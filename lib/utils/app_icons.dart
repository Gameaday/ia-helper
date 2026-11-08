import 'package:flutter/material.dart';

/// Curated icon registry for Internet Archive Helper (v2.0 iconography).
///
/// Policy:
/// - **One family**: Material outlined icons everywhere by default.
/// - **Filled only for state**: the `*Filled` variants mark a selected or
///   active control (current navigation destination, a favorited item).
/// - **One place**: screens import semantic roles from here instead of
///   hand-picking `Icons.*` names, so the family can never drift again.
///
/// Every name below is verified to exist in the MaterialIconsOutlined font
/// (or is a stable legacy outline name such as `Icons.info_outline`).
class AppIcons {
  AppIcons._();

  // ===== Navigation =====
  static const IconData home = Icons.home_outlined;
  static const IconData homeFilled = Icons.home;
  static const IconData search = Icons.search_outlined;
  static const IconData searchFilled = Icons.search;
  static const IconData library = Icons.local_library_outlined;
  static const IconData libraryFilled = Icons.local_library;
  static const IconData favorites = Icons.favorite_border;
  static const IconData favoritesFilled = Icons.favorite;
  static const IconData settings = Icons.settings_outlined;
  static const IconData account = Icons.account_circle_outlined;

  // ===== Downloads & transfers =====
  static const IconData download = Icons.download_outlined;
  static const IconData downloadFilled = Icons.download;
  static const IconData downloadDone = Icons.download_done_outlined;
  static const IconData cloudDownload = Icons.cloud_download_outlined;
  static const IconData pause = Icons.pause_outlined;
  static const IconData play = Icons.play_arrow_outlined;
  static const IconData cancel = Icons.cancel_outlined;
  static const IconData refresh = Icons.refresh_outlined;
  static const IconData restart = Icons.restart_alt_outlined;
  static const IconData sync = Icons.sync_outlined;
  static const IconData cloudDone = Icons.cloud_done_outlined;
  static const IconData schedule = Icons.schedule_outlined;
  static const IconData bandwidth = Icons.speed_outlined;

  // ===== Item actions =====
  static const IconData share = Icons.share_outlined;
  static const IconData delete = Icons.delete_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData openInNew = Icons.open_in_new_outlined;
  static const IconData folder = Icons.folder_outlined;
  static const IconData folderOpen = Icons.folder_open_outlined;
  static const IconData folderZip = Icons.folder_zip_outlined;
  static const IconData archive = Icons.archive_outlined;
  static const IconData link = Icons.link_outlined;
  static const IconData copy = Icons.content_copy_outlined;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;

  /// Torrent handoff: the outlined font has no torrent glyph, so the app's
  /// established handoff mark is the hub.
  static const IconData torrent = Icons.hub_outlined;

  // ===== Search & analytics =====
  static const IconData filter = Icons.filter_list_outlined;
  static const IconData sort = Icons.sort_outlined;
  static const IconData history = Icons.history_outlined;
  static const IconData manageSearch = Icons.manage_search_outlined;
  static const IconData stats = Icons.bar_chart_outlined;
  static const IconData queryStats = Icons.query_stats_outlined;
  static const IconData trendingUp = Icons.trending_up_outlined;

  // ===== Feedback & status =====
  static const IconData success = Icons.check_circle_outline;
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData info = Icons.info_outline;
  static const IconData check = Icons.check_outlined;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsActive = Icons.notifications_active_outlined;
  static const IconData notificationsOff = Icons.notifications_off_outlined;
  static const IconData cloudOff = Icons.cloud_off_outlined;
  static const IconData wifiOff = Icons.wifi_off_outlined;

  // ===== Common UI =====
  static const IconData close = Icons.close_outlined;
  static const IconData more = Icons.more_horiz_outlined;
  static const IconData moreVertical = Icons.more_vert_outlined;
  static const IconData chevronLeft = Icons.chevron_left_outlined;
  static const IconData chevronRight = Icons.chevron_right_outlined;
  static const IconData expandMore = Icons.expand_more_outlined;
  static const IconData expandLess = Icons.expand_less_outlined;
  static const IconData star = Icons.star_outline;
  static const IconData starFilled = Icons.star;
  static const IconData add = Icons.add_outlined;

  // ===== File types =====
  static const IconData fileAudio = Icons.audio_file_outlined;
  static const IconData fileVideo = Icons.video_file_outlined;
  static const IconData fileImage = Icons.image_outlined;
  static const IconData filePdf = Icons.picture_as_pdf_outlined;
  static const IconData fileText = Icons.description_outlined;
  static const IconData menuBook = Icons.menu_book_outlined;
}
