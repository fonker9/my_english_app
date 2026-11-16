import '../models/user_settings.dart';
import '../sources/local/hive_settings_source.dart';

/// Репозиторий локальных настроек приложения (только Hive).
abstract class SettingsRepository {
  /// Загружает текущие настройки пользователя.
  Future<UserSettings> loadSettings();

  /// Сохраняет настройки пользователя.
  Future<void> saveSettings(UserSettings settings);
}

/// Реализация [SettingsRepository] поверх [HiveSettingsSource].
class SettingsRepositoryImpl implements SettingsRepository {
  final HiveSettingsSource _settingsSource;

  SettingsRepositoryImpl(this._settingsSource);

  @override
  Future<UserSettings> loadSettings() async {
    return _settingsSource.getSettings();
  }

  @override
  Future<void> saveSettings(UserSettings settings) {
    return _settingsSource.saveSettings(settings);
  }
}
