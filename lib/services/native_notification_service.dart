import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native Android System Notifications (status bar / shade).
class NativeNotificationService {
  static const MethodChannel _channel =
      MethodChannel('kmart_staff/notifications');

  /// Displays a native Android mobile system notification in the status bar
  /// with heads-up display, sound, vibration, and Kmart branding.
  static Future<bool> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    if (kIsWeb) {
      debugPrint('[NativeNotification] Web fallback: $title — $body');
      return true;
    }

    try {
      final success = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'body': body,
        'id': id ?? (DateTime.now().millisecondsSinceEpoch % 100000),
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[NativeNotificationService] showNotification error: $e');
      return false;
    }
  }

  /// Request runtime notification permission (Android 13+ / API 33+)
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestNotificationPermission');
      return granted ?? true;
    } catch (e) {
      debugPrint(
          '[NativeNotificationService] requestNotificationPermission error: $e');
      return true;
    }
  }

  /// Check whether notification permission is granted
  static Future<bool> checkNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final granted =
          await _channel.invokeMethod<bool>('checkNotificationPermission');
      return granted ?? true;
    } catch (e) {
      debugPrint(
          '[NativeNotificationService] checkNotificationPermission error: $e');
      return true;
    }
  }

  /// Cancel specific notification by ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('cancelNotification', {'id': id});
    } catch (e) {
      debugPrint('[NativeNotificationService] cancelNotification error: $e');
    }
  }

  /// Cancel all active notifications
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('cancelAll');
    } catch (e) {
      debugPrint('[NativeNotificationService] cancelAll error: $e');
    }
  }
}
