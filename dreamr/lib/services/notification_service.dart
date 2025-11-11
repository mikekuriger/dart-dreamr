// services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart' as os; // optional
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

// import 'package:dreamr/utils/log.dart';

/// Daily notifications + prefs. Uses local notifications for scheduling.
/// If you set a OneSignal App ID, push subscription is initialized too.
/// Server-side scheduled push is optional and not required for daily reminders.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  // ===== Config =====
  static const String _oneSignalAppId = 'YOUR-ONESIGNAL-APP-ID'; // leave as-is if not using
  static const int _dailyReminderId = 1001;
  static const int _creditUpdateId = 2001;
  static const String _channelId = 'dreamr_daily';
  static const String _channelName = 'Daily Reminders';
  static const String _channelDesc = 'Daily Dreamr reminder notifications';

  // ===== State =====
  bool _isInitialized = false;
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  // ===== Public API =====
  Future<void> init() async {
    if (_isInitialized) return;

    // Timezone bootstrap
    try {
      tzdata.initializeTimeZones();
      final String tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      debugPrint('Timezone init failed: $e');
      // fallback to UTC if anything goes wrong
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Local notifications init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _fln.initialize(initSettings,
        onDidReceiveNotificationResponse: _onTapLocalNotification);

    // OneSignal init (optional)
    // if (_oneSignalAppId != 'YOUR-ONESIGNAL-APP-ID' && _oneSignalAppId.isNotEmpty) {
    //   try {
    //     os.OneSignal.Debug.setLogLevel(os.OSLogLevel.warn);
    //     os.OneSignal.initialize(_oneSignalAppId);
    //     // Do not auto prompt on iOS; we call requestPermissions() ourselves.
    //     await os.OneSignal.Notifications.requestPermission(false);
    //     // Tag the device if you want audience segmentation later
    //     os.OneSignal.login(await _deviceKey());
    //   } catch (e) {
    //     debugPrint('OneSignal init error: $e');
      // }
    // }

    // ===== ANDROID: create the channel once =====
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'dreamr_daily',                 // must match your channel id
      'Daily Reminders',
      description: 'Daily reminder to log dreams',
      importance: Importance.max,
      enableLights: true,
      playSound: true,
      enableVibration: true,
    ));
    // ===========================================

    _isInitialized = true;
    debugPrint('NotificationService initialized');
    
    // Check if this is first app launch and enable notifications by default
    await _enableNotificationsByDefault();
  }
  
  /// Checks if this is the first app launch and enables notifications by default
  Future<void> _enableNotificationsByDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSetNotifications = prefs.getBool('has_set_notifications') ?? false;
    
    if (!hasSetNotifications) {
      // This is the first launch or the flag hasn't been set yet
      debugPrint('First app launch detected - enabling notifications by default');
      
      // Request notification permissions
      final granted = await requestPermissions();
      if (granted) {
        // Set notification preferences to enabled
        await prefs.setBool('enable_notifications', true);
        await prefs.setBool('reminder_enabled', true);
        
        // Schedule the default morning reminder (8:00 AM)
        final defaultTime = TimeOfDay(hour: 8, minute: 0);
        await scheduleMorningReminder(defaultTime);
        
        debugPrint('Notifications enabled by default with reminder at 8:00 AM');
      } else {
        debugPrint('Notification permissions denied on first launch');
        await prefs.setBool('enable_notifications', false);
        await prefs.setBool('reminder_enabled', false);
      }
      
      // Mark that we've set the notification preference
      await prefs.setBool('has_set_notifications', true);
    }
  }

  Future<bool> requestPermissions() async {
    await init();

    bool iosGranted = true;
    // bool androidGranted = true;
    final status = await Permission.notification.request();
    final androidGranted = status.isGranted;

    // iOS (older plugin API)
    final ios = _fln.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      iosGranted = await ios.requestPermissions(
            alert: true, badge: true, sound: true,
          ) ??
          true;
    }

    // Android: no runtime request on this plugin version
    // Permission is granted via manifest on < Android 13.
    // For Android 13+, use `permission_handler` if you want a prompt.

    return iosGranted && androidGranted;
  }

  Future<void> toggleNotifications(bool enable) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', enable);

    if (enable) {
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('Notifications denied by user');
        return;
      }
      final t = await getNotificationTime(); // existing or default 08:00
      await scheduleMorningReminder(t);
      await prefs.setBool('reminder_enabled', true);
      debugPrint('Notifications enabled');
    } else {
      await cancelMorningReminder();
      await prefs.setBool('reminder_enabled', false);
      debugPrint('Notifications disabled');
    }

    // If using OneSignal, update subscription
    if (_usingOneSignal) {
      try {
        if (enable) {
          os.OneSignal.login(await _deviceKey());
        } else {
          os.OneSignal.logout();
        }
      } catch (e) {
        debugPrint('OneSignal subscription toggle error: $e');
      }
    }
  }

  Future<bool> getNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enable_notifications') ?? false;
  }

  Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour') ?? 8;
    final minute = prefs.getInt('notification_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);

    if (await getNotificationSetting()) {
      await scheduleMorningReminder(time);
    }
  }

  /// Schedule or reschedule the daily reminder at the specified local time.
  Future<void> scheduleMorningReminder(TimeOfDay time) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);

    // Create a dedicated high-priority channel for daily reminders
    const String dailyChannelId = 'dreamr_daily_reminder';
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      dailyChannelId,
      'Daily Dream Reminders',
      description: 'Daily reminder to log your dreams',
      importance: Importance.max,
      enableLights: true,
      playSound: true,
      enableVibration: true,
    ));

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        dailyChannelId, 
        'Daily Dream Reminders',
        channelDescription: 'Daily reminder to log your dreams',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm, // Higher priority category
        visibility: NotificationVisibility.public,
        playSound: true,
        fullScreenIntent: true, // Try to show even on lock screen
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true, 
        presentBadge: true, 
        presentSound: true,
        threadIdentifier: 'dreamr.daily'
      ),
    );

    // Ensure timezone is set
    try {
      final String name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Timezone error in scheduleMorningReminder: $e');
    }

    final first = _nextInstance(time);
    await _fln.zonedSchedule(
      _dailyReminderId,
      'Log last night\'s dream',
      'Open Dreamr and jot the details while they are fresh.',
      first,
      details,
      androidScheduleMode: Platform.isAndroid
          ? AndroidScheduleMode.exactAllowWhileIdle  // Use exact scheduling for reliability
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    // Print debugging information about the scheduled reminder
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final nowStr = DateTime.now().toString();
    final scheduledStr = first.toString();
    debugPrint('Daily reminder scheduled at $timeStr');
    debugPrint('Current time: $nowStr');
    debugPrint('Scheduled time: $scheduledStr');
    
    // Display pending notifications to verify it's scheduled
    final pending = await _fln.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id == _dailyReminderId) {
        debugPrint('Verified daily reminder is in pending queue: id=${p.id} title=${p.title}');
      }
    }
  }

  Future<void> cancelMorningReminder() async {
    await init();
    await _fln.cancel(_dailyReminderId);
    debugPrint('Daily reminder canceled');
  }

  /// Immediate local notification for credit updates.
  Future<void> sendCreditUpdateNotification(int creditCount) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('enable_notifications') ?? false;
    if (!enabled) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _fln.show(
      _creditUpdateId,
      'New dream credits',
      '$creditCount credits added to your account.',
      details,
      payload: 'credit_update',
    );

    await prefs.setInt('last_credit_update', DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('last_credit_amount', creditCount);
  }

  /// Schedule a notification to be delivered after a specific delay.
  /// Uses Future.delayed for reliable delivery even with Android battery optimizations.
  Future<void> scheduleDelayedNotification(Duration delay, String title, String body, {String? payload}) async {
    await init();

    // Create a dedicated high-priority channel
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    const String channelId = 'dreamr_scheduled';
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      channelId,
      'Scheduled Notifications',
      description: 'Time-sensitive scheduled notifications',
      importance: Importance.max,
      enableLights: true,
      playSound: true,
      enableVibration: true,
    ));

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        channelId, 
        'Scheduled Notifications',
        channelDescription: 'Time-sensitive scheduled notifications',
        importance: Importance.max, 
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true, 
        presentBadge: true, 
        presentSound: true,
      ),
    );

    // Use Future.delayed for reliable notification delivery
    // This method has been proven to work reliably even with Android battery optimizations
    Future.delayed(delay, () async {
      await _fln.show(
        // Create a unique ID based on current time to avoid conflicts
        DateTime.now().millisecondsSinceEpoch % 10000,
        title,
        body,
        details,
        payload: payload,
      );
    });
  }

  /// Test method for showing an immediate notification and scheduling one for later
  Future<void> showNowTest() async {
    await init();
    
    const String channelId = 'dreamr_test';
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      channelId,
      'Test Notifications',
      description: 'Test notifications',
      importance: Importance.max,
      enableLights: true,
      playSound: true,
    ));

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        channelId, 'Test Notifications',
        channelDescription: 'Test notifications',
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true,
      ),
    );
    
    // Immediate test notification
    await _fln.show(9999, 'Test', 'If you see this, notifications work.', details);
    
    // Schedule a system notification via Android's alarm mechanism
    await scheduleTestExactNotification(const Duration(seconds: 70));
    
    // Also use our direct method as backup - this only works while app is running
    await scheduleDelayedNotification(
      const Duration(seconds: 72),
      'Direct notification (backup)',
      'This notification used direct scheduling (app must be running)',
      payload: 'direct_test'
    );
  }
  
  /// Schedule a test notification using the system alarm
  Future<void> scheduleTestExactNotification(Duration delay) async {
    await init();
    
    const String testChannelId = 'dreamr_test_exact';
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      testChannelId,
      'Test Notifications',
      description: 'High priority exact test notifications',
      importance: Importance.max,
      enableLights: true,
      playSound: true,
      enableVibration: true,
    ));

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        testChannelId,
        'Test Notifications',
        channelDescription: 'High priority exact test notifications',
        importance: Importance.max, 
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true, 
        presentBadge: true, 
        presentSound: true,
      ),
    );

    final when = tz.TZDateTime.now(tz.local).add(delay);
    
    await _fln.zonedSchedule(
      4343,
      'Scheduled system notification',
      'This notification was scheduled ${delay.inSeconds}s ago via system alarm',
      when,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: Platform.isAndroid
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'scheduled_test',
    );
  }
  
  // List pending scheduled notifications
  Future<void> debugDumpNotifications() async {
    await init();
    final pending = await _fln.pendingNotificationRequests();
    debugPrint('Pending notifications: ${pending.length}');
    for (final p in pending) {
      debugPrint('id=${p.id} title=${p.title} body=${p.body}');
    }
  }

  // ===== Helpers =====
  bool get _usingOneSignal =>
      _oneSignalAppId.isNotEmpty && _oneSignalAppId != 'YOUR-ONESIGNAL-APP-ID';

  tz.TZDateTime _nextInstance(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<String> _deviceKey() async {
    // Use a stable string for login/tagging. Replace with your internal user id if available.
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('onesignal_key');
    if (id == null) {
      id = 'anon-${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('onesignal_key', id);
    }
    return id;
  }

  void _onTapLocalNotification(NotificationResponse r) {
    // Handle taps if you need deep links. Payload is in r.payload.
    debugPrint('Notification tapped: ${r.payload}');
  }
}