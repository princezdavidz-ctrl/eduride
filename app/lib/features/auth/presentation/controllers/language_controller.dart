import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  const LanguageState({this.languageCode = 'en'});

  final String languageCode;

  LanguageState copyWith({String? languageCode}) {
    return LanguageState(languageCode: languageCode ?? this.languageCode);
  }
}

class LanguageController extends ChangeNotifier {
  LanguageController() {
    _loadSavedLocale();
  }

  static const _storageKey = 'selected_language';

  LanguageState state = const LanguageState();

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey) ?? 'en';
    state = state.copyWith(languageCode: saved);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.languageCode);
    state = state.copyWith(languageCode: locale.languageCode);
    notifyListeners();
  }

  Locale get locale => Locale(state.languageCode);
}
