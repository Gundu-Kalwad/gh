import 'package:flutter/material.dart';
import 'dart:async';

class PhotoCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const PhotoCarousel({Key? key, required this.imageUrls}) : super(key: key);

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  late final PageController _controller;
  int _currentPage = 0;
  late final Duration _autoSlideDuration;
  late final Duration _animationDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    _autoSlideDuration = const Duration(seconds: 4);
    _animationDuration = const Duration(milliseconds: 500);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(_autoSlideDuration, (timer) {
      if (_controller.hasClients && widget.imageUrls.isNotEmpty) {
        int nextPage = (_currentPage + 1) % widget.imageUrls.length;
        _controller.animateToPage(
          nextPage,
          duration: _animationDuration,
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = width * 9 / 16; // 16:9 aspect ratio
    return SizedBox(
      width: width,
      height: height,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return Image.network(
            widget.imageUrls[index],
            fit: BoxFit.cover,
            width: width,
            height: height,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

