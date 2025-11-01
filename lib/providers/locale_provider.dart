import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en', 'US'));

  void setLocale(String languageCode) {
    state = Locale(languageCode);
  }
}
