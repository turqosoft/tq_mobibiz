import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class BrochureHelper {
  final Dio _dio;
  final String serverUrl;

  BrochureHelper({required this.serverUrl, required String cookies})
      : _dio = Dio()
    ..options.headers = {
      'Cookie': cookies,
    };

  /// Returns the local [File] after downloading, or null on failure.
  Future<File?> _downloadBrochure({
    required String brochurePath,
    required BuildContext context,
    required void Function(double progress) onProgress,
  }) async {
    final String url = '$serverUrl$brochurePath';
    final String fileName = brochurePath.split('/').last;

    try {
      // Get temp directory (works on both Android & iOS)
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      // Use cached file if already downloaded
      if (await file.exists()) return file;

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

      return file;
    } catch (e) {
      debugPrint('Brochure download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download brochure. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Download and open the brochure with the device's default viewer.
  Future<void> openBrochure({
    required String brochurePath,
    required BuildContext context,
  }) async {
    double progress = 0;

    // Show download progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(
        progressNotifier: ValueNotifier(progress),
        fileName: brochurePath.split('/').last,
      ),
    );

    final file = await _downloadBrochure(
      brochurePath: brochurePath,
      context: context,
      onProgress: (p) => progress = p,
    );

    if (context.mounted) Navigator.pop(context); // close dialog

    if (file == null) return;

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file: ${result.message}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Download and share the brochure via the system share sheet.
  Future<void> shareBrochure({
    required String brochurePath,
    required String itemName,
    required BuildContext context,
  }) async {
    double progress = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(
        progressNotifier: ValueNotifier(progress),
        fileName: brochurePath.split('/').last,
      ),
    );

    final file = await _downloadBrochure(
      brochurePath: brochurePath,
      context: context,
      onProgress: (p) => progress = p,
    );

    if (context.mounted) Navigator.pop(context); // close dialog

    if (file == null) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '$itemName - Product Brochure',
      text: 'Please find the product brochure for $itemName attached.',
    );
  }
}

// ── Progress dialog shown during download ─────────────────────────────────────

class _ProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progressNotifier;
  final String fileName;

  const _ProgressDialog({
    required this.progressNotifier,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (_, progress, __) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Downloading',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 6,
                ),
              ),
              if (progress > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}