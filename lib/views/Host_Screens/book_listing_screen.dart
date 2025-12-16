import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pay/pay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_app/CONFIG_Notification/twilio_service.dart';

import 'package:service_app/Payment_Gateway/payment_config.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/model/conversation_model.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/views/Widgets/Booking_Time.dart';

import 'package:service_app/views/conversation_screen.dart';
import 'package:service_app/views/host_home.dart';

class BookListingScreen extends StatefulWidget {
  final PostingModel? posting;
  final String? hostID;

  const BookListingScreen({super.key, this.posting, this.hostID});

  @override
  State<BookListingScreen> createState() => _BookListingScreenState();
}

class _BookListingScreenState extends State<BookListingScreen> {
  // Ayurvedic colors
  final Color _primaryColor = Color(0xFF2E7D32); // Deep green
  final Color _secondaryColor = Color(0xFF8BC34A); // Light green
  final Color _accentColor = Color(0xFF795548); // Earth brown
  final Color _backgroundColor = Color(0xFFF5F5DC); // Beige background
  final Color _cardColor = Color(0xFFFFFDE7); // Light yellow
  final Color _textColor = Color(0xFF5D4037); // Dark brown

  PostingModel? posting;
  List<DateTime> bookedDates = [];
  List<DateTime> selectedDates = [];
  List<CalenderUi> calendarWidgets = [];
  double bookingPrice = 0.0;
  String paymentResult = "";
  bool isLoading = false;
  bool showTestButton = true; // Set to false in production

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    _loadBookedDates();
    _testTwilioOnInit();
  }

  Future<void> _testTwilioOnInit() async {
    debugPrint('🔧 Testing Twilio configuration on init...');
    final isConnected = await TwilioService.testTwilioConnection();
    if (isConnected) {
      debugPrint('✅ Twilio connection test passed');
    } else {
      debugPrint('❌ Twilio connection test failed - check credentials');
    }
  }

  void _buildCalendarWidgets() {
    calendarWidgets = List.generate(12, (index) => CalenderUi(
      monthIndex: index,
      bookedDates: bookedDates,
      selectDate: _selectDate,
      onBookedDateTap: _onBookedDateTap,
      getSelectedDates: _getSelectedDates,
    ));
    setState(() {});
  }

  Future<void> _onBookedDateTap(DateTime date) async {
    try {
      await posting!.getAllBookingFromFirestore();

      final matching = posting!.bookings
              ?.where((b) => b.dates != null && b.dates!.any((d) => d.year == date.year && d.month == date.month && d.day == date.day))
              .toList() ?? [];

      if (matching.isEmpty) {
        Get.snackbar('No bookings', 'No booking found for ${date.day}/${date.month}/${date.year}');
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: _primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Bookings on ${date.day}/${date.month}/${date.year}', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...matching.map((b) {
                  final user = b.user;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ListTile(
                      leading: user?.displayImage != null 
                          ? CircleAvatar(backgroundImage: user!.displayImage) 
                          : CircleAvatar(
                              backgroundColor: _primaryColor.withOpacity(0.1),
                              child: Icon(Icons.person, color: _primaryColor),
                            ),
                      title: Text(
                        user?.getFullNameofUser() ?? 'Unknown',
                        style: TextStyle(fontWeight: FontWeight.w600, color: _textColor),
                      ),
                      subtitle: Text(
                        'Sessions: ${b.dates?.length ?? 0}\nAmount: \$${(b.price ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(color: _textColor.withOpacity(0.7)),
                      ),
                      isThreeLine: true,
                      trailing: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryColor, _secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              ConversationModel conv = ConversationModel();
                              final snap = await FirebaseFirestore.instance.collection('conversations')
                                  .where('userIDs', arrayContains: AppConstants.currentUser.id)
                                  .get();
                              bool exists = false;
                              for (var doc in snap.docs) {
                                List<String> ids = List<String>.from(doc['userIDs'] ?? []);
                                if (ids.contains(user?.id)) {
                                  await conv.getConversationInfoFromFirestore(doc);
                                  exists = true;
                                  break;
                                }
                              }
                              if (!exists) {
                                ContactModel other = ContactModel(id: user?.id);
                                await other.getContactInfoFromFirestore();
                                await conv.addConversationToFirestore(other);
                              }

                              Navigator.of(context).pop();
                              Get.to(ConversationScreen(conversation: conv));
                            } catch (e) {
                              Get.snackbar('Error', 'Failed to open chat: ${e.toString()}');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Chat', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load booking info: ${e.toString()}');
    }
  }

  List<DateTime> _getSelectedDates() => selectedDates;

  void _selectDate(DateTime date) {
    setState(() {
      if (selectedDates.any((d) => _isSameDate(d, date))) {
        selectedDates.removeWhere((d) => _isSameDate(d, date));
      } else {
        selectedDates.add(date);
      }
      selectedDates.sort();
      calculateAmountForOverallStay(); // Recalculate price when dates change
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadBookedDates() async {
    setState(() => isLoading = true);
    try {
      await posting!.getAllBookingFromFirestore();
      bookedDates = posting!.getAllBookedDates();
      _buildCalendarWidgets();
    } catch (e) {
      Get.snackbar("Error", "Failed to load booked dates: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _makeBooking() async {
    if (selectedDates.isEmpty) {
      Get.snackbar("Error", "Please select at least one date");
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final hostId = widget.hostID ?? '';
      final orderID = 'ORD${DateTime.now().millisecondsSinceEpoch}${AppConstants.currentUser.id}';
      
      debugPrint('🎯 Starting booking process...');
      debugPrint('📅 Selected Dates: ${selectedDates.length}');
      debugPrint('💰 Total Price: \$$bookingPrice');
      debugPrint('🆔 Order ID: $orderID');
      debugPrint('👤 Customer: ${AppConstants.currentUser.getFullNameofUser()}');
      
      // Step 1: Send WhatsApp message
      debugPrint('📱 Sending WhatsApp notification...');
      final whatsappSent = await TwilioService.sendWhatsAppMessage(
        serviceName: posting?.name ?? 'Unknown Service',
        orderID: orderID,
        nights: selectedDates.length,
        selectedDates: selectedDates,
        totalAmount: bookingPrice,
        customerName: AppConstants.currentUser.getFullNameofUser(),
      );
      
      if (whatsappSent) {
        debugPrint('✅ WhatsApp message sent successfully');
      } else {
        debugPrint('⚠️ WhatsApp message failed, but continuing with booking');
      }
      
      // Step 2: Create booking in Firebase
      debugPrint('🔥 Creating booking in Firebase...');
      await posting!.makeNewBooking(selectedDates, context, hostId);
      
      // Step 3: Navigate back
      Get.back();
      
      // Step 4: Show success message
      Get.snackbar(
        "🎉 Booking Successful!", 
        "Your order has been confirmed!\nOrder ID: $orderID\nWe've sent a confirmation to your host.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: _primaryColor,
        colorText: Colors.white,
      );
      
      // Step 5: Create conversation with host
      if (hostId.isNotEmpty) {
        debugPrint('💬 Creating conversation with host...');
        Future.microtask(() => _sendOrderMessageToHost(hostId, orderID));
      }
      
    } catch (e) {
      debugPrint('❌ Booking error: $e');
      Get.snackbar(
        "Booking Failed", 
        "There was an error processing your booking. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Test method for WhatsApp without payment
  Future<void> _testWhatsAppDirectly() async {
    if (selectedDates.isEmpty) {
      Get.snackbar("Error", "Please select at least one date first");
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final orderID = 'TEST${DateTime.now().millisecondsSinceEpoch}';
      
      Get.snackbar(
        "Testing WhatsApp", 
        "Sending test message...",
        snackPosition: SnackPosition.BOTTOM,
      );
      
      final success = await TwilioService.sendWhatsAppMessage(
        serviceName: posting?.name ?? 'Test Service',
        orderID: orderID,
        nights: selectedDates.length,
        selectedDates: selectedDates,
        totalAmount: bookingPrice,
        customerName: AppConstants.currentUser.getFullNameofUser(),
      );
      
      if (success) {
        Get.snackbar(
          "✅ Test Successful!", 
          "WhatsApp message sent successfully!",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: _primaryColor,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "❌ Test Failed", 
          "Failed to send WhatsApp message. Check console for details.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Test Error", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendOrderMessageToHost(String hostId, String orderID) async {
    try {
      debugPrint("📨 Starting to send order message to host: $hostId");
      
      ConversationModel conversation = ConversationModel();
      
      final conversationSnapshot = await FirebaseFirestore.instance
          .collection("conversations")
          .where("userIDs", arrayContains: AppConstants.currentUser.id)
          .get();
      
      bool conversationExists = false;
      for (var doc in conversationSnapshot.docs) {
        List<String> userIDs = List<String>.from(doc["userIDs"] ?? []);
        if (userIDs.contains(hostId)) {
          await conversation.getConversationInfoFromFirestore(doc);
          conversationExists = true;
          debugPrint("✅ Found existing conversation: ${conversation.id}");
          break;
        }
      }
      
      if (!conversationExists) {
        debugPrint("📝 Creating new conversation with host...");
        ContactModel hostContact = ContactModel(id: hostId);
        await hostContact.getContactInfoFromFirestore();
        await conversation.addConversationToFirestore(hostContact);
        debugPrint("✅ New conversation created with ID: ${conversation.id}");
      }
      
      if (conversation.id == null || conversation.id!.isEmpty) {
        throw Exception("Conversation ID is null or empty after creation");
      }
      
      final orderMessage = '''✅ New Booking Confirmed! 🎉

Order ID: $orderID
Service: ${posting?.name ?? 'Unknown'}
Dates: ${selectedDates.length} night(s)
Total Amount: \$${bookingPrice.toStringAsFixed(2)}

Thank you for your booking!''';
      
      debugPrint("📤 Sending order message to conversation ${conversation.id}...");
      await conversation.addMessageToFirestore(orderMessage);
      debugPrint("✅ Order message sent successfully!");
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      try {
        final freshDoc = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversation.id)
            .get();
        if (freshDoc.exists) {
          await conversation.getConversationInfoFromFirestore(freshDoc);
          debugPrint("🔄 Conversation refreshed with ID: ${conversation.id}");
        }
      } catch (e) {
        debugPrint("⚠️ Could not refresh conversation: $e");
      }
      
      if (Get.context != null) {
        debugPrint("🔄 Opening ConversationScreen with conversation: ${conversation.id}");
        Get.to(ConversationScreen(conversation: conversation));
      }
      
    } catch (e) {
      debugPrint("❌ Error in _sendOrderMessageToHost: $e");
      if (Get.context != null) {
        ConversationModel fallbackConversation = ConversationModel();
        fallbackConversation.id = "";
        fallbackConversation.otherContact = ContactModel(id: hostId);
        Get.to(ConversationScreen(conversation: fallbackConversation));
      }
    }
  }

  void calculateAmountForOverallStay() {
    if (selectedDates.isEmpty) {
      setState(() => bookingPrice = 0.0);
      return;
    }
    setState(() {
      bookingPrice = selectedDates.length * (posting?.price ?? 0.0);
    });
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
        title: Text(
          "Book Ayurvedic Session",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                  SizedBox(height: 16),
                  Text("Loading Ayurvedic Calendar...", style: TextStyle(color: _textColor)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: _cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.spa, color: _primaryColor, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  posting?.name ?? 'Ayurvedic Therapy',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Select your preferred session dates",
                            style: TextStyle(
                              color: _textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),

                  // Selected Dates Info
                  if (selectedDates.isNotEmpty) ...[
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month, color: _primaryColor, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Selected Dates (${selectedDates.length} sessions)",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              selectedDates.map((date) => "${date.day}/${date.month}/${date.year}").join(", "),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: _textColor),
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Total: \$${bookingPrice.toStringAsFixed(2)}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Weekday headers
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Text("Sun", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                        Text("Mon", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                        Text("Tue", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                        Text("Wed", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                        Text("Thu", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                        Text("Fri", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                        Text("Sat", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),

                  // Calendar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: calendarWidgets.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                            )
                          : PageView.builder(
                              itemCount: calendarWidgets.length,
                              itemBuilder: (context, index) => calendarWidgets[index],
                            ),
                    ),
                  ),
                  
                  SizedBox(height: 16),

                  // Action Buttons
                  Column(
                    children: [
                      // Calculate Price Button
                      if (bookingPrice == 0.0 && selectedDates.isNotEmpty)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryColor, _secondaryColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
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
                            onPressed: calculateAmountForOverallStay,
                            height: 50,
                            child: Text(
                              "Calculate Total Price",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      
                      // Test WhatsApp Button (for development)
                      if (showTestButton && selectedDates.isNotEmpty && bookingPrice > 0) ...[
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: MaterialButton(
                            onPressed: _testWhatsAppDirectly,
                            height: 45,
                            child: Text(
                              "TEST WhatsApp Message",
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                      
                      // Proceed Button
                      if (paymentResult.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryColor, _secondaryColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: MaterialButton(
                            onPressed: () {
                              Get.to(HostHomeScreen());
                              setState(() => paymentResult = "");
                            },
                            height: 50,
                            child: Text(
                              "Proceed to Home",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                      
                      // Payment Buttons
                      if (bookingPrice > 0.0 && paymentResult.isEmpty) ...[
                        SizedBox(height: 8),
                        Platform.isIOS
                            ? ApplePayButton(
                                paymentConfiguration:
                                    PaymentConfiguration.fromJsonString(defaultApplePay),
                                paymentItems: [
                                  PaymentItem(
                                    amount: bookingPrice.toStringAsFixed(2),
                                    label: "Ayurvedic Session Booking",
                                    status: PaymentItemStatus.final_price,
                                  ),
                                ],
                                style: ApplePayButtonStyle.black,
                                width: double.infinity,
                                height: 50,
                                type: ApplePayButtonType.buy,
                                margin: const EdgeInsets.only(top: 8),
                                onPaymentResult: (result) {
                                  setState(() => paymentResult = result.toString());
                                  _makeBooking();
                                },
                                loadingIndicator: Center(
                                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                                ),
                              )
                            : GooglePayButton(
                                paymentConfiguration:
                                    PaymentConfiguration.fromJsonString(defaultGooglePay),
                                paymentItems: [
                                  PaymentItem(
                                    label: "Ayurvedic Session Total",
                                    amount: bookingPrice.toStringAsFixed(2),
                                    status: PaymentItemStatus.final_price,
                                  ),
                                ],
                                type: GooglePayButtonType.pay,
                                margin: const EdgeInsets.only(top: 8),
                                onPaymentResult: (result) {
                                  setState(() => paymentResult = result.toString());
                                  _makeBooking();
                                },
                                loadingIndicator: Center(
                                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                                ),
                              ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}