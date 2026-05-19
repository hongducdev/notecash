import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notecash/core/providers.dart';
import 'package:notecash/services/notification_recognition_service.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const MethodChannel _installedAppsChannel = MethodChannel(
    'notecash/installed_apps',
  );

  final TextEditingController _searchController = TextEditingController();

  List<_InstalledAppOption> _installedApps = [];
  bool _loadingInstalledApps = false;

  Set<String> _trackedPackageNames = {};
  bool _loadedTrackedApps = false;

  @override
  void initState() {
    super.initState();
    _loadTrackedApps();
  }

  Future<void> _loadTrackedApps() async {
    final settings = await ref.read(isarServiceProvider).getUserSettings();
    final savedPackages =
        settings?.trackedNotificationPackages ?? const <String>[];
    if (savedPackages.isNotEmpty) {
      _trackedPackageNames = savedPackages.toSet();
    }
    if (mounted) {
      setState(() {
        _loadedTrackedApps = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureInstalledAppsLoaded() async {
    if (_installedApps.isNotEmpty) return;
    if (_loadingInstalledApps) return;

    setState(() {
      _loadingInstalledApps = true;
    });

    try {
      final raw = await _installedAppsChannel.invokeMethod<List<dynamic>>(
        'listInstalledApps',
      );
      final apps = (raw ?? const <dynamic>[])
          .whereType<Map>()
          .map((m) {
            final packageName = (m['packageName'] as String?) ?? '';
            final label = (m['label'] as String?) ?? packageName;
            if (packageName.isEmpty) return null;
            return _InstalledAppOption(packageName: packageName, label: label);
          })
          .whereType<_InstalledAppOption>()
          .toList();

      if (mounted) {
        setState(() {
          _installedApps = apps;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _installedApps = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingInstalledApps = false;
        });
      }
    }
  }

  Future<void> _openTrackedAppsPicker() async {
    await _ensureInstalledAppsLoaded();
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    final tempSelection = {..._trackedPackageNames};
    _searchController.text = '';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = _searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? _installedApps
                : _installedApps
                      .where(
                        (a) =>
                            a.label.toLowerCase().contains(query) ||
                            a.packageName.toLowerCase().contains(query),
                      )
                      .toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn ứng dụng theo dõi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NoteCash chỉ xử lý thông báo từ các ứng dụng bạn chọn.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Tìm theo tên hoặc package',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _loadingInstalledApps
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final opt = filtered[index];
                                final checked = tempSelection.contains(
                                  opt.packageName,
                                );
                                return CheckboxListTile(
                                  value: checked,
                                  onChanged: (value) {
                                    setModalState(() {
                                      if (value == true) {
                                        tempSelection.add(opt.packageName);
                                      } else {
                                        tempSelection.remove(opt.packageName);
                                      }
                                    });
                                  },
                                  title: Text(opt.label),
                                  subtitle: Text(opt.packageName),
                                  secondary: const Icon(Icons.apps_outlined),
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await NotificationRecognitionService.updateTrackedPackages(
                                tempSelection,
                              );
                              if (mounted) {
                                setState(() {
                                  _trackedPackageNames = tempSelection;
                                });
                              }
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã cập nhật ứng dụng theo dõi',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Lưu'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection('Tính năng thông minh', [
            _buildTile(
              Icons.notifications_active_outlined,
              'Nhận diện biến động số dư',
              subtitle: 'Tự động nhắc thêm giao dịch từ thông báo ngân hàng',
              onTap: () async {
                final hasPermission =
                    await NotificationListenerService.isPermissionGranted();
                await NotificationRecognitionService.startListening();
                if (hasPermission && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đã được kích hoạt!'),
                    ),
                  );
                }
              },
            ),
            _buildTile(
              Icons.tune_outlined,
              'Ứng dụng theo dõi',
              subtitle: 'Chọn app ngân hàng/ví để nhận diện giao dịch',
              trailing: _loadedTrackedApps
                  ? Text('${_trackedPackageNames.length} app')
                  : const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
              onTap: _openTrackedAppsPicker,
            ),
          ]),
          _buildSection('Chung', [
            _buildTile(
              Icons.dark_mode_outlined,
              'Chế độ tối',
              trailing: const Text('Luôn bật'),
            ),
          ]),
          _buildSection('Dữ liệu', [
            _buildTile(
              Icons.cloud_upload_outlined,
              'Sao lưu đám mây',
              trailing: const Text('V2'),
            ),
            _buildTile(
              Icons.file_download_outlined,
              'Xuất Excel',
              trailing: const Text('V2'),
            ),
          ]),
          _buildSection('Thông tin', [
            _buildTile(
              Icons.info_outline,
              'Phiên bản',
              trailing: const Text('1.0.0'),
            ),
            _buildTile(Icons.star_outline, 'Đánh giá ứng dụng'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTile(
    IconData icon,
    String title, {
    Widget? trailing,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            )
          : null,
      trailing: trailing,
      onTap: onTap ?? () {},
    );
  }
}

class _InstalledAppOption {
  final String packageName;
  final String label;

  const _InstalledAppOption({required this.packageName, required this.label});
}
