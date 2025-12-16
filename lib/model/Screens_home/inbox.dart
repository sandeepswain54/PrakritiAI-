import 'package:flutter/material.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/Widgets/Booking_Time.dart';

import 'package:service_app/views/Widgets/posting_listing_tile_ui.dart';

class Inbox extends StatefulWidget {
  const Inbox({super.key});

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  List<DateTime> _bookedDates = [];
  List<DateTime> _allBookedDates = [];
  PostingModel? _selectedPosting;

  List<DateTime> _getSelectedDates() {
    return [];
  }

  void _selectDate(DateTime data) {
    // You can implement date-specific logic here
  }

  void _selectAPosting(PostingModel posting) {
    _selectedPosting = posting;
    _bookedDates = posting.getAllBookedDates();

    setState(() {});
  }

  void _clearSelectedPosting() {
    setState(() {
      _bookedDates = _allBookedDates;
      _selectedPosting = null;
    });
  }

  @override
  void initState() {
    super.initState();

    _bookedDates = AppConstants.currentUser.getAllBookedDates();
    _allBookedDates = AppConstants.currentUser.getAllBookedDates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text("Sun"),
                  Text("Mon"),
                  Text("Tue"),
                  Text("Wed"),
                  Text("Thu"),
                  Text("Fri"),
                  Text("Sat"),
                ],
              ),

              /// Calendar
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 35),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 1.8,
                  child: PageView.builder(
                    itemBuilder: (context, index) {
                      return CalenderUi(
                        monthIndex: index,
                        bookedDates: _bookedDates,
                        selectDate: _selectDate,
                        getSelectedDates: _getSelectedDates,
                      );
                    },
                    itemCount: 12,
                  ),
                ),
              ),

              /// Filter Section
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 25, 0, 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filter by Listing",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    MaterialButton(
                      onPressed: _clearSelectedPosting,
                      child: const Text(
                        "Reset",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              /// Postings List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AppConstants.currentUser.myPostings?.length ?? 0,
                itemBuilder: (context, index) {
                  final posting = AppConstants.currentUser.myPostings![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: InkResponse(
                      onTap: () => _selectAPosting(posting),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedPosting == posting
                                ? Colors.blue
                                : Colors.grey,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: PostingListingTileUi(posting: posting),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
