import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:path/path.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/booking_model.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/model/global.dart';
import 'package:service_app/model/review_model.dart';


class PostingModel {
  String? id;
  String? name;
  String? type;
  double? price;
  String? description;
  String? address;
  String? city;
  String? country;
  double? rating;
  ContactModel? host;
  List<String>? imageNames;
  List<Uint8List>? displayImagesBytes;
  List<String>? amenities;
  Map<String, int>? beds;
  Map<String, int>? bathroom;
  List<BookingModel>? bookings;
  List<ReviewModel>? reviews;
  List<MemoryImage>? _memoryImagesCache;
  

  PostingModel({
    this.id = "",
    this.name = "",
    this.type = "",
    this.price = 0,
    this.description = '',
    this.address = '',
    this.city = '',
    this.country = "",
    this.host,
    this.imageNames,
    this.displayImagesBytes,
    this.amenities,
    this.beds,
    this.bathroom,
    this.rating,
    this.bookings,
    this.reviews,
  }) {
    imageNames = imageNames ?? [];
    displayImagesBytes = displayImagesBytes ?? [];
    amenities = amenities ?? [];
    beds = beds ?? {"small": 0, "medium": 0, "large": 0};
    bathroom = bathroom ?? {"full": 0, "half": 0};
    rating = rating ?? 0;
    bookings = bookings ?? [];
    reviews = reviews ?? [];
    List<MemoryImage>? displayImages = [];

  }

  List<MemoryImage> get displayImages {
    _memoryImagesCache ??= displayImagesBytes
        ?.map((bytes) => MemoryImage(bytes))
        .toList() ?? [];
    return _memoryImagesCache!;
  }

  get user => null;

  get details => null;

  set displayImages(List<MemoryImage> images) {
    _memoryImagesCache = images;
    displayImagesBytes = images.map((img) => img.bytes).toList();
  }

  void updateFrom(PostingModel newData) {
    name = newData.name;
    type = newData.type;
    price = newData.price;
    description = newData.description;
    address = newData.address;
    city = newData.city;
    country = newData.country;
    amenities = newData.amenities;
    beds = newData.beds;
    bathroom = newData.bathroom;
    
    if (newData.displayImagesBytes != null && 
        newData.displayImagesBytes!.isNotEmpty) {
      displayImagesBytes = newData.displayImagesBytes;
      _memoryImagesCache = null;
    }
  }

  void setImagesNames() {
    imageNames = [];
    for (int i = 0; i < displayImagesBytes!.length; i++) {
      imageNames!.add("${id}image${DateTime.now().millisecondsSinceEpoch}_$i.png");
    }
  }

  List<Uint8List> getNewImages() {
    if (imageNames == null || displayImagesBytes == null) return [];
    
    if (displayImagesBytes!.length > imageNames!.length) {
      return displayImagesBytes!.sublist(imageNames!.length);
    }
    
    return [];
  }

  

  Future<void> getPostingInfoFromFirestore() async {
    if (id == null || id!.isEmpty) return;
    
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection("postings")
        .doc(id)
        .get();
    getPostingInfoFromSnapshot(snapshot);
  }

  void getPostingInfoFromSnapshot(DocumentSnapshot snapshot) {
    try {
      id = snapshot.id;
      name = snapshot.get('name') ?? "";
      type = snapshot.get('type') ?? "";
      price = (snapshot.get('price') ?? 0.0).toDouble();
      description = snapshot.get('description') ?? "";
      address = snapshot.get('address') ?? "";
      city = snapshot.get('city') ?? "";
      country = snapshot.get('country') ?? "";
      rating = (snapshot.get('rating') ?? 0.0).toDouble();
      
      amenities = snapshot.exists && snapshot.data() != null 
          ? List<String>.from((snapshot.data() as Map<String, dynamic>)['amenities'] ?? [])
          : [];

      beds = snapshot.exists && snapshot.data() != null
          ? Map<String, int>.from((snapshot.data() as Map<String, dynamic>)['beds'] ?? {"small": 0, "medium": 0, "large": 0})
          : {"small": 0, "medium": 0, "large": 0};

      bathroom = snapshot.exists && snapshot.data() != null
          ? Map<String, int>.from((snapshot.data() as Map<String, dynamic>)['bathrooms'] ?? {"full": 0, "half": 0})
          : {"full": 0, "half": 0};

      imageNames = snapshot.exists && snapshot.data() != null
          ? List<String>.from((snapshot.data() as Map<String, dynamic>)['imageNames'] ?? [])
          : [];

      String hostId = snapshot.get('hostID') ?? "";
      if (hostId.isNotEmpty) {
        host = ContactModel(id: hostId);
      }
    } catch (e) {
      debugPrint("Error parsing posting snapshot: $e");
      throw Exception("Failed to parse posting data");
    }
  }

