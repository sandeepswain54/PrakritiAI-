import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/view_posting_screen.dart';

class PostingGridTileUi extends StatefulWidget {
  final PostingModel? posting;
  const PostingGridTileUi({super.key, this.posting});

  @override
  State<PostingGridTileUi> createState() => _PostingGridTileUiState();
}

class _PostingGridTileUiState extends State<PostingGridTileUi> {
  late PostingModel? posting;
  bool _isLoading = true;

  // List of exactly 10 specific image names from your assets
  final List<String> _placeholderImages = [
    'assets/pppp.png',
    'assets/pppp2.png',
    'assets/pppp3.png',
    'assets/pppp4.png',
    'assets/po1.jpg',
    'assets/po3.jpg',
    'assets/po.jpg',
    'assets/po4.jpg',
    'assets/po5.jpg',
    'assets/pppp1.png',
  ];

  Future<void> _loadImage() async {
    if (posting == null) return;
    try {
      await posting!.getFirstImageFromStorage();
    } catch (e) {
      debugPrint("Error loading image: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadImage());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.20),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Top image section with fixed aspect and expansion
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildImageContainer(),
                ),
              ),
            ),
            // Card content area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextInfo("${posting?.type ?? ''} - ${posting?.city ?? ''},${posting?.country ?? ''}"),
                  const SizedBox(height: 2),
                  _buildTextInfo(posting?.name ?? ''),
                  const SizedBox(height: 2),
                  _buildPriceSection(),
                  _buildRatingBar(),
                  const SizedBox(height: 2),
                  _buildAddButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer() {
    if (_isLoading) {
      return Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final images = posting?.displayImages;
    if (images == null || images.isEmpty) {
      // Show one of the exact 10 ppp images randomly
      return _buildPlaceholderImage();
    }
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: images.first,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    // Get random index between 0-9 for the 10 images
    final randomIndex = DateTime.now().millisecondsSinceEpoch % 10;
    final imagePath = _placeholderImages[randomIndex];
    
    return Container(
      color: Colors.grey[100],
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if the specific ppp image doesn't exist
          return Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, size: 40)),
          );
        },
      ),
    );
  }

  Widget _buildTextInfo(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPriceSection() {
    return Row(
      children: [
        const SizedBox(width: 4),
        Text(
          "₹${posting?.price?.toStringAsFixed(2) ?? '--'}",
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 2),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            elevation: 0
          ),
          child: const Text("Book Now"),
          onPressed: () {
            if (posting != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewPostingScreen(posting: posting)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Posting data unavailable')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    return Row(
      children: [
        RatingBar.readOnly(
          size: 14,
          maxRating: 5,
          initialRating: posting?.getCurrentRating() ?? 0,
          filledIcon: Icons.star,
          emptyIcon: Icons.star_border,
          filledColor: Colors.yellow[700] ?? Colors.yellow,
        ),
      ],
    );
  }
}