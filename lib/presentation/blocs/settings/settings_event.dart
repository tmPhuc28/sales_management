// lib/presentation/blocs/settings/settings_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class ToggleThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  const ToggleThemeMode(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class ChangeThemeColor extends SettingsEvent {
  final Color primaryColor;
  const ChangeThemeColor(this.primaryColor);

  @override
  List<Object> get props => [primaryColor];
}

class ClearAllData extends SettingsEvent {}

class ImportData extends SettingsEvent {
  final String filePath;
  const ImportData(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class ExportData extends SettingsEvent {
  final String filePath;
  const ExportData(this.filePath);

  @override
  List<Object> get props => [filePath];
}