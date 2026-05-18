import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

  Widget _buildTile(IconData icon, String title, {Widget? trailing}) {
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
      trailing: trailing,
      onTap: () {},
    );
  }
}