  Future<ImageProvider?> getFirstImageFromStorage() async {
  if (id == null || imageNames == null || imageNames!.isEmpty) {
    debugPrint("❌ Missing ID or imageNames");
    return null;
  }

  try {
    final imageData = await FirebaseStorage.instance
        .ref("postingImages/$id/${imageNames!.first}")
        .getData(1024 * 1024);

    if (imageData != null) {
      displayImagesBytes = [imageData];
      _memoryImagesCache = [MemoryImage(imageData)];
      return _memoryImagesCache!.first;
    }
  } catch (e) {
    debugPrint("🔥 Image load error: $e");
  }

  return null;
}


Future<void> getAllImagesFromStorage() async {
  if (id == null || imageNames == null || imageNames!.isEmpty) {
    debugPrint("❌ Missing ID or imageNames");
    displayImages = [];
    return;
  }

  displayImages = [];

  try {
    for (String name in imageNames!) {
      final data = await FirebaseStorage.instance
          .ref("postingImages/$id/$name")
          .getData(1024 * 1024);

      if (data != null) {
        displayImages!.add(MemoryImage(data));
      }
    }
  } catch (e) {
    debugPrint("🔥 Error loading images: $e");
  }
}


  String getAmenititesString() {
    return amenities?.join(", ") ?? "";
  }

  double getCurrentRating() {
    if (reviews == null || reviews!.isEmpty) return 4.0;

    double rating = 0;
    reviews!.forEach((review) {
      rating += review.rating ?? 0;
    });
    return rating / reviews!.length;
  }

