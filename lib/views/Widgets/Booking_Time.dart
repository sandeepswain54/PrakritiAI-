import 'package:flutter/material.dart';
import 'package:service_app/model/app_constant.dart';

class CalenderUi extends StatefulWidget {
  final int? monthIndex;
  final List<DateTime>? bookedDates;
  final Function(DateTime)? selectDate;
  final Function(DateTime)? onBookedDateTap;
  final List<DateTime> Function()? getSelectedDates;

  const CalenderUi({
    super.key, 
    this.getSelectedDates,
    this.selectDate,
    this.onBookedDateTap,
    this.monthIndex,
    this.bookedDates
  });

  @override
  State<CalenderUi> createState() => _CalenderUiState();
}

class _CalenderUiState extends State<CalenderUi> {
  List<DateTime> _selectedDates = [];
  List<MonthTileWidget> _monthTiles = [];
  int? _currentMonthInt;
  int? _currentYearInt;
  late Set<DateTime> _bookedDatesSet;

  @override
  void initState() {
    super.initState();
    
    final now = DateTime.now();
    _currentMonthInt = (now.month + widget.monthIndex! - 1) % 12 + 1;
    _currentYearInt = now.year + ((now.month + widget.monthIndex! - 1) ~/ 12);
    
    // Convert bookedDates to Set for faster lookup
    _bookedDatesSet = Set.from(widget.bookedDates?.map((d) => DateTime(d.year, d.month, d.day)) ?? {});
    
    if (widget.getSelectedDates != null) {
      _selectedDates.addAll(widget.getSelectedDates!());
    }
    
    _setUpMonthTiles();
  }

  bool _isSameDate(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  bool _isDateBooked(DateTime date) {
    return _bookedDatesSet.contains(DateTime(date.year, date.month, date.day));
  }

  void _setUpMonthTiles() {
    _monthTiles = [];
    
    if (_currentMonthInt == null) return;

    int daysInMonth = AppConstants.daysInMonths![_currentMonthInt]!;
    
    // Handle February in leap years
    if (_currentMonthInt == 2 && 
        _currentYearInt! % 4 == 0 && 
        (_currentYearInt! % 100 != 0 || _currentYearInt! % 400 == 0)) {
      daysInMonth = 29;
    }

    DateTime firstDayOfMonth = DateTime(_currentYearInt!, _currentMonthInt!, 1);
    int firstWeekdayOfMonth = firstDayOfMonth.weekday;

    // Add empty tiles for days before the first day of the month
    for (int i = 1; i < firstWeekdayOfMonth; i++) {
      _monthTiles.add(const MonthTileWidget(dateTime: null));
    }

    // Add tiles for each day of the month
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime date = DateTime(_currentYearInt!, _currentMonthInt!, i);
      _monthTiles.add(MonthTileWidget(dateTime: date));
    }
  }

  void _selectDate(DateTime date) {
    if (_isDateBooked(date)) return;
    
    setState(() {
      if (_selectedDates.any((d) => _isSameDate(d, date))) {
        _selectedDates.removeWhere((d) => _isSameDate(d, date));
      } else {
        _selectedDates.add(date);
      }
      widget.selectDate?.call(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            "${AppConstants.monthDict[_currentMonthInt]} $_currentYearInt",
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          itemCount: _monthTiles.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final monthTile = _monthTiles[index];
            
            if (monthTile.dateTime == null) {
              return const SizedBox.shrink();
            }

            final isBooked = _isDateBooked(monthTile.dateTime!);
            final isSelected = _selectedDates.any((d) => _isSameDate(d, monthTile.dateTime));

            return GestureDetector(
              onTap: isBooked ? () => widget.onBookedDateTap?.call(monthTile.dateTime!) : () => _selectDate(monthTile.dateTime!),
              child: Container(
                decoration: BoxDecoration(
                  color: isBooked
                      ? Colors.amber[300]
                      : isSelected
                          ? Colors.blue[400]
                          : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: isBooked
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  monthTile.dateTime!.day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isBooked 
                        ? Colors.black 
                        : isSelected
                            ? Colors.white
                            : Colors.black87,
                    fontWeight: isBooked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class MonthTileWidget extends StatelessWidget {
  final DateTime? dateTime;

  const MonthTileWidget({super.key, this.dateTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        dateTime?.day.toString() ?? "",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}