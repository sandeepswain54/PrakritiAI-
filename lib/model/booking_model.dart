import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/model/posting_model.dart';

class BookingModel {
  String? id;
  PostingModel? posting;
  PostingModel? postingModel;
  ContactModel? user;
  ContactModel? host;
  List<DateTime>? dates;
  double? price;
  DateTime? createdAt;
  String? status; // pending, confirmed, cancelled, completed
  String? paymentMethod;
  String? transactionId;
  bool? isPaid;
  String? specialRequests;

  BookingModel({
    this.id,
    this.posting,
    this.user,
    this.host,
    this.dates,
    this.price,
    this.createdAt,
    this.status = "pending",
    this.paymentMethod,
    this.transactionId,
    this.isPaid = false,
    this.specialRequests,
  });

  /// Create a booking from scratch
  void createBooking(
    PostingModel posting,
    ContactModel user,
    List<DateTime> dates, {
    String? specialRequests,
  }) {
    this.posting = posting;
    this.user = user;
    this.dates = dates;
    this.createdAt = DateTime.now();
    this.status = "pending";
    this.price = calculateTotalPrice();
    this.specialRequests = specialRequests;
  }

  /// Calculate total price
  double calculateTotalPrice() {
    if (posting == null || dates == null || dates!.isEmpty) return 0.0;
    return dates!.length * (posting!.price ?? 0.0);
  }

  /// Load booking info from Firestore
  Future<void> getAllBookingInfoFromFirestore(DocumentSnapshot snapshot) async {
    try {
      id = snapshot.id;
      final data = snapshot.data() as Map<String, dynamic>? ?? {};

      if (data['dates'] != null) {
        dates = (data['dates'] as List<dynamic>)
            .map((ts) => (ts as Timestamp).toDate())
            .toList();
      }

      if (data['postingID'] != null) {
        posting = PostingModel(id: data['postingID']);
        await posting!.getPostingInfoFromFirestore();
      }

      if (data['userID'] != null) {
        user = ContactModel(id: data['userID']);
        await user!.getContactInfoFromFirestore();
      }

      if (data['hostID'] != null) {
        host = ContactModel(id: data['hostID']);
        await host!.getContactInfoFromFirestore();
      }

      price = data['price']?.toDouble() ?? calculateTotalPrice();
      status = data['status']?.toString() ?? "pending";
      paymentMethod = data['paymentMethod']?.toString();
      transactionId = data['transactionId']?.toString();
      isPaid = data['isPaid'] ?? false;
      specialRequests = data['specialRequests']?.toString();
      createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    } catch (e) {
      Get.snackbar("Error", "Failed to load booking: ${e.toString()}");
      rethrow;
    }
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'postingID': posting?.id,
      'userID': user?.id,
      'hostID': host?.id ?? posting?.host?.id,
      'dates': dates?.map((date) => Timestamp.fromDate(date)).toList(),
      'price': price ?? calculateTotalPrice(),
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'isPaid': isPaid,
      'specialRequests': specialRequests,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }


/// booking info from firestoreposting 

Future<void> getAllBookingInfoFromFirestoreFromPosting(
    PostingModel postingModel, DocumentSnapshot snapshot) async {
  try {
    id = snapshot.id;
    final data = snapshot.data() as Map<String, dynamic>? ?? {};

    posting = postingModel; // Directly assign the passed posting
    host = postingModel.host;

    if (data['dates'] != null) {
      dates = (data['dates'] as List<dynamic>)
          .map((ts) => (ts as Timestamp).toDate())
          .toList();
    }

    if (data['userID'] != null) {
      user = ContactModel(id: data['userID']);
      await user!.getContactInfoFromFirestore();
    }

    price = data['price']?.toDouble() ?? calculateTotalPrice();
    status = data['status']?.toString() ?? "pending";
    paymentMethod = data['paymentMethod']?.toString();
    transactionId = data['transactionId']?.toString();
    isPaid = data['isPaid'] ?? false;
    specialRequests = data['specialRequests']?.toString();
    createdAt = (data['createdAt'] as Timestamp?)?.toDate();
  } catch (e) {
    Get.snackbar("Error", "Failed to load booking: ${e.toString()}");
    rethrow;
  }
}



  /// Save booking to Firestore
  Future<void> saveBookingToFirestore() async {
    try {
      if (posting?.id == null) throw Exception("Posting reference required");
      if (user?.id == null) throw Exception("User reference required");

      final bookingsRef = FirebaseFirestore.instance
          .collection('postings')
          .doc(posting!.id)
          .collection('bookings');

      if (id == null) {
        DocumentReference docRef = await bookingsRef.add(toFirestoreMap());
        id = docRef.id;
      } else {
        await bookingsRef.doc(id).set(toFirestoreMap());
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save booking: ${e.toString()}");
      rethrow;
    }
  }

  /// Confirm payment
  Future<void> confirmPayment(String paymentMethod, String transactionId) async {
    try {
      this.paymentMethod = paymentMethod;
      this.transactionId = transactionId;
      this.isPaid = true;
      this.status = "confirmed";

      await saveBookingToFirestore();

      if (host?.id != null && price != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(host!.id)
            .update({'earnings': FieldValue.increment(price!)});
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to confirm payment: ${e.toString()}");
      rethrow;
    }
  }

  /// Cancel booking
  Future<void> cancelBooking() async {
    try {
      if (status == "cancelled") return;
      status = "cancelled";
      await saveBookingToFirestore();
    } catch (e) {
      Get.snackbar("Error", "Failed to cancel booking: ${e.toString()}");
      rethrow;
    }
  }

  /// Duration
  int getDuration() => dates?.length ?? 0;

  /// Formatted date range
  String getFormattedDateRange() {
    if (dates == null || dates!.isEmpty) return "No dates selected";
    dates!.sort();
    final first = dates!.first;
    final last = dates!.last;
    return dates!.length == 1
        ? _formatDate(first)
        : "${_formatDate(first)} - ${_formatDate(last)}";
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";

  /// Copy with method
  BookingModel copyWith({
    String? id,
    PostingModel? posting,
    ContactModel? user,
    ContactModel? host,
    List<DateTime>? dates,
    double? price,
    DateTime? createdAt,
    String? status,
    String? paymentMethod,
    String? transactionId,
    bool? isPaid,
    String? specialRequests,
  }) {
    return BookingModel(
      id: id ?? this.id,
      posting: posting ?? this.posting,
      user: user ?? this.user,
      host: host ?? this.host,
      dates: dates ?? (this.dates != null ? List.from(this.dates!) : null),
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      isPaid: isPaid ?? this.isPaid,
      specialRequests: specialRequests ?? this.specialRequests,
    );
  }

  /// Active
  bool get isActive {
    if (dates == null || dates!.isEmpty) return false;
    final now = DateTime.now();
    return dates!.any((d) => d.isAfter(now)) && status == "confirmed";
  }

  /// Completed
  bool get isCompleted {
    if (dates == null || dates!.isEmpty) return false;
    final now = DateTime.now();
    return dates!.every((d) => d.isBefore(now)) && status == "confirmed";
  }
}
