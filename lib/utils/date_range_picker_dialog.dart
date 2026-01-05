import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange initialDateRange;

  const CustomDateRangePickerDialog(
      {super.key, required this.initialDateRange});

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();

  static Future<DateTimeRange?> show(
      BuildContext context, DateTimeRange initialDateRange) {
    return showDialog<DateTimeRange>(
      context: context,
      builder: (context) =>
          CustomDateRangePickerDialog(initialDateRange: initialDateRange),
    );
  }
}

class _CustomDateRangePickerDialogState
    extends State<CustomDateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _focusedDay = DateTime.now();
  bool _isSingleDayMode = true;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange.start;
    _endDate = widget.initialDateRange.end;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            AppBar(
              title: const Text('날짜 선택'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              actions: [
                Switch(
                  value: !_isSingleDayMode,
                  onChanged: (value) {
                    setState(() {
                      _isSingleDayMode = !value;
                      // 모드 변경 시 선택 리셋
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  activeColor: Colors.purple,
                  activeTrackColor: Colors.purple.withOpacity(0.5),
                ),
              ],
            ),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_startDate, day) || isSameDay(_endDate, day);
                },
                rangeStartDay: _startDate,
                rangeEndDay: _endDate,
                rangeSelectionMode: _isSingleDayMode
                    ? RangeSelectionMode.disabled
                    : RangeSelectionMode.enforced,
                onDaySelected: _isSingleDayMode
                    ? (selectedDay, focusedDay) {
                        setState(() {
                          // 날짜만 사용해서 시간대 문제 방지
                          final dateOnly = DateTime(selectedDay.year,
                              selectedDay.month, selectedDay.day);
                          _startDate = dateOnly;
                          _endDate = dateOnly
                              .add(const Duration(days: 1))
                              .subtract(const Duration(milliseconds: 1));
                          _focusedDay = focusedDay;
                        });
                      }
                    : null,
                onRangeSelected: !_isSingleDayMode
                    ? (start, end, focusedDay) {
                        setState(() {
                          // 날짜만 사용해서 시간대 문제 방지
                          _startDate = start != null
                              ? DateTime(start.year, start.month, start.day)
                              : null;
                          _endDate = end != null
                              ? DateTime(end.year, end.month, end.day)
                                  .add(const Duration(days: 1))
                                  .subtract(const Duration(milliseconds: 1))
                              : null;
                          _focusedDay = focusedDay ?? DateTime.now();
                        });
                      }
                    : null,
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  rangeHighlightColor: Colors.blue,
                  rangeStartDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    if (_startDate != null && _endDate != null) {
                      Navigator.of(context).pop(DateTimeRange(
                        start: _startDate!,
                        end: _endDate!,
                      ));
                    }
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
