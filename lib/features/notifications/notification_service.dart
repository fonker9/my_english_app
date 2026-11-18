import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../core/di/service_locator.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';

/// Сервис локальных ежедневных напоминаний о занятиях.
class NotificationService {
  static const int dailyReminderId = 1001;
  static const String channelId = 'daily_study_reminder';
  static const String channelName = 'Ежедневные напоминания';
  static const String channelDescription =
      'Напоминания о ежедневном изучении и повторении английских слов';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _tzInitialized = false;

  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Вычисляет ближайшее время показа уведомления по [time] относительно [now].
  /// Если выбранное время сегодня уже прошло, возвращает это же время на завтра.
  static DateTime nextScheduledDateTime(TimeOfDay time, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    var scheduled = DateTime(
      reference.year,
      reference.month,
      reference.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(reference)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Инициализирует часовые пояса, плагин уведомлений и применяет сохранённые настройки.
  Future<void> init() async {
    if (_initialized) return;

    try {
      _ensureTimezoneConfigured();

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: initializationSettings);
      _initialized = true;

      if (sl.isRegistered<SettingsRepository>()) {
        final settings = await sl<SettingsRepository>().loadSettings();
        if (settings.notificationsEnabled) {
          await scheduleDailyReminder(
            settings.notificationTime ?? const TimeOfDay(hour: 20, minute: 0),
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка инициализации NotificationService: $e');
    }
  }

  /// Запрашивает разрешение на показ уведомлений (Android 13+).
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('Ошибка запроса разрешений уведомлений: $e');
      return false;
    }
  }

  /// Планирует ежедневное напоминание на указанное время [time].
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    try {
      _ensureTimezoneConfigured();
      if (!_initialized) {
        const initializationSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
        await _plugin.initialize(settings: initializationSettings);
        _initialized = true;
      }

      final next = nextScheduledDateTime(time);
      final scheduledDate = tz.TZDateTime(
        tz.local,
        next.year,
        next.month,
        next.day,
        next.hour,
        next.minute,
      );

      await _plugin.zonedSchedule(
        id: dailyReminderId,
        title: 'Время учить английский!',
        body: 'Повторите слова и поддержите свою серию дней.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Ошибка планирования ежедневного уведомления: $e');
    }
  }

  /// Отменяет все запланированные уведомления.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Ошибка отмены уведомлений: $e');
    }
  }

  /// Применяет настройки уведомлений пользователя [settings].
  Future<void> applySettings(UserSettings settings) async {
    if (settings.notificationsEnabled) {
      await requestPermissions();
      await scheduleDailyReminder(
        settings.notificationTime ?? const TimeOfDay(hour: 20, minute: 0),
      );
    } else {
      await cancelAll();
    }
  }

  void _ensureTimezoneConfigured() {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    _tzInitialized = true;

    final now = DateTime.now();
    final targetOffsetMs = now.timeZoneOffset.inMilliseconds;
    final nowMs = now.millisecondsSinceEpoch;

    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.timeZone(nowMs).offset.inMilliseconds == targetOffsetMs) {
        tz.setLocalLocation(location);
        return;
      }
    }
  }
}
