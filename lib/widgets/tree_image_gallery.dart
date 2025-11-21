import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TreeImageGallery extends StatefulWidget {
  final List<String> images; // paths or URLs
  final void Function(int idx) onDelete;
  final List<DateTime?>? imageDates;
  final List<String>? imageSources; // 'camera', 'gallery', 'cloud'
  final int initialIndex;

  const TreeImageGallery({
    super.key,
    required this.images,
    required this.onDelete,
    this.imageDates,
    this.imageSources,
    this.initialIndex = 0,
  });

  @override
  State<TreeImageGallery> createState() => _TreeImageGalleryState();
}

class _TreeImageGalleryState extends State<TreeImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<void> _deleteImage(int idx) async {
    final img = widget.images[idx];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      if (img.startsWith('http')) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(img);
          await ref.delete();
        } catch (_) {}
      } else if (!img.startsWith('data:')) {
        final file = File(img);
        if (file.existsSync()) file.deleteSync();
      }
      widget.onDelete(idx);
      if (mounted) {
        if (widget.images.length == 1) Navigator.pop(context);
        else setState(() {});
      }
    }
  }

  // Web-compatible image widget
  Widget _buildWebCompatibleImage(String imagePath) {
    try {
      if (imagePath.startsWith('http')) {
        return Image.network(imagePath, fit: BoxFit.contain);
      }

      if (imagePath.startsWith('data:')) {
        final uri = Uri.parse(imagePath);
        final data = uri.data;
        if (data != null) {
          final bytes = data.contentAsBytes();
          return Image.memory(bytes, fit: BoxFit.contain);
        }
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.contain);
        }
      }

      if (kIsWeb) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                imagePath.length > 30 ? '${imagePath.substring(0, 27)}...' : imagePath,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error, color: Colors.red, size: 48),
      );
    } catch (e) {
      // Fallback for any errors
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error, color: Colors.red, size: 48),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Dismissible(
      key: const ValueKey('gallery'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, idx) {
                  final img = images[idx];
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: _buildWebCompatibleImage(img),
                  );
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 32),
                  onPressed: () => _deleteImage(_currentIndex),
                ),
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (widget.imageDates != null && widget.imageDates!.length > _currentIndex && widget.imageDates![_currentIndex] != null)
                      Text(
                        'Captured: ${DateFormat.yMMMd().add_jm().format(widget.imageDates![_currentIndex]!)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    if (widget.imageSources != null && widget.imageSources!.length > _currentIndex)
                      Text(
                        'Source: ${widget.imageSources![_currentIndex]}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
