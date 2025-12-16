import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/host_home.dart';

class CreatePostingScreen extends StatefulWidget {
  final PostingModel? posting;
  const CreatePostingScreen({super.key, this.posting});

  @override
  State<CreatePostingScreen> createState() => _CreatePostingScreenState();
}

class _CreatePostingScreenState extends State<CreatePostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _amenitiesController = TextEditingController();

  final List<String> _serviceTypes = [
    "Abhyanga Massage",
    "Shirodhara Therapy",
    "Detox Panchakarma",
    "Back Pain Kati Basti",
    "Stress Relief Combo",
  ];

  late String _selectedServiceType;
  late Map<String, int> _beds;
  late Map<String, int> _bathrooms;
  List<String> _base64Images = [];
  bool _isLoading = false;

  // Ayurvedic colors
  final Color _primaryColor = Color(0xFF2E7D32); // Deep green
  final Color _secondaryColor = Color(0xFF8BC34A); // Light green
  final Color _accentColor = Color(0xFF795548); // Earth brown
  final Color _backgroundColor = Color(0xFFF5F5DC); // Beige background
  final Color _cardColor = Color(0xFFFFFDE7); // Light yellow
  final Color _textColor = Color(0xFF5D4037); // Dark brown

  @override
  void initState() {
    super.initState();
    _selectedServiceType = _serviceTypes.first;
    _beds = {"small": 0, "medium": 0, "large": 0};
    _bathrooms = {"full": 0, "half": 0};

    // If editing an existing posting, populate fields
    if (widget.posting != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final posting = widget.posting!;
    _nameController.text = posting.name ?? '';
    _priceController.text = posting.price?.toString() ?? '';
    _descriptionController.text = posting.description ?? '';
    _addressController.text = posting.address ?? '';
    _cityController.text = posting.city ?? '';
    _countryController.text = posting.country ?? '';
    _amenitiesController.text = posting.amenities?.join(', ') ?? '';
    _selectedServiceType = posting.type ?? _serviceTypes.first;
    _beds = posting.beds ?? {"small": 0, "medium": 0, "large": 0};

    try {
      final baths = (posting as dynamic).bathrooms;
      if (baths is Map<String, int>) {
        _bathrooms = baths;
      } else if (baths is Map) {
        _bathrooms = baths.cast<String, int>();
      }
    } catch (_) {
      _bathrooms = {"full": 0, "half": 0};
    }
  }

  Future<void> _pickImage(int index) async {
    if (_isLoading) return;

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() {
          if (index < 0) {
            _base64Images.add(base64Image);
          } else {
            _base64Images[index] = base64Image;
          }
        });
      } catch (e) {
        Get.snackbar("Error", "Failed to process image: ${e.toString()}");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitPosting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_base64Images.isEmpty && (widget.posting == null || (widget.posting!.imageNames?.isEmpty ?? true))) {
      Get.snackbar("Error", "Please add at least one image");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final postingData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'amenities': _amenitiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'type': _selectedServiceType,
        'beds': _beds,
        'bathrooms': _bathrooms,
        'hostId': AppConstants.currentUser.id,
        'hostName': (AppConstants.currentUser.getFullNameofUser().isNotEmpty
            ? AppConstants.currentUser.getFullNameofUser()
            : (AppConstants.currentUser.email ?? '')),
        'hostEmail': AppConstants.currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      Future<List<String>> uploadImagesToStorage(String docId, List<String> base64Images) async {
        final List<String> imageNames = [];
        for (int i = 0; i < base64Images.length; i++) {
          try {
            final bytes = base64Decode(base64Images[i]);
            final imageName = "${docId}_image_${DateTime.now().millisecondsSinceEpoch}_$i.png";
            final ref = FirebaseStorage.instance.ref().child('postingImages').child(docId).child(imageName);
            await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
            imageNames.add(imageName);
          } catch (e) {
            debugPrint("Failed to upload image #$i: $e");
          }
        }
        return imageNames;
      }

      if (widget.posting != null && widget.posting!.id != null && widget.posting!.id!.isNotEmpty) {
        final docId = widget.posting!.id!;
        await FirebaseFirestore.instance.collection('service_listings').doc(docId).update(postingData);

        if (_base64Images.isNotEmpty) {
          final imageNames = await uploadImagesToStorage(docId, _base64Images);
          if (imageNames.isNotEmpty) {
            await FirebaseFirestore.instance.collection('service_listings').doc(docId).update({
              'imageNames': FieldValue.arrayUnion(imageNames),
            });
          }
        }

        Get.snackbar("Success", "Service updated successfully");
      } else {
        final docRef = await FirebaseFirestore.instance.collection('service_listings').add(postingData);
        final docId = docRef.id;

        if (_base64Images.isNotEmpty) {
          final imageNames = await uploadImagesToStorage(docId, _base64Images);
          if (imageNames.isNotEmpty) {
            await FirebaseFirestore.instance.collection('service_listings').doc(docId).update({
              'imageNames': imageNames,
            });
          }
        }

        Get.snackbar("Success", "Service created successfully");
      }

      Get.offAll(() => HostHomeScreen(Index: 1));
    } catch (e) {
      Get.snackbar("Error", "Failed to save: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

Widget _buildCounter(String label, int value, Function(int) onChanged) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 4),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _primaryColor.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        // Label - takes most of the space
        Expanded(
          flex: 3, // 75% of space
          child: Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w500, 
              color: _textColor,
              fontSize: 14, // Slightly smaller font
            ),
          ),
        ),
        
        SizedBox(width: 8), // Small gap between label and counter
        
        // Counter buttons - fixed width
        Container(
          width: 100, // Fixed width for counter section
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Minus button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primaryColor),
                ),
                child: IconButton(
                  icon: Icon(Icons.remove, size: 16, color: _primaryColor),
                  onPressed: () => onChanged(value - 1 < 0 ? 0 : value - 1),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              // Value display
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Text(
                  value.toString(), 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: _primaryColor, 
                    fontSize: 16
                  ),
                ),
              ),
              
              // Plus button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primaryColor),
                ),
                child: IconButton(
                  icon: Icon(Icons.add, size: 16, color: _primaryColor),
                  onPressed: () => onChanged(value + 1),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${_base64Images.length}/10 photos", 
          style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 12)),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _base64Images.length + (_base64Images.length < 10 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _base64Images.length) {
              return GestureDetector(
                onTap: () => _pickImage(-1),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    border: Border.all(color: _primaryColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 30, color: _primaryColor),
                      SizedBox(height: 4),
                      Text("Add", style: TextStyle(color: _primaryColor, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(_base64Images[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _cardColor, 
                        child: Icon(Icons.error, color: Colors.red),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _base64Images.removeAt(index)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFormField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: _cardColor,
        ),
        validator: (value) => value?.isEmpty ?? true ? "Required" : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.posting != null ? "Edit Ayurvedic Service" : "Add Ayurvedic Service",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_primaryColor)),
                  SizedBox(height: 16),
                  Text("Processing...", style: TextStyle(color: _textColor)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.spa, size: 40, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            "Ayurvedic Service Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Share the healing power of Ayurveda",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Basic Information
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: _primaryColor, size: 20),
                                SizedBox(width: 8),
                                Text("Basic Information", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor)),
                              ],
                            ),
                            SizedBox(height: 16),
                            _buildFormField(_nameController, "Treatment Name"),
                            
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: DropdownButtonFormField<String>(
                                value: _selectedServiceType,
                                items: _serviceTypes.map((type) => DropdownMenuItem(
                                  value: type, 
                                  child: Text(type, style: TextStyle(color: _textColor)),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedServiceType = value!),
                                decoration: InputDecoration(
                                  labelText: "Therapy Type",
                                  labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: _primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: _cardColor,
                                ),
                                dropdownColor: _cardColor,
                                style: TextStyle(color: _textColor),
                                validator: (value) => value == null ? "Required" : null,
                              ),
                            ),

                            _buildFormField(_priceController, "Price (\$)", 
                              keyboardType: TextInputType.numberWithOptions(decimal: true)),
                            
                            _buildFormField(_descriptionController, "Description", maxLines: 3),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Location Information
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: _primaryColor, size: 20),
                                SizedBox(width: 8),
                                Text("Clinic Location", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor)),
                              ],
                            ),
                            SizedBox(height: 16),
                            _buildFormField(_addressController, "Clinic Address"),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(_cityController, "City"),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(_countryController, "Country"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Session Slots
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, color: _primaryColor, size: 20),
                                SizedBox(width: 10),
                                Text("Session Slots Available", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor)),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildCounter("Abhyanga Massage", _beds["small"]!, (value) => setState(() => _beds["small"] = value)),
                            _buildCounter("Shirodhara Therapy", _beds["medium"]!, (value) => setState(() => _beds["medium"] = value)),
                            _buildCounter("Detox Panchakarma", _beds["large"]!, (value) => setState(() => _beds["large"] = value)),
                            _buildCounter("Back Pain Kati Basti", _bathrooms["full"]!, (value) => setState(() => _bathrooms["full"] = value)),
                            _buildCounter("Stress Relief Combo", _bathrooms["half"]!, (value) => setState(() => _bathrooms["half"] = value)),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Treatment Details
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medical_services, color: _primaryColor, size: 20),
                                SizedBox(width: 8),
                                Text("Treatment Details", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor)),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildFormField(_amenitiesController, "Treatment Details & Amenities", maxLines: 3),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Photos
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(16), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.photo_library, color: _primaryColor, size: 20),
                                SizedBox(width: 8),
                                Text("Treatment/Clinic Photos", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor)),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildImageGrid(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitPosting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading 
                            ? SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.spa, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    widget.posting != null ? "Update Ayurvedic Service" : "Upload Ayurvedic Service",
                                    style: TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}