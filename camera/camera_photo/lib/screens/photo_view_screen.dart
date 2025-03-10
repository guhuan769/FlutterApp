import 'dart:io';

import 'package:camera_photo/providers/photo_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PhotoViewScreen extends StatefulWidget {
  final List<File> photos;
  final int initialIndex;

  const PhotoViewScreen({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
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

  Future<void> _deleteCurrentPhoto(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这张照片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<PhotoProvider>(context, listen: false);
      await provider.deletePhoto(widget.photos[_currentIndex]);

      if (widget.photos.length <= 1) {
        // 如果是最后一张照片，返回上一页
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (_currentIndex == widget.photos.length - 1) {
        // 如果是最后一张，显示前一张
        setState(() {
          _currentIndex--;
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1}/${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // 添加删除按钮
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
            onPressed: () => _deleteCurrentPhoto(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Hero(
                  tag: widget.photos[index].path,
                  child: Image.file(
                    widget.photos[index],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}