import 'dart:io';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Memory-optimized Receipt Image Thumbnail View.
///
/// Uses [ResizeImage] to constrain decoded bitmap dimensions to a max of 256x256
/// pixels. This prevents allocating multi-megabyte uncompressed camera bitmaps in RAM
/// during list rendering and detail inspection.
class ReceiptThumbnailView extends StatelessWidget {
  const ReceiptThumbnailView({
    super.key,
    required this.imagePath,
    this.width = 64.0,
    this.height = 64.0,
    this.borderRadius = 12.0,
    this.maxDecodeWidth = 256,
    this.maxDecodeHeight = 256,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final String? imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final int maxDecodeWidth;
  final int maxDecodeHeight;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imagePath == null || imagePath!.isEmpty) {
      content = _buildPlaceholder(Icons.receipt_long_rounded);
    } else {
      final file = File(imagePath!);
      if (!file.existsSync()) {
        content = _buildPlaceholder(Icons.broken_image_rounded);
      } else {
        final ImageProvider provider = ResizeImage(
          FileImage(file),
          width: maxDecodeWidth,
          height: maxDecodeHeight,
          allowUpscaling: false,
        );

        content = Image(
          image: provider,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(Icons.broken_image_rounded);
          },
        );
      }
    }

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceCardHover,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.borderStroke),
        ),
        child: content,
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: clipped,
      );
    }

    return clipped;
  }

  Widget _buildPlaceholder(IconData icon) {
    return Center(
      child: Icon(
        icon,
        size: width * 0.45,
        color: AppColors.textMuted.withValues(alpha: 0.6),
      ),
    );
  }
}
