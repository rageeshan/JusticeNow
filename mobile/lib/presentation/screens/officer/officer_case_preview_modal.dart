import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OfficerCasePreviewModal {
  static void show(BuildContext context, Map<String, dynamic> evidenceItem) {
    final originalName = evidenceItem['originalName']?.toString() ?? 'Evidence File';
    final rawUrl = evidenceItem['fileUrl']?.toString() ?? evidenceItem['url']?.toString() ?? '';
    final mimeType = (evidenceItem['mimeType'] ?? evidenceItem['fileType'] ?? '').toString().toLowerCase();
    final isImage = mimeType.contains('image');
    final isVideo = mimeType.contains('video');

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      originalName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 380),
                width: double.infinity,
                alignment: Alignment.center,
                child: isImage && rawUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          rawUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.broken_image_rounded, size: 64, color: AppColors.textMuted),
                              SizedBox(height: 8),
                              Text('Could not load image file',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVideo
                                  ? Icons.videocam_rounded
                                  : Icons.picture_as_pdf_rounded,
                              size: 64,
                              color: isVideo ? AppColors.accent : AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isVideo ? 'Video Evidence' : 'PDF Document',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              rawUrl.isNotEmpty ? rawUrl : originalName,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Preview'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
