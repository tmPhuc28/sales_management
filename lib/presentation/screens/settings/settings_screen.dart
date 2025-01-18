// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/presentation/widgets/custom_app_bar.dart';
import 'package:path_provider/path_provider.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.settings),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildThemeModeSection(context, state),
                  const Divider(height: 32),
                  _buildThemeColorSection(context, state),
                  const Divider(height: 32),
                  _buildDataSection(context),
                ],
              ),
              if (state.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeModeSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.theme,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        RadioListTile<ThemeMode>(
          title: const Text(AppStrings.systemMode),
          value: ThemeMode.system,
          groupValue: state.themeMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleThemeMode(value!));
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text(AppStrings.lightMode),
          value: ThemeMode.light,
          groupValue: state.themeMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleThemeMode(value!));
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text(AppStrings.darkMode),
          value: ThemeMode.dark,
          groupValue: state.themeMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleThemeMode(value!));
          },
        ),
      ],
    );
  }

  Widget _buildThemeColorSection(BuildContext context, SettingsState state) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.indigo,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.themeColor,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: colors.map((color) {
            final isSelected = state.primaryColor == color;
            return InkWell(
              onTap: () {
                context.read<SettingsBloc>().add(ChangeThemeColor(color));
              },
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.dataManagement,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text(AppStrings.importData),
          subtitle: const Text(AppStrings.importDataDesc),
          onTap: () => _importData(context),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text(AppStrings.exportData),
          subtitle: const Text(AppStrings.exportDataDesc),
          onTap: () => _exportData(context),
        ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: const Text('Vị trí file dữ liệu'),
          subtitle: const Text('Xem vị trí lưu trữ file dữ liệu'),
          onTap: () => _showBackupLocation(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text(
            AppStrings.clearData,
            style: TextStyle(color: Colors.red),
          ),
          subtitle: const Text(AppStrings.clearDataDesc),
          onTap: () => _confirmClearData(context),
        ),
      ],
    );
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        if (context.mounted) {
          context
              .read<SettingsBloc>()
              .add(ImportData(result.files.single.path!));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.dataImportSuccess)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.error}: $e')),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final filePath =
          await context.read<SettingsRepository>().getBackupFilePath();
      context.read<SettingsBloc>().add(ExportData(filePath));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.dataExportSuccess(filePath)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.error}: $e')),
        );
      }
    }
  }

  Future<void> _showBackupLocation(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vị trí lưu trữ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File dữ liệu được lưu tại:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(directory.path),
                const SizedBox(height: 16),
                const Text(
                  'Tên file:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('backup_[timestamp].json'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.error}: $e')),
        );
      }
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearData),
        content: const Text(AppStrings.clearDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.clear),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(ClearAllData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.dataCleared)),
      );
    }
  }
}
