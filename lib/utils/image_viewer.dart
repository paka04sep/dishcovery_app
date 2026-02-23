import 'dart:ui';
import 'package:flutter/material.dart';

class ImageViewer {
  /// =========================
  /// ดูรูปเดียว (Fullscreen + Blur)
  /// =========================
  static void showSingle(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Image",
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              /// Blur Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),

              /// Image
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// =========================
  ///  ดูทั้งหมด (Grid Overlay)
  /// =========================
  static void showGallery(BuildContext context, List<String> images) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Gallery",
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return _GalleryOverlay(images: images);
      },
    );
  }
}

/// =========================
/// Internal Widget (Grid View)
/// =========================
class _GalleryOverlay extends StatelessWidget {
  final List<String> images;

  const _GalleryOverlay({required this.images});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Blur Background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.black.withOpacity(0.4)),
        ),

        /// Grid Images (2 columns)
        GridView.builder(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 20,
            20,
            40,
          ),
          itemCount: images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final image = images[index];

            return GestureDetector(
              onTap: () {
                /// กดใน gallery  ดูรูปนั้นต่อได้
                ImageViewer.showSingle(context, image);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(image, fit: BoxFit.cover),
              ),
            );
          },
        ),

        /// Close Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
