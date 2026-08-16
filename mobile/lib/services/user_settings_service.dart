import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class UserSettingsService extends ChangeNotifier {
  static final UserSettingsService instance = UserSettingsService._internal();
  UserSettingsService._internal();

  String _name = 'Alex Johnson';
  bool _notificationsEnabled = true;
  String _exportFormat = 'PNG (High Quality)';
  bool _isDarkMode = false;
  List<String> _favoriteTemplateIds = [];
  bool _hasSeenOnboarding = false;
  bool _isGuest = false;

  String get name => _name;
  bool get notificationsEnabled => _notificationsEnabled;
  String get exportFormat => _exportFormat;
  bool get isDarkMode => _isDarkMode;
  List<String> get favoriteTemplateIds => _favoriteTemplateIds;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isGuest => _isGuest;

  Future<void> init() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final data = json.decode(await file.readAsString());
        if (data is Map<String, dynamic>) {
          _name = data['name'] ?? _name;
          _notificationsEnabled = data['notificationsEnabled'] ?? _notificationsEnabled;
          _exportFormat = data['exportFormat'] ?? _exportFormat;
          _isDarkMode = data['isDarkMode'] ?? _isDarkMode;
          if (data['favoriteTemplateIds'] != null) {
            _favoriteTemplateIds = List<String>.from(data['favoriteTemplateIds']);
          }
          _hasSeenOnboarding = data['hasSeenOnboarding'] ?? _hasSeenOnboarding;
          _isGuest = data['isGuest'] ?? _isGuest;
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep defaults on error
    }
  }

  Future<File> _getConfigFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/user_settings.json');
  }

  Future<void> _save() async {
    try {
      final file = await _getConfigFile();
      final data = {
        'name': _name,
        'notificationsEnabled': _notificationsEnabled,
        'exportFormat': _exportFormat,
        'isDarkMode': _isDarkMode,
        'favoriteTemplateIds': _favoriteTemplateIds,
        'hasSeenOnboarding': _hasSeenOnboarding,
        'isGuest': _isGuest,
      };
      await file.writeAsString(json.encode(data));
    } catch (_) {
      // Ignore save error
    }
  }

  Future<void> setName(String newName) async {
    _name = newName.trim().isEmpty ? 'Alex Johnson' : newName.trim();
    notifyListeners();
    await _save();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _save();
  }

  Future<void> setExportFormat(String format) async {
    _exportFormat = format;
    notifyListeners();
    await _save();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    notifyListeners();
    await _save();
  }

  Future<void> toggleFavorite(String templateId) async {
    if (_favoriteTemplateIds.contains(templateId)) {
      _favoriteTemplateIds.remove(templateId);
    } else {
      _favoriteTemplateIds.add(templateId);
    }
    notifyListeners();
    await _save();
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    _hasSeenOnboarding = value;
    notifyListeners();
    await _save();
  }

  Future<void> setGuest(bool value) async {
    _isGuest = value;
    notifyListeners();
    await _save();
  }
}
