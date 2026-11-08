package com.gameaday.internet_archive_helper

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Activity for the Internet Archive Helper mobile app
 * Handles deep links and integrates with the background download service
 */
class MainActivity: FlutterActivity() {

    private val methodChannelName = "com.gameaday.internet_archive_helper/platform"
    private val notificationChannelName = "com.internetarchive.helper/notifications"
    private lateinit var methodChannel: MethodChannel

    /** Pending result while the POST_NOTIFICATIONS system dialog is showing (#92). */
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 4292
        private const val DOWNLOAD_PROGRESS_CHANNEL_ID = "download_progress"
        private const val DOWNLOAD_COMPLETION_CHANNEL_ID = "download_completion"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up platform method channel for native integration
        // Note: Rust FFI has been removed - using pure Dart implementation instead
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val packageInfo = packageManager.getPackageInfo(packageName, 0)
                        result.success(packageInfo.versionName)
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", "Failed to get app version", e.message)
                    }
                }
                "getSdkInt" -> {
                    // Real Android version for permission branching (issue #77)
                    result.success(Build.VERSION.SDK_INT)
                }
                "shareFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType")
                    if (filePath != null) {
                        shareFile(filePath, mimeType ?: "*/*")
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing filePath", null)
                    }
                }
                "openFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType")
                    if (filePath != null) {
                        openFile(filePath, mimeType ?: "*/*")
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing filePath", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Download progress/completion notifications (#92). The Dart side
        // (NotificationService) talks to this channel; POST_NOTIFICATIONS is
        // declared in the manifest and requested in-context at the first
        // download, never at launch.
        val notificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationChannelName
        )
        notificationChannel.setMethodCallHandler { call, result ->
            handleNotificationCall(call.method, call.arguments, result)
        }
    }

    /**
     * Method calls for the notification channel (#92).
     *
     * Implements the surface NotificationService invokes:
     * initialize / requestPermissions / arePermissionsGranted /
     * showProgressNotification / showNotification / cancelNotification /
     * cancelAllNotifications / updateBadgeCount. Notification action
     * buttons (pause/cancel from the shade) are a follow-up; tapping the
     * notification opens the app.
     */
    private fun handleNotificationCall(
        method: String,
        arguments: Any?,
        result: MethodChannel.Result
    ) {
        val args = if (arguments is Map<*, *>) arguments else emptyMap<Any, Any>()
        when (method) {
            "initialize" -> {
                initializeNotificationChannels()
                result.success(true)
            }
            "requestPermissions" -> requestNotificationPermission(result)
            "arePermissionsGranted" -> result.success(canPostNotifications())
            "showProgressNotification" -> {
                showProgressNotification(args)
                result.success(true)
            }
            "showNotification" -> {
                showStaticNotification(args)
                result.success(true)
            }
            "cancelNotification" -> {
                val id = (args["notificationId"] as? Int) ?: 0
                NotificationManagerCompat.from(this).cancel(id)
                result.success(true)
            }
            "cancelAllNotifications" -> {
                NotificationManagerCompat.from(this).cancelAll()
                result.success(true)
            }
            // Badge counts are launcher-dependent; accepted as a no-op.
            "updateBadgeCount" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    /** Create the two notification channels (API 26+; no-op below). */
    private fun initializeNotificationChannels() {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        val progress = NotificationChannel(
            DOWNLOAD_PROGRESS_CHANNEL_ID,
            "Download Progress",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows progress of ongoing downloads"
            setShowBadge(false)
        }

        val completion = NotificationChannel(
            DOWNLOAD_COMPLETION_CHANNEL_ID,
            "Download Complete",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Notifications when downloads are completed"
            setShowBadge(true)
        }

        manager.createNotificationChannel(progress)
        manager.createNotificationChannel(completion)
    }

    /**
     * Whether notifications may be posted right now: the runtime grant on
     * Android 13+ (#92) plus the user's master notification toggle.
     */
    private fun canPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        return NotificationManagerCompat.from(this).areNotificationsEnabled()
    }

    /**
     * Request POST_NOTIFICATIONS (Android 13+). On older versions the
     * permission does not exist and only the master toggle applies.
     * The dialog result is delivered back through the MethodChannel result.
     */
    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33) {
            result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
            return
        }
        if (ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingNotificationPermissionResult != null) {
            // A request is already in flight; never stack dialogs.
            result.success(false)
            return
        }
        pendingNotificationPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingNotificationPermissionResult?.success(granted)
            pendingNotificationPermissionResult = null
        }
    }

    /** Content intent that reopens the app when the notification is tapped. */
    private fun launchPendingIntent(): PendingIntent {
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent()
        // FLAG_IMMUTABLE exists from API 23; on 21-22 the plain update flag
        // is enough (the immutability bit is simply not interpreted).
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getActivity(this, 0, intent, flags)
    }

    private fun baseNotificationBuilder(
        channelId: String,
        title: String,
        text: String
    ): NotificationCompat.Builder =
        NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(launchPendingIntent())
            .setOnlyAlertOnce(true)

    /** Ongoing progress notification with a determinate progress bar. */
    private fun showProgressNotification(args: Map<*, *>) {
        if (!canPostNotifications()) return
        val id = args["notificationId"] as? Int ?: return
        val channelId = args["channelId"] as? String ?: return
        val title = args["title"] as? String ?: return
        val text = args["description"] as? String ?: ""
        val progress = args["progress"] as? Int ?: 0
        val max = args["maxProgress"] as? Int ?: 100
        val indeterminate = args["indeterminate"] as? Boolean ?: false
        val ongoing = args["ongoing"] as? Boolean ?: true

        val builder = baseNotificationBuilder(channelId, title, text)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setProgress(if (max > 0) max else 100, progress, indeterminate)
            .setOngoing(ongoing)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        NotificationManagerCompat.from(this).notify(id, builder.build())
    }

    /** Completion / error notification (the "download_completion" channel). */
    private fun showStaticNotification(args: Map<*, *>) {
        if (!canPostNotifications()) return
        val id = args["notificationId"] as? Int ?: return
        val channelId = args["channelId"] as? String ?: return
        val title = args["title"] as? String ?: return
        val text = args["description"] as? String ?: ""
        val autoCancel = args["autoCancel"] as? Boolean ?: true
        val priority = args["priority"] as? String ?: "default"

        // The Dart side titles error notifications "Download Failed"; use
        // the warning icon for those and the done icon for completions.
        val isError = title.contains("Failed")
        val builder = baseNotificationBuilder(channelId, title, text)
            .setSmallIcon(
                if (isError) android.R.drawable.stat_notify_error
                else android.R.drawable.stat_sys_download_done
            )
            .setAutoCancel(autoCancel)
            .setPriority(
                if (priority == "high") NotificationCompat.PRIORITY_HIGH
                else NotificationCompat.PRIORITY_DEFAULT
            )

        NotificationManagerCompat.from(this).notify(id, builder.build())
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle deep link if present
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    /**
     * Handle incoming intents, including deep links to Internet Archive URLs
     */
    private fun handleIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri ->
                    handleDeepLink(uri)
                }
            }
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") {
                    intent.getStringExtra(Intent.EXTRA_TEXT)?.let { sharedText ->
                        handleSharedText(sharedText)
                    }
                }
            }
        }
    }

    /**
     * Handle deep link URLs (archive.org links and custom iaget:// scheme)
     */
    private fun handleDeepLink(uri: Uri) {
        val identifier = extractIdentifierFromUri(uri)
        if (identifier != null) {
            // Send deep link data to Flutter app
            methodChannel.invokeMethod("deepLink", mapOf(
                "url" to uri.toString(),
                "identifier" to identifier,
                "host" to uri.host
            ))
        }
    }

    /**
     * Handle shared text that might contain Internet Archive URLs
     */
    private fun handleSharedText(text: String) {
        // Look for archive.org URLs in shared text
        val archiveRegex = Regex("https?://archive\\.org/(?:details|download)/([^\\s/?]+)")
        val match = archiveRegex.find(text)
        
        if (match != null) {
            val identifier = match.groupValues[1]
            methodChannel.invokeMethod("sharedText", mapOf(
                "text" to text,
                "identifier" to identifier
            ))
        } else {
            methodChannel.invokeMethod("sharedText", mapOf(
                "text" to text
            ))
        }
    }

    /**
     * Extract archive identifier from various URL formats
     */
    private fun extractIdentifierFromUri(uri: Uri): String? {
        return when (uri.scheme) {
            "iaget" -> {
                // Custom scheme: iaget://identifier
                uri.host ?: uri.path?.removePrefix("/")
            }
            "https", "http" -> {
                if (uri.host == "archive.org") {
                    // Extract from archive.org URLs
                    val pathSegments = uri.pathSegments
                    if (pathSegments.size >= 2 && 
                        (pathSegments[0] == "details" || pathSegments[0] == "download")) {
                        pathSegments[1]
                    } else null
                } else null
            }
            else -> null
        }
    }

    /**
     * Share a downloaded file using Android sharing
     */
    private fun shareFile(filePath: String, mimeType: String) {
        try {
            val file = java.io.File(filePath)
            if (file.exists()) {
                val uri = androidx.core.content.FileProvider.getUriForFile(
                    this,
                    "${packageName}.fileprovider",
                    file
                )
                
                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                    type = mimeType
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                
                startActivity(Intent.createChooser(shareIntent, "Share file"))
            } else {
                methodChannel.invokeMethod("error", mapOf(
                    "type" to "share_error",
                    "message" to "File not found: $filePath"
                ))
            }
        } catch (e: Exception) {
            // Handle sharing error
            methodChannel.invokeMethod("error", mapOf(
                "type" to "share_error",
                "message" to "Failed to share file: ${e.message}"
            ))
        }
    }

    /**
     * Open a downloaded file with appropriate app
     */
    private fun openFile(filePath: String, mimeType: String) {
        try {
            val file = java.io.File(filePath)
            if (file.exists()) {
                val uri = androidx.core.content.FileProvider.getUriForFile(
                    this,
                    "${packageName}.fileprovider",
                    file
                )
                
                val openIntent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, mimeType)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                
                // Do not use resolveActivity(): under Android 11+
                // package visibility it returns null for file content
                // types even when a handler is installed. Just start the
                // activity and treat ActivityNotFoundException as "no app
                // found".
                try {
                    startActivity(openIntent)
                } catch (e: ActivityNotFoundException) {
                    methodChannel.invokeMethod("error", mapOf(
                        "type" to "open_error",
                        "message" to "No app found to open this file type"
                    ))
                }
            } else {
                methodChannel.invokeMethod("error", mapOf(
                    "type" to "open_error",
                    "message" to "File not found: $filePath"
                ))
            }
        } catch (e: Exception) {
            methodChannel.invokeMethod("error", mapOf(
                "type" to "open_error",
                "message" to "Failed to open file: ${e.message}"
            ))
        }
    }
}
