import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/features/home/data/models/story_model.dart';
import 'package:localtrade/features/home/providers/stories_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    required this.userId,
    required this.stories,
    super.key,
  });

  final String userId;
  final List<StoryModel> stories;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late PageController _pageController;
  late Timer _timer;
  int _currentStoryIndex = 0;
  double _progress = 0.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startProgressTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startProgressTimer() {
    if (_isPaused) return;
    
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (!_isPaused) {
        setState(() {
          _progress += 0.05 / 5; // 5 seconds per story
          
          if (_progress >= 1.0) {
            _progress = 0.0;
            _nextStory();
          }
        });
      }
    });
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      _currentStoryIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _currentStoryIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentStoryIndex = index;
      _progress = 0.0;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      _timer.cancel();
    } else {
      _startProgressTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No stories available')),
      );
    }

    final currentStory = widget.stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _togglePause(),
        onTapUp: (_) => _togglePause(),
        child: Stack(
          children: [
            // Story Image
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story);
              },
            ),
            
            // Progress Indicators
            _buildProgressIndicators(),
            
            // Header
            _buildHeader(currentStory),
            
            // Bottom Actions
            _buildBottomActions(currentStory),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedImage(
          imageUrl: story.imageUrl,
          fit: BoxFit.cover,
        ),
        // Text Overlay
        if (story.text != null)
          Positioned(
            top: story.textPosition == TextPosition.top ? 100 : null,
            bottom: story.textPosition == TextPosition.bottom ? 100 : null,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  story.text!,
                  style: TextStyle(
                    color: story.textColor ?? Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicators() {
    return Positioned(
      top: 40,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(widget.stories.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  if (index == _currentStoryIndex)
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                  else if (index < _currentStoryIndex)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(StoryModel story) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: story.userProfileImage != null
                ? NetworkImage(story.userProfileImage!)
                : null,
            child: story.userProfileImage == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTimeUntilExpiry(story.timeUntilExpiry),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(StoryModel story) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
            onPressed: _previousStory,
          ),
          IconButton(
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 40,
            ),
            onPressed: _togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
            onPressed: _nextStory,
          ),
        ],
      ),
    );
  }

  String _formatTimeUntilExpiry(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m left';
    } else {
      return 'Expiring soon';
    }
  }
}

