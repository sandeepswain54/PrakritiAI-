import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/instance_manager.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/views/Widgets/create_posting_screen.dart';
import 'package:service_app/views/Widgets/posting_List_tile_button.dart';
import 'package:service_app/views/Widgets/posting_listing_tile_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MyPoastingScreen extends StatefulWidget {
  const MyPoastingScreen({super.key});

  @override
  State<MyPoastingScreen> createState() => _MyPoastingScreenState();
}

class _MyPoastingScreenState extends State<MyPoastingScreen>
    with TickerProviderStateMixin {
  // Ayurvedic colors
  final Color _primaryColor = Color(0xFF2E7D32); // Deep green
  final Color _secondaryColor = Color(0xFF8BC34A); // Light green
  final Color _accentColor = Color(0xFF795548); // Earth brown
  final Color _backgroundColor = Color(0xFFF5F5DC); // Beige background
  final Color _cardColor = Color(0xFFFFFDE7); // Light yellow
  final Color _textColor = Color(0xFF5D4037); // Dark brown

  late VideoPlayerController _videoController1;
  late VideoPlayerController _videoController2;
  ChewieController? _chewieController1;
  ChewieController? _chewieController2;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    try {
      // Initialize first video
      _videoController1 = VideoPlayerController.asset('assets/yukti23.mp4');
      await _videoController1.initialize();
      
      // Initialize second video
      _videoController2 = VideoPlayerController.asset('assets/yukti2.mp4');
      await _videoController2.initialize();

      // Initialize Chewie controllers for better video controls
      _chewieController1 = ChewieController(
        videoPlayerController: _videoController1,
        autoPlay: false,
        looping: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: _primaryColor,
          handleColor: _primaryColor,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade200,
        ),
      );

      _chewieController2 = ChewieController(
        videoPlayerController: _videoController2,
        autoPlay: false,
        looping: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: _primaryColor,
          handleColor: _primaryColor,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade200,
        ),
      );

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('Error initializing videos: $e');
      // If videos fail to load, still set initialized to true to show placeholder
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController1.dispose();
    _videoController2.dispose();
    _chewieController1?.dispose();
    _chewieController2?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Main scrollable content
          Padding(
            padding: const EdgeInsets.only(top: 25, bottom: 80), // Space for bottom button
            child: ListView.builder(
              itemCount: AppConstants.currentUser.myPostings!.length + 3, // +3 for button and 2 videos
              itemBuilder: (context, index) {
                // Show videos when there are no postings
                if (AppConstants.currentUser.myPostings!.isEmpty) {
                  if (index == 0) {
                    return _buildVideoSection(
                      title: "How to Create Your First Ayurvedic Listing",
                      videoController: _chewieController1,
                      isInitialized: _isVideoInitialized,
                    );
                  } else if (index == 1) {
                    return _buildVideoSection(
                      title: "Tips for Successful Ayurvedic Listings", 
                      videoController: _chewieController2,
                      isInitialized: _isVideoInitialized,
                    );
                  } else if (index == 2) {
                    return _buildCreateListingButton();
                  }
                }
                
                // Original logic when there are postings
                final postingIndex = AppConstants.currentUser.myPostings!.isEmpty ? 
                    index - 3 : index;
                
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: InkResponse(
                    onTap: () {
                      Get.to(
                        CreatePostingScreen(
                          posting: (postingIndex == AppConstants.currentUser.myPostings!.length)
                              ? null
                              : AppConstants.currentUser.myPostings![postingIndex],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: (postingIndex == AppConstants.currentUser.myPostings!.length)
                          ? const PostingTileButton()
                          : PostingListingTileUi(posting: AppConstants.currentUser.myPostings![postingIndex]),
                    ),
                  ),
                );
              },
            ),
          ),

          // Fixed bottom button
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: InkResponse(
                onTap: () {
                  Get.to(const CreatePostingScreen(posting: null));
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.spa, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Create Ayurvedic Listing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection({
    required String title,
    required ChewieController? videoController,
    required bool isInitialized,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.play_circle_filled, color: _primaryColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isInitialized && videoController != null
                  ? Chewie(controller: videoController)
                  : Container(
                      color: _primaryColor.withOpacity(0.05),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                            SizedBox(height: 12),
                            Text(
                              'Loading Ayurvedic Tutorial...',
                              style: TextStyle(
                                color: _textColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCreateListingButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          border: Border.all(
            color: _primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const PostingTileButton(),
      ),
    );
  }
}