import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageViewerDialog extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String title;

  const ImageViewerDialog({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.title = 'ছবি দেখুন',
  });

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
          );
        },
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
      return const Center(
        child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.imagePaths.length > 1
              ? '${widget.title} (${_currentIndex + 1}/${widget.imagePaths.length})'
              : widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: widget.imagePaths.isEmpty
          ? const Center(child: Text('কোনো ছবি পাওয়া যায়নি', style: TextStyle(color: Colors.white70)))
          : PageView.builder(
              controller: _pageController,
              itemCount: widget.imagePaths.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: _buildImage(widget.imagePaths[index]),
                  ),
                );
              },
            ),
    );
  }
}
