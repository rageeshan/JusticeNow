import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_aid_repository.dart';

class SubmitAdScreen extends StatefulWidget {
  const SubmitAdScreen({super.key});

  @override
  State<SubmitAdScreen> createState() => _SubmitAdScreenState();
}

class _SubmitAdScreenState extends State<SubmitAdScreen> {
  final LegalAidRepository _repo = LegalAidRepository();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _imageFileName;
  int? _imageFileSize;
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked != null) {
        final file = File(picked.path);
        final size = await file.length();
        setState(() {
          _selectedImage = file;
          _imageFileName = picked.name;
          _imageFileSize = size;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Upload Post Photo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.photo_library_rounded, color: AppColors.accent),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Select a flyer, poster or ad banner', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.accent),
                ),
                title: const Text('Take a Photo', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Capture using camera', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAd() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a photo to upload your post.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repo.submitLawyerAdPost(_selectedImage!);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
                SizedBox(width: 10),
                Text('Post Published', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
            content: const Text(
              'Your legal advertisement post has been published successfully and is now displayed on the citizen dashboard.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primaryDark,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit post: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Submit an Ad'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legal Awareness & Practice Ads',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Your post will be showcased directly in the sliding showcase on the citizen home screen.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Title: Add your post here
              const Text(
                'Add your post here',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload an image, flyer, or announcement poster for your legal post.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Photo Upload Card
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null
                          ? AppColors.accent.withValues(alpha: 0.8)
                          : AppColors.border,
                      width: _selectedImage != null ? 1.5 : 1.2,
                    ),
                  ),
                  child: _selectedImage == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: AppColors.accent,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tap to upload post photo',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Supports JPG, PNG (Flyers, posters, legal ads)',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showImageSourceSheet,
                                icon: const Icon(Icons.file_upload_outlined, size: 18),
                                label: const Text('Select Image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceVariant,
                                  foregroundColor: AppColors.accent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Preview
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 380),
                                color: Colors.black,
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            // Image details and actions
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.image_outlined, color: AppColors.accent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _imageFileName ?? 'Selected Image',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_imageFileSize != null)
                                          Text(
                                            _formatFileSize(_imageFileSize),
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showImageSourceSheet,
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.accent),
                                    label: const Text('Change', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
                                    tooltip: 'Remove photo',
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _imageFileName = null;
                                        _imageFileSize = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isSubmitting || _selectedImage == null) ? null : _submitAd,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                        )
                      : const Icon(Icons.publish_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Publishing...' : 'Publish Post',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
                    disabledForegroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
