// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/settings/settings_event.dart';
import '../../blocs/settings/settings_state.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
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
                  const Divider(),
                  _buildThemeColorSection(context, state),
                  const Divider(),
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
        const Text(
          'Chế độ giao diện',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        RadioListTile<ThemeMode>(
          title: const Text('Hệ thống'),
          value: ThemeMode.system,
          groupValue: state.themeMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleThemeMode(value!));
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Sáng'),
          value: ThemeMode.light,
          groupValue: state.themeMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleThemeMode(value!));
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Tối'),
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
      Colors.teal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Màu giao diện',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                context.read<SettingsBloc>().add(ChangeThemeColor(color));
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: state.primaryColor == color
                      ? Border.all(
                    color: Colors.white,
                    width: 3,
                  )
                      : null,
                ),
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
        const Text(
          'Quản lý dữ liệu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Thêm dữ liệu vào hệ thống'),
          onTap: () => _importData(context),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Xuất dữ liệu'),
          onTap: () => _exportData(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text(
            'Xóa toàn bộ dữ liệu',
            style: TextStyle(color: Colors.red),
          ),
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
        context.read<SettingsBloc>().add(ImportData(result.files.single.path!));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dữ liệu đã được thêm vào thành công')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm vào dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final filePath = await context.read<SettingsRepository>().getBackupFilePath();
      context.read<SettingsBloc>().add(ExportData(filePath));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dữ liệu đã được xuất ra đến: $filePath'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu'),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ dữ liệu. Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(ClearAllData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tất cả dữ liệu đã được xóa')),
      );
    }
  }
}