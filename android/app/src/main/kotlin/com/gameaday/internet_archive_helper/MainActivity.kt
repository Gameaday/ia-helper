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
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.OpenableColumns
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
    private val safChannelName = "com.internetarchive.helper/saf"
    private lateinit var methodChannel: MethodChannel

    /** Pending result while the POST_NOTIFICATIONS system dialog is showing (#92). */
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    /** Pending result while the SAF folder picker is showing (#90). */
    private var pendingSafResult: MethodChannel.Result? = null

    /** Main-thread poster for results produced on worker threads. */
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 4292
        private const val SAF_PICK_REQUEST_CODE = 4293
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

        // SAF download-location picker (#90). ACTION_OPEN_DOCUMENT_TREE
        // with a persistable URI grant: downloads can be copied into a
        // user-chosen public folder with NO storage permission and the
        // grant survives restarts.
        val safChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            safChannelName
        )
        safChannel.setMethodCallHandler { call, result ->
            handleSafCall(call.method, call.arguments, result)
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

    /**
     * Method calls for the SAF channel (#90).
     *
     * pickFolder -> ACTION_OPEN_DOCUMENT_TREE, takes a persistable
     * grant and returns {treeUri, folderName} (null on cancel).
     * hasValidGrant -> whether the stored grant is still held.
     * releaseGrant -> drop the persistable grant.
     * exportFile -> create the document in the tree and stream the
     * local file into it (worker thread; result posted to main).
     */
    private fun handleSafCall(
        method: String,
        arguments: Any?,
        result: MethodChannel.Result
    ) {
        val args = if (arguments is Map<*, *>) arguments else emptyMap<Any, Any>()
        when (method) {
            "pickFolder" -> launchSafPicker(result)
            "hasValidGrant" -> {
                val treeUri = args["treeUri"] as? String
                result.success(hasValidSafGrant(treeUri))
            }
            "releaseGrant" -> {
                releaseSafGrant(args["treeUri"] as? String)
                result.success(true)
            }
            "exportFile" -> exportToSafFolder(args, result)
            else -> result.notImplemented()
        }
    }

    /** Launch the system folder picker; single-flight like #92. */
    private fun launchSafPicker(result: MethodChannel.Result) {
        if (pendingSafResult != null) {
            // A picker is already showing; never stack pickers.
            result.success(null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        }
        pendingSafResult = result
        startActivityForResult(intent, SAF_PICK_REQUEST_CODE)
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAF_PICK_REQUEST_CODE) return

        val pending = pendingSafResult
        pendingSafResult = null
        if (resultCode != RESULT_OK || data?.data == null) {
            pending?.success(null)
            return
        }
        val uri = data.data!!
        // Persist across restarts - this is the whole point of the SAF
        // flow (no storage permission, grant survives reboots).
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } catch (e: SecurityException) {
            // Some providers do not offer persistable grants; the
            // session-scoped grant still works until restart.
        }
        pending?.success(
            mapOf("treeUri" to uri.toString(), "folderName" to prettySafFolderName(uri))
        )
    }

    /**
     * Human-readable name for a tree URI: the document id looks like
     * "primary:Download", so keep the part after the volume colon.
     */
    private fun prettySafFolderName(uri: Uri): String {
        val docId = try {
            DocumentsContract.getTreeDocumentId(uri)
        } catch (e: IllegalArgumentException) {
            uri.lastPathSegment ?: uri.toString()
        }
        val colon = docId.indexOf(':')
        return if (colon >= 0 && colon + 1 < docId.length) docId.substring(colon + 1) else docId
    }

    /** Whether the persistable write grant for the tree is still held. */
    private fun hasValidSafGrant(treeUri: String?): Boolean {
        if (treeUri == null) return false
        return contentResolver.persistedUriPermissions.any {
            it.uri.toString() == treeUri && it.isWritePersistableUriPermission
        }
    }

    /** Release the persistable grant (folder reset back to app storage). */
    private fun releaseSafGrant(treeUri: String?) {
        if (treeUri == null) return
        try {
            contentResolver.releasePersistableUriPermission(
                Uri.parse(treeUri),
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } catch (e: Exception) {
            // Already gone: releasing is best-effort.
        }
    }

    /**
     * Copy a finished local download into the chosen folder. Runs on a
     * worker thread (files can be multi-GB); the MethodChannel result
     * is posted back on the main thread.
     */
    private fun exportToSafFolder(args: Map<*, *>, result: MethodChannel.Result) {
        val treeUri = args["treeUri"] as? String
        val filePath = args["filePath"] as? String
        val fileName = args["fileName"] as? String
        val mimeType = (args["mimeType"] as? String) ?: "application/octet-stream"
        if (treeUri == null || filePath == null || fileName == null) {
            result.error("INVALID_ARGUMENTS", "treeUri, filePath and fileName are required", null)
            return
        }
        Thread {
            try {
                val tree = Uri.parse(treeUri)
                val rootDocUri = DocumentsContract.buildDocumentUriUsingTree(
                    tree,
                    DocumentsContract.getTreeDocumentId(tree)
                )
                val created = DocumentsContract.createDocument(
                    contentResolver, rootDocUri, mimeType, fileName
                ) ?: throw java.io.IOException("SAF provider rejected the document")

                java.io.FileInputStream(java.io.File(filePath)).use { source ->
                    contentResolver.openOutputStream(created)?.use { sink ->
                        val buffer = ByteArray(64 * 1024)
                        while (true) {
                            val read = source.read(buffer)
                            if (read < 0) break
                            sink.write(buffer, 0, read)
                        }
                        sink.flush()
                    } ?: throw java.io.IOException("Could not open the destination stream")
                }

                // The provider may have renamed on collision; report the
                // real document name.
                var documentName = fileName
                try {
                    contentResolver.query(created, null, null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                            if (idx >= 0) cursor.getString(idx)?.let { documentName = it }
                        }
                    }
                } catch (e: Exception) {
                    // Display name is cosmetic; the export succeeded.
                }

                mainHandler.post { result.success(mapOf("documentName" to documentName)) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("EXPORT_ERROR", e.message ?: "export failed", null)
                }
            }
        }.start()
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
