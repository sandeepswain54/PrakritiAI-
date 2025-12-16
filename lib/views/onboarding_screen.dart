import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/views/login.dart';

class OnboardingScreenPage extends StatefulWidget {
  const OnboardingScreenPage({super.key});

  @override
  State<OnboardingScreenPage> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreenPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> pages = [
    {
      'image': 'assets/io.png',
      'title': '🌸 Women',
      'description': 'Sustainable choices, better periods',
      'color': Colors.white,
    },
    {
      'image': 'assets/io7.png',
      'title': '🏥 Pharmacy',
      'description': 'Smart stocking. Faster sales.',
      'color': Colors.white,
    },
    {
      'image': 'assets/io2.png',
      'title': '🚚 Distributor',
      'description': 'Bulk orders made simple',
      'color': Colors.white,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (_, index) => _buildPage(pages[index]),
          ),
          _buildIndicator(),
          _buildNavigationButton(),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Container(
      color: page['color'],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(page['image'], height:MediaQuery.of(context).size.height*0.5,),
          const SizedBox(height: 40),
          Text(
            page['title'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              page['description'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.pink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pages.map((page) {
          int index = pages.indexOf(page);
          return Container(
            width: _currentPage == index ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.white : Colors.white54,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationButton() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: () {
          if (_currentPage < pages.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          } else {
            Get.offAll(() => const Login());
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
          style: TextStyle(
            fontSize: 18,
            color: pages[_currentPage]['color'],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}