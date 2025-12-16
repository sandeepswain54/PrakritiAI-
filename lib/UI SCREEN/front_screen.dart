import 'package:flutter/material.dart';

class FrontScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar since navbar/main.dart is handled elsewhere
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top user and icons row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Namaste Guest", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Row(
                          children: [
                            Text("Puri 752050", style: TextStyle(fontSize: 15)),
                            Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.notifications_none, size: 28),
                    SizedBox(width: 16),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 28),
                        Positioned(
                          top: -6, right: -10,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("₹40", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.account_circle, size: 28),
                  ],
                ),
              ),
              // Search bar and cart icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Icon(Icons.search, color: Colors.grey[600]),
                            SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.shopping_cart_outlined, size: 28),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Horizontal tab bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTabItem("24|7 Health", true),
                    _buildTabItem("Skin Care", false),
                    _buildTabItem("Winter Care", false),
                    _buildTabItem("Daily Needs", false),
                    _buildTabItem("Baby Care", false),
                  ],
                ),
              ),
              SizedBox(height: 8),
              // Top four features section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _featureCard("Reusable Products", "SINCE 1987", "assets/pad.png"),
                    _featureCard("Lab Test\nAt Home", "60% OFF", "assets/pad.png"),
                    _featureCard("Doctor Booking", "PRE BOOK", "assets/pad.png"),
                    _featureCard("Health Insurance", "0% GST", "assets/pad.png"),
                  ],
                ),
              ),
              // Offer banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Extra 15% OFF*", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("(Avail on Payment Page via IDBI Credit Card) *T&C", style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/pad.png',
                        height: 36,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 36,
                          width: 36,
                          color: Colors.grey[200],
                          child: Icon(Icons.image_not_supported, size: 20, color: Colors.grey[600]),
                        ),
                      ), // Replace with IDBI BANK logo
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Dots indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(true),
                    _dot(false),
                    _dot(false),
                    _dot(false),
                    _dot(false),
                    _dot(false),
                    _dot(false),
                  ],
                ),
              ),
              // Grid section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  runSpacing: 10,
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _bottomFeature("Circle Benefits", "FREE DR.", "assets/pad.png"),
                    _bottomFeature("Health Records", "", "assets/pad.png"),
                    _bottomFeature("Health Assistant", "ASK APOLLO", "assets/pad.png"),
                    _bottomFeature("Apollo SELECT", "SAVE 25%", "assets/pad.png"),
                    _bottomFeature("Apollo Essentials", "", "assets/pad.png"),
                    _bottomFeature("On-Time Consult", "", "assets/pad.png"),
                    _bottomFeature("Visit Hospital", "", "assets/pad.png"),
                    _bottomFeature("View All", "Brand of the Day", "assets/pad.png"),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 17,
                  color: selected ? Colors.black : Colors.grey)),
          if (selected)
            Container(
              margin: EdgeInsets.only(top: 3),
              height: 4,
              width: 32,
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(2)),
            ),
        ],
      ),
    );
  }

  Widget _featureCard(String title, String sub, String image) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Image.asset(
              image,
              height: 50,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 50,
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, size: 28, color: Colors.grey[600]),
              ),
            ), // replace image here
            SizedBox(height: 5),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool selected) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2),
      height: 9,
      width: selected ? 20 : 9,
      decoration: BoxDecoration(
        color: selected ? Colors.teal[300] : Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _bottomFeature(String title, String subtitle, String image) {
    return Container(
      width: 95,
      margin: EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
              Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                image,
                height: 44,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 44,
                  width: 44,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported, size: 20, color: Colors.grey[600]),
                ),
              ),
              if (subtitle == "Brand of the Day")
                Positioned(
                  right: -12, bottom: -13,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(subtitle, style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (subtitle.isNotEmpty && subtitle != "Brand of the Day")
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
