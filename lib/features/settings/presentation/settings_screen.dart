import 'package:flutter/material.dart';
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
  static final List<_TrackedAppOption> _appOptions = [
    _TrackedAppOption(
      key: 'techcombank',
      label: 'Techcombank',
      icon: Icons.account_balance_outlined,
    ),
    _TrackedAppOption(
      key: 'vietinbank',
      label: 'VietinBank',
      icon: Icons.account_balance_outlined,
    ),
    _TrackedAppOption(
      key: 'timo',
      label: 'Timo',
      icon: Icons.account_balance_outlined,
    ),
    _TrackedAppOption(
      key: 'cake',
      label: 'Cake',
      icon: Icons.account_balance_outlined,
    ),
    _TrackedAppOption(
      key: 'momo',
      label: 'MoMo',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _TrackedAppOption(
      key: 'zalopay',
      label: 'ZaloPay',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  late Set<String> _trackedAppKeys = _appOptions.map((e) => e.key).toSet();
  bool _loadedTrackedApps = false;

  @override
  void initState() {
    super.initState();
    _loadTrackedApps();
  }

  Future<void> _loadTrackedApps() async {
    final settings = await ref.read(isarServiceProvider).getUserSettings();
    final saved = settings?.trackedNotificationApps;
    if (saved != null && saved.isNotEmpty) {
      _trackedAppKeys = saved.toSet();
    }
    if (mounted) {
      setState(() {
        _loadedTrackedApps = true;
      });
    }
  }

  Future<void> _openTrackedAppsPicker() async {
    final colorScheme = Theme.of(context).colorScheme;
    final tempSelection = {..._trackedAppKeys};

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _appOptions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final opt = _appOptions[index];
                          final checked = tempSelection.contains(opt.key);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelection.add(opt.key);
                                } else {
                                  tempSelection.remove(opt.key);
                                }
                              });
                            },
                            title: Text(opt.label),
                            secondary: Icon(opt.icon),
                            controlAffinity: ListTileControlAffinity.trailing,
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
                              await NotificationRecognitionService.updateTrackedApps(
                                tempSelection,
                              );
                              if (mounted) {
                                setState(() {
                                  _trackedAppKeys = tempSelection;
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
                bool hasPermission =
                    await NotificationListenerService.isPermissionGranted();
                if (!hasPermission) {
                  NotificationRecognitionService.startListening();
                } else {
                  NotificationRecognitionService.startListening();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đã được kích hoạt!'),
                      ),
                    );
                  }
                }
              },
            ),
            _buildTile(
              Icons.tune_outlined,
              'Ứng dụng theo dõi',
              subtitle: 'Chọn app ngân hàng/ví để nhận diện giao dịch',
              trailing: _loadedTrackedApps
                  ? Text('${_trackedAppKeys.length} app')
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
            _buildTile(
              Icons.language_outlined,
              'Ngôn ngữ',
              trailing: const Text('Tiếng Việt'),
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
          color: Colors.white.withOpacity(0.05),
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

class _TrackedAppOption {
  final String key;
  final String label;
  final IconData icon;

  const _TrackedAppOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}
