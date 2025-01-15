// lib/presentation/blocs/settings/settings_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Color primaryColor;
  final bool isLoading;
  final String? error;

  const SettingsState({
    required this.themeMode,
    required this.primaryColor,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Color? primaryColor,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [themeMode, primaryColor, isLoading, error];
}