  PostingModel copyWith({
    String? id,
    String? name,
    String? type,
    double? price,
    String? description,
    String? address,
    String? city,
    String? country,
    double? rating,
    ContactModel? host,
    List<String>? imageNames,
    List<Uint8List>? displayImagesBytes,
    List<String>? amenities,
    Map<String, int>? beds,
    Map<String, int>? bathroom,
    List<BookingModel>? bookings,
    List<ReviewModel>? reviews,
  }) {
    return PostingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      rating: rating ?? this.rating,
      host: host ?? this.host,
      imageNames: imageNames ?? List.from(this.imageNames ?? []),
      displayImagesBytes: displayImagesBytes ?? List.from(this.displayImagesBytes ?? []),
      amenities: amenities ?? List.from(this.amenities ?? []),
      beds: beds ?? Map.from(this.beds ?? {}),
      bathroom: bathroom ?? Map.from(this.bathroom ?? {}),
      bookings: bookings ?? List.from(this.bookings ?? []),
      reviews: reviews ?? List.from(this.reviews ?? []),
    );
  }

  static PostingModel fromMap(Map<String, dynamic> data) {
    return PostingModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      host: data['hostID'] != null ? ContactModel(id: data['hostID']) : null,
      imageNames: List<String>.from(data['imageNames'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      beds: Map<String, int>.from(data['beds'] ?? {"small": 0, "medium": 0, "large": 0}),
      bathroom: Map<String, int>.from(data['bathrooms'] ?? {"full": 0, "half": 0}),
    );
  }

  Future<void> getHostFromFirestore() async {
    if (host != null) {
      await host!.getContactInfoFromFirestore();
      await host!.getImageFromStorage();
    }
  }

  int getGuestsNumber() {
    int numGuests = 0;
    numGuests += beds?["small"] ?? 0;
    numGuests += (beds?["medium"] ?? 0) * 2;
    numGuests += (beds?["large"] ?? 0) * 2;
    return numGuests;
  }

  String getBedroomText() {
    String text = "";
    if ((beds?["small"] ?? 0) != 0) {
      text += "${beds!["small"]} single/twin ";
    }
    if ((beds?["medium"] ?? 0) != 0) {
      text += "${beds!["medium"]} double ";
    }
    if ((beds?["large"] ?? 0) != 0) {
      text += "${beds!["large"]} queen/king";
    }
    return text.trim();
  }

  String getBathroomText() {
    String text = "";
    if ((bathroom?["full"] ?? 0) != 0) {
      text += "${bathroom!["full"]} full ";
    }
    if ((bathroom?["half"] ?? 0) != 0) {
      text += "${bathroom!["half"]} half";
    }
    return text.trim();
  }

  String getFullAddress() {
    return [address, city, country].where((part) => part?.isNotEmpty ?? false).join(", ");
  }

  Future<void> getAllBookingFromFirestore() async {
    bookings = [];

    if (id == null || id!.isEmpty) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("postings")
        .doc(id)
        .collection("bookings")
        .get();

    for (var doc in snapshot.docs) {
      BookingModel newBooking = BookingModel();
      await newBooking.getAllBookingInfoFromFirestoreFromPosting(this, doc);
      bookings!.add(newBooking);
    }
  }

  List<DateTime> getAllBookedDates() {
    List<DateTime> dates = [];
    bookings?.forEach((booking) {
      if (booking.dates != null) {
        dates.addAll(booking.dates!);
      }
    });
    return dates;
  }

  

Future<void> makeNewBooking(List<DateTime> dates, BuildContext context, String hostID) async {
  // 1. Validate all inputs
  try {
    // Validate posting
    if (id == null || id!.isEmpty) {
      throw Exception('Invalid posting reference');
    }

    // Validate dates
    if (dates.isEmpty) {
      throw Exception('Please select at least one date');
    }

    // Validate price
    if (price == null || price! <= 0) {
      throw Exception('Invalid price for this accommodation');
    }

    // 2. Validate user
    if (AppConstants.currentUser == null) {
      throw Exception('User not authenticated - please log in');
    }

    final currentUser = AppConstants.currentUser!;
    
    if (currentUser.id == null || currentUser.id!.isEmpty) {
      throw Exception('Booked Sucessfully');
    }

    // 3. Prepare booking data with fallbacks
    final userName = currentUser.getFullNameofUser() ?? 'Guest User';

    
    final userId = currentUser.id!;
    
    final bookingData = {
      'dates': dates.map((date) => Timestamp.fromDate(date)).toList(),
      'name': userName,
      'userID': userId,
      'payment': dates.length * price!,
      'createdAt': FieldValue.serverTimestamp(),
      'postingID': id!,
      'hostID': hostID,
      'status': 'pending',
    };

    // 4. Create booking document
    final bookingRef = await FirebaseFirestore.instance
        .collection('postings')
        .doc(id)
        .collection('bookings')
        .add(bookingData);

    // 5. Update local models
    final newBooking = BookingModel()
      ..createBooking(
        this,
        currentUser.createUserFromContact(),
        dates,
      )
      ..id = bookingRef.id;

    bookings ??= [];
    bookings!.add(newBooking);

    // 6. Update user's bookings
    await currentUser.addBookingToFirestore(
      newBooking,
     (bookingData['payment'] as num).toDouble(),
      hostID,
    );

    // 7. Show success
    Get.snackbar(
      'Booking Confirmed',
      'Your booking for ${name} has been created',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  } catch (e) {
    debugPrint('❌ Booking Error: ${e.toString()}');
    debugPrint('Stack Trace: ${StackTrace.current}');
    
    Get.snackbar(
      'Booking Confirmed',
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
    
    rethrow;
  }
}
}