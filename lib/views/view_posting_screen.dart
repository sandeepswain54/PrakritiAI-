import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/model/conversation_model.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/Host_Screens/book_listing_screen.dart';
import 'package:service_app/views/Widgets/posting_info_tile_ui.dart';
import 'package:service_app/views/conversation_screen.dart';

class ViewPostingScreen extends StatefulWidget {
  final PostingModel? posting;

  ViewPostingScreen({super.key, this.posting});

  @override
  State<ViewPostingScreen> createState() => _ViewPostingScreenState();
}

class _ViewPostingScreenState extends State<ViewPostingScreen> {
  // Ayurvedic colors
  final Color _primaryColor = Color(0xFF2E7D32); // Deep green
  final Color _secondaryColor = Color(0xFF8BC34A); // Light green
  final Color _accentColor = Color(0xFF795548); // Earth brown
  final Color _backgroundColor = Color(0xFFF5F5DC); // Beige background
  final Color _cardColor = Color(0xFFFFFDE7); // Light yellow
  final Color _textColor = Color(0xFF5D4037); // Dark brown

  late PostingModel posting;
  bool isLoading = true;

  Future<void> getRequiredInfo() async {
    try {
      await posting.getAllImagesFromStorage();
      await posting.getHostFromFirestore();
      
      // Debug: Print host information
      print("Host ID: ${posting.host?.id}");
      print("Host Name: ${posting.host?.getFullNameofUser()}");
      print("Host Display Image: ${posting.host?.displayImage}");
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting!;
    getRequiredInfo();
  }

  Future<void> _startConversation() async {
    if (posting.host != null && posting.host!.id != null) {
      try {
        // Show loading indicator
        Get.dialog(
          Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor))),
          barrierDismissible: false,
        );

        // Create a ContactModel for the host
        ContactModel hostContact = ContactModel(
          id: posting.host!.id,
          firstname: posting.host!.firstname,
          lastname: posting.host!.lastname,
        );

        // Initialize a new conversation
        ConversationModel conversation = ConversationModel();
        
        // Check if conversation already exists or create new one
        QuerySnapshot conversationSnapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .where("userIDs", arrayContains: AppConstants.currentUser.id)
            .get();

        bool conversationExists = false;
        
        for (var doc in conversationSnapshot.docs) {
          List<dynamic> userIDs = doc["userIDs"] ?? [];
          if (userIDs.contains(posting.host!.id)) {
            // Existing conversation found
            conversation.id = doc.id;
            await conversation.getConversationInfoFromFirestore(doc);
            conversationExists = true;
            break;
          }
        }

        if (!conversationExists) {
          // Create new conversation
          await conversation.addConversationToFirestore(hostContact);
        }

        // Close loading dialog
        if (Get.isDialogOpen!) Get.back();

        // Navigate to conversation screen
        Get.to(() => ConversationScreen(conversation: conversation));
        
      } catch (e) {
        // Close loading dialog if still open
        if (Get.isDialogOpen!) Get.back();
        
        Get.snackbar(
          'Error',
          'Could not start conversation: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
        print("Conversation error: $e");
      }
    } else {
      Get.snackbar(
        'Error',
        'Host information is not available',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text("Ayurvedic Clinic Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              if (posting.id != null && posting.id!.isNotEmpty) {
                AppConstants.currentUser.addSavedPosting(posting);
                Get.snackbar('Saved', 'Added to your saved list');
              } else {
                Get.snackbar('Failed to save', 'Posting ID is missing');
              }
            },
            icon: Icon(Icons.bookmark_add, color: Colors.white),
          )
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                  SizedBox(height: 16),
                  Text("Loading Ayurvedic Details...", style: TextStyle(color: _textColor)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Listing Images
                // Listing Images
AspectRatio(
  aspectRatio: 2 / 2,
  child: (posting.displayImages.isEmpty)
      ? Image.network(
          "https://ayusanjivani.com/wp-content/uploads/2023/08/Paramkaram.jpg",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 50, color: _primaryColor.withOpacity(0.5)),
                    SizedBox(height: 8),
                    Text("Ayurvedic Therapy", style: TextStyle(color: _primaryColor)),
                  ],
                ),
              ),
            );
          },
        )
      : PageView.builder(
          itemCount: posting.displayImages.length,
          itemBuilder: (context, index) {
            try {
              MemoryImage currentImage = posting.displayImages[index];
              return Image(
                image: currentImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fall back to URL image when MemoryImage fails
                  return Image.network(
                    "https://ayusanjivani.com/wp-content/uploads/2023/08/Paramkaram.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  );
                },
              );
            } catch (e) {
              // If MemoryImage creation fails, use URL image directly
              return Image.network(
                "https://content.jdmagicbox.com/v2/comp/mumbai/t7/022pxx22.xx22.220704061529.e3t7/catalogue/swarayu-ayurveda-clinic-and-panchakarma-centre-vile-parle-east-mumbai-ayurvedic-doctors-fl937dh2qf-250.jpg",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.broken_image)),
                  );
                },
              );
            }
          },
        ),
),
                  // Main Content Card
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Posting Name and Book Now button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.medical_services, color: _primaryColor, size: 24),
                                  SizedBox(height: 8),
                                  Text(
                                    posting.name!.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: _textColor,
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Book Now button with price
                            Column(
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryColor, _secondaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: MaterialButton(
                                    onPressed: () {
                                      final hostId = posting.host?.id ?? '';
                                      Get.to(() => BookListingScreen(posting: posting, hostID: hostId));
                                    },
                                    child: Text(
                                      "Book Session",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "\$${posting.price}/Session",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryColor),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),

                        SizedBox(height: 24),

                        // Description and Host Profile
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.description, color: _primaryColor, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        "Treatment Description",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _primaryColor.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      posting.description!,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(fontSize: 14, color: _textColor, height: 1.4),
                                      maxLines: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: _startConversation,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_primaryColor, _secondaryColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: MediaQuery.of(context).size.width / 12,
                                      backgroundColor: _cardColor,
                                      child: posting.host?.displayImage != null
                                          ? CircleAvatar(
                                              backgroundImage: posting.host!.displayImage,
                                              radius: MediaQuery.of(context).size.width / 13,
                                            )
                                          : CircleAvatar(
                                              radius: MediaQuery.of(context).size.width / 13,
                                              backgroundColor: _primaryColor.withOpacity(0.1),
                                              child: Icon(
                                                Icons.spa,
                                                color: _primaryColor,
                                                size: 24,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    posting.host?.getFullNameofUser() ?? "Ayurvedic Clinic",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: _primaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Tap to Chat",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _textColor.withOpacity(0.6),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Service Details Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.medical_information, color: _primaryColor, size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Service Details",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        ListView(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            PostingInfoTileUi(
                              iconData: Icons.health_and_safety,
                              category: "Service Type",
                              categoryInfo: posting.type ?? "Not specified",
                            ),
                            PostingInfoTileUi(
                              iconData: Icons.access_time,
                              category: "Slots Available Today",
                              categoryInfo: "${posting.getGuestsNumber()} available bookings",
                            ),
                            PostingInfoTileUi(
                              iconData: Icons.category,
                              category: "Therapy Category",
                              categoryInfo: posting.type ?? "General Ayurvedic",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Available Durations Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer, color: _primaryColor, size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Available Durations",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 3.6,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            children: posting.amenities != null 
                                ? List.generate(
                                    posting.amenities!.length,
                                    (index) {
                                      String currentAmenity = posting.amenities![index];
                                      // Different image URLs for each amenity based on index
                                      List<String> amenityImageUrls = [
                                        "https://ayusanjivani.com/wp-content/uploads/2023/08/Paramkaram.jpg",
                                        "https://i.pinimg.com/1200x/39/c9/72/39c972be5d1cd2b1cb93ac0da362cd25.jpg",
                                        "https://i.pinimg.com/1200x/17/13/1f/17131f0c9182c2e30b94ab2f0b3c0aeb.jpg",
                                        "https://i.pinimg.com/736x/49/d0/ea/49d0eaee76ffbb25fd52e0b5a1925bdd.jpg",
                                        "https://i.pinimg.com/1200x/db/87/1f/db871f0cddcc345954d04b89426cdcc7.jpg",
                                        "https://ind.5bestincity.com/profileimages/india/jiva-ayurveda-clinic-ayurvedic-clinics-saheed-nagar-bhubaneswar-odisha/36369-79553-3.jpg",
                                      ];
                                      
                                      String imageUrl = amenityImageUrls[index % amenityImageUrls.length];
                                      
                                      return Container(
                                        margin: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [Colors.white, _primaryColor.withOpacity(0.05)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(color: _primaryColor.withOpacity(0.2)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Image for each amenity
                                            Container(
                                              width: 45,
                                              height: 45,
                                              margin: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                image: DecorationImage(
                                                  image: NetworkImage(imageUrl),
                                                  fit: BoxFit.cover,
                                                ),
                                                border: Border.all(color: _primaryColor.withOpacity(0.3)),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(right: 8),
                                                child: Text(
                                                  currentAmenity,
                                                  style: TextStyle(
                                                    color: _textColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : [
                                    Container(
                                      margin: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: _primaryColor.withOpacity(0.05),
                                        border: Border.all(color: _primaryColor.withOpacity(0.2)),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text("No durations available", style: TextStyle(color: _textColor.withOpacity(0.6))),
                                        ),
                                      ),
                                    )
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Location Card
                  Container(
                    margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: _primaryColor, size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Clinic Location",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.place, color: _primaryColor, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  posting.getFullAddress(),
                                  style: TextStyle(fontSize: 14, color: _textColor, height: 1.4),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFallbackImage() {
  return Image.network(
    "https://ayusanjivani.com/wp-content/uploads/2023/08/Ayusanjivani-Ayurveda-is-a-Pune-based-clinic-that-specializes-in-Ayurvedic-therapy.jpg",
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: _primaryColor.withOpacity(0.5)),
              SizedBox(height: 8),
              Text("Image not available", style: TextStyle(color: _primaryColor)),
            ],
          ),
        ),
      );
    },
  );
}}