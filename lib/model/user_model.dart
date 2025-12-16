import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/booking_model.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/model/conversation_model.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/model/review_model.dart';

class UserModel extends ContactModel {
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  String? bio;
  String? city;
  String? country;
  bool? isHost;
  bool? isCurrentlyHosting;
  DocumentSnapshot? snapshot;

  List<BookingModel>? bookings;
  List<ReviewModel> reviews = [];
  List<PostingModel>? savedPostings;
  List<PostingModel>? myPostings;

  UserModel({
    String? id = '',
    String? firstname = '',
    String? lastname = '',
    MemoryImage? displayImage,
    this.email = '',
    this.password = '',
    this.bio = '',
    this.city = '',
    this.country,
  })  : firstName = firstname,
        lastName = lastname,
        super(
          id: id,
          firstname: firstname,
          lastname: lastname,
          displayImage: displayImage,
        ) {
    isHost = false;
    isCurrentlyHosting = false;
    bookings = [];
    reviews = [];
    savedPostings = [];
    myPostings = [];


    
  }

  

  ContactModel createContactFromUser() {
    return ContactModel(
      id: id,
      firstname: firstName,
      lastname: lastName,
      displayImage: displayImage
    );
  }

  Future<void> getUserInfoFromFirestore(DocumentSnapshot snapshot) async {
    try {
      this.snapshot = snapshot;
      id = snapshot.id;
      firstName = snapshot['firstName'] ?? '';
      lastName = snapshot['lastName'] ?? '';
      email = snapshot['email'] ?? '';
      bio = snapshot['bio'] ?? '';
      city = snapshot['city'] ?? '';
      country = snapshot['country'] ?? '';
      isHost = snapshot['isHost'] ?? false;
      isCurrentlyHosting = snapshot['isCurrentlyHosting'] ?? false;

      // Load saved postings when user data is loaded
      await getSavedPostingsFromFirestore();
      await getMyPostingsFromFirestore();
    } catch (e) {
      Get.snackbar("Error", "Failed to load user data: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> saveUserToFirestore() async {
    try {
      Map<String, dynamic> dataMap = {
        'bio': bio,
        'city': city,
        'country': country,
        'email': email,
        'firstName': firstName,
        "lastName": lastName,
        'isHost': isHost ?? false,
        "myPostingIDs": myPostings?.map((p) => p.id!).toList() ?? [],
        "savedPostingIDs": savedPostings?.map((p) => p.id!).toList() ?? [],
        "earning": 0,
      };
      await FirebaseFirestore.instance.collection('users').doc(id).set(dataMap);
    } catch (e) {
      Get.snackbar("Error", "Failed to save user: ${e.toString()}");
      rethrow;
    }
  }

  String getFullNameofUser() {
    return "${firstName ?? ''} ${lastName ?? ''}".trim();
  }

  Future<void> addPostingToMyPostings(PostingModel posting) async {
    try {
      myPostings!.add(posting);
      List<String> myPostingIDs = myPostings!.map((p) => p.id!).toList();
      
      await FirebaseFirestore.instance.collection("users").doc(id).update({
        'myPostingIDs': myPostingIDs,
      });
    } catch (e) {
      Get.snackbar("Error", "Failed to add posting: ${e.toString()}");
      myPostings!.remove(posting);
      rethrow;
    }
  }

  Future<void> getMyPostingsFromFirestore() async {
    try {
      myPostings?.clear();
      List<String> myPostingIDs = List<String>.from(snapshot?["myPostingIDs"] ?? []);

      for (String postingID in myPostingIDs) {
        PostingModel posting = PostingModel(id: postingID);
        await posting.getPostingInfoFromFirestore();
        await posting.getAllBookingFromFirestore();
        await posting.getAllImagesFromStorage();
        myPostings!.add(posting);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load postings: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> getSavedPostingsFromFirestore() async {
    try {
      savedPostings?.clear();
      List<String> savedPostingIDs = List<String>.from(snapshot?["savedPostingIDs"] ?? []);

      for (String postingID in savedPostingIDs) {
        PostingModel posting = PostingModel(id: postingID);
        await posting.getPostingInfoFromFirestore();
        await posting.getAllImagesFromStorage();
        savedPostings!.add(posting);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load saved postings: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> addSavedPosting(PostingModel posting) async {
    try {
      if (savedPostings!.any((p) => p.id == posting.id)) {
        return;
      }

      savedPostings!.add(posting);
      List<String> savedPostingIDs = savedPostings!.map((p) => p.id!).toList();
      
      await FirebaseFirestore.instance.collection("users").doc(id).update({
        "savedPostingIDs": savedPostingIDs,
      });

      Get.snackbar("Saved", "Added to your favorites");
    } catch (e) {
      Get.snackbar("Error", "Failed to save: ${e.toString()}");
      savedPostings!.removeWhere((p) => p.id == posting.id);
      rethrow;
    }
  }

  Future<void> removeSavedPosting(PostingModel posting) async {
    try {
      savedPostings!.removeWhere((p) => p.id == posting.id);
      List<String> savedPostingIDs = savedPostings!.map((p) => p.id!).toList();

      await FirebaseFirestore.instance.collection("users").doc(id).update({
        "savedPostingIDs": savedPostingIDs,
      });
      
      Get.snackbar("Removed", "Posting removed from saved");
    } catch (e) {
      Get.snackbar("Error", "Failed to remove: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> addBookingToFirestore(BookingModel booking, double totalPriceForAllNights, String hostID) async {
    try {
      String earningsOld = "";

      await FirebaseFirestore.instance.collection("users").doc(hostID).get().then((dataSnap) {
        earningsOld = dataSnap["earning"].toString();
      });

      Map<String, dynamic> data = {
        "dates": booking.dates,
        "postingID": booking.postingModel!.id!,
      };
      
      await FirebaseFirestore.instance.doc("users/${id}/bookings/${booking.id}").set(data);
      await FirebaseFirestore.instance.collection("users").doc(hostID).update({
        "earnings": totalPriceForAllNights + int.parse(earningsOld),
      });
      
      bookings!.add(booking);
      await addBookingConversation(booking);
    } catch (e) {
      Get.snackbar("Error", "Failed to add booking: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> addBookingConversation(BookingModel booking) async {
    try {
      ConversationModel conversation = ConversationModel();
      await conversation.addConversationToFirestore(booking.postingModel!.host!);

      String textMessage = "Hi my name is ${AppConstants.currentUser!.firstName} and I have "
          "just booked ${booking.postingModel!.name} from ${booking.dates!.first} to "
          "${booking.dates!.last} if you have any questions contact me. Enjoy your stay!";

      await conversation.addMessageToFirestore(textMessage);
    } catch (e) {
      Get.snackbar("Error", "Failed to create conversation: ${e.toString()}");
      rethrow;
    }
  }

  List<DateTime> getAllBookedDates() {
    List<DateTime> allBookedDates = [];

    myPostings!.forEach((posting) {
      posting.bookings!.forEach((booking) {
        if (booking.dates != null) {
          allBookedDates.addAll(booking.dates!);
        }
      });
    });

    return allBookedDates;
  }
}