import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String _repoOwner = 'hongducdev';
  static const String _repoName = 'notecash';
  static const String _githubApiBase = 'https://api.github.com';
  static const String _githubAcceptHeader = 'application/vnd.github+json';
  static String get _releaseFallbackUrl =>
      'https://github.com/$_repoOwner/$_repoName/releases/latest';

  final Dio _dio = Dio();

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get<Map<String, dynamic>>(
        '$_githubApiBase/repos/$_repoOwner/$_repoName/releases/latest',
        options: Options(
          headers: const {
            'Accept': _githubAcceptHeader,
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'NoteCash',
          },
          validateStatus: (status) =>
              status != null && status >= 200 && status < 500,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 403) {
        final message = response.data?['message'] as String?;
        final remaining = response.headers.value('x-ratelimit-remaining');
        final reset = response.headers.value('x-ratelimit-reset');
        final retryAt = _formatRateLimitReset(reset);

        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          releasePageUrl: _releaseFallbackUrl,
          error: _buildGithub403Message(
            message: message,
            remaining: remaining,
            retryAt: retryAt,
          ),
        );
      }

      if (statusCode != 200 || response.data == null) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          releasePageUrl: _releaseFallbackUrl,
          error:
              'Không thể kiểm tra cập nhật (${statusCode == 0 ? 'unknown' : statusCode})',
        );
      }

      final data = response.data!;
      final latestTagRaw = data['tag_name'] as String?;
      final latestTag = _normalizeVersion(latestTagRaw);
      final releaseNotes = data['body'] as String? ?? '';
      final releasePageUrl = data['html_url'] as String?;
      final assets = data['assets'] as List<dynamic>? ?? [];

      if (latestTag == null) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          error: 'Không tìm thấy phiên bản mới',
        );
      }

      final apkAsset = _pickBestApkAsset(assets);

      if (apkAsset == null) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: latestTag,
          releasePageUrl: releasePageUrl,
          error: 'Không tìm thấy file APK',
        );
      }

      final downloadUrl = apkAsset['browser_download_url'] as String?;
      if (downloadUrl == null) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: latestTag,
          releasePageUrl: releasePageUrl,
          error: 'Không tìm thấy link tải',
        );
      }

      final hasUpdate =
          _compareVersions(
            _normalizeVersion(currentVersion) ?? currentVersion,
            latestTag,
          ) <
          0;

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestTag,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        releasePageUrl: releasePageUrl,
      );
    } on DioException catch (e) {
      final packageInfo = await PackageInfo.fromPlatform();
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      final message = data is Map
          ? (data['message'] as String?)
          : data?.toString();
      final baseMessage = statusCode == null
          ? 'Không thể kiểm tra cập nhật'
          : 'Không thể kiểm tra cập nhật ($statusCode)';
      final errorText = message == null || message.trim().isEmpty
          ? baseMessage
          : '$baseMessage: $message';
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: packageInfo.version,
        releasePageUrl: _releaseFallbackUrl,
        error: errorText,
      );
    } catch (e) {
      final packageInfo = await PackageInfo.fromPlatform();
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: packageInfo.version,
        releasePageUrl: _releaseFallbackUrl,
        error: 'Lỗi: $e',
      );
    }
  }

  Future<DownloadResult> downloadUpdate(
    String downloadUrl,
    void Function(double progress)? onProgress,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/notecash-update.apk';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return DownloadResult(success: true, filePath: filePath);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = status == null ? 'Lỗi tải' : 'Lỗi tải ($status)';
      return DownloadResult(success: false, error: message);
    } catch (e) {
      return DownloadResult(success: false, error: 'Lỗi tải: $e');
    }
  }

  Future<bool> installUpdate(String apkPath) async {
    try {
      final result = await OpenFilex.open(apkPath);
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic>? _pickBestApkAsset(List<dynamic> assets) {
    Map<String, dynamic>? best;
    var bestScore = -1;

    for (final a in assets) {
      if (a is! Map) continue;
      final name = (a['name'] as String?) ?? '';
      if (!name.toLowerCase().endsWith('.apk')) continue;

      var score = 0;
      final lower = name.toLowerCase();
      if (lower.contains('notecash')) score += 3;
      if (lower.contains('release')) score += 2;
      if (lower.contains('universal')) score += 2;
      if (lower.contains('app')) score += 1;

      if (score > bestScore) {
        bestScore = score;
        best = Map<String, dynamic>.from(a);
      }
    }

    return best;
  }

  String? _normalizeVersion(String? v) {
    if (v == null) return null;
    var out = v.trim();
    if (out.isEmpty) return null;
    if (out.startsWith('v') || out.startsWith('V')) {
      out = out.substring(1);
    }
    out = out.split('+').first;
    out = out.split('-').first;
    out = out.trim();
    return out.isEmpty ? null : out;
  }

  String? _formatRateLimitReset(String? epochSeconds) {
    if (epochSeconds == null) return null;
    final seconds = int.tryParse(epochSeconds);
    if (seconds == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toLocal();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$hh:$mm $dd/$mo/$yyyy';
  }

  String _buildGithub403Message({
    required String? message,
    required String? remaining,
    required String? retryAt,
  }) {
    final normalized = message?.trim();
    final remainingValue = int.tryParse((remaining ?? '').trim());

    if (remainingValue != null && remainingValue <= 0) {
      return retryAt == null
          ? 'GitHub API đang bị giới hạn truy cập. Vui lòng thử lại sau.'
          : 'GitHub API đang bị giới hạn truy cập. Thử lại sau $retryAt.';
    }

    if (normalized != null && normalized.isNotEmpty) {
      return 'GitHub từ chối yêu cầu: $normalized';
    }

    return 'GitHub từ chối yêu cầu (403).';
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).whereType<int>().toList();
    final parts2 = v2.split('.').map(int.tryParse).whereType<int>().toList();

    final maxLen = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;

    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  void dispose() {
    _dio.close();
  }
}

class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? releasePageUrl;
  final String? error;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.releasePageUrl,
    this.error,
  });
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;

  const DownloadResult({required this.success, this.filePath, this.error});
}
