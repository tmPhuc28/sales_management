// lib/presentation/blocs/settings/settings_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management/data/repositories/settings_repository.dart';
import 'package:sales_management/presentation/blocs/settings/settings_event.dart';
import 'package:sales_management/presentation/blocs/settings/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final SharedPreferences _prefs;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required SharedPreferences prefs,
  })  : _settingsRepository = settingsRepository,
        _prefs = prefs,
        super(SettingsState(
        themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? 0],
        primaryColor: Color(prefs.getInt('primaryColor') ?? Colors.blue.value),
      )) {
    on<ToggleThemeMode>(_onToggleThemeMode);
    on<ChangeThemeColor>(_onChangeThemeColor);
    on<ClearAllData>(_onClearAllData);
    on<ImportData>(_onImportData);
    on<ExportData>(_onExportData);
  }

  void _onToggleThemeMode(ToggleThemeMode event, Emitter<SettingsState> emit) async {
    await _prefs.setInt('themeMode', event.themeMode.index);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onChangeThemeColor(ChangeThemeColor event, Emitter<SettingsState> emit) async {
    await _prefs.setInt('primaryColor', event.primaryColor.value);
    emit(state.copyWith(primaryColor: event.primaryColor));
  }

  Future<void> _onClearAllData(ClearAllData event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _settingsRepository.clearAllData();
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onImportData(ImportData event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _settingsRepository.importData(event.filePath);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onExportData(ExportData event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _settingsRepository.exportData(event.filePath);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}