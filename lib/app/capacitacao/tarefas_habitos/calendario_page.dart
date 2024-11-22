import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({
    super.key,
  });

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  int? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      showDatePickerButton: true,
      timeSlotViewSettings: const TimeSlotViewSettings(
        minimumAppointmentDuration: Duration(minutes: 30),
        timeFormat: 'HH:mm',
      ),
      allowedViews: const [
        CalendarView.day,
        CalendarView.week,
        CalendarView.month,
        CalendarView.timelineDay,
        CalendarView.timelineWeek,
        CalendarView.timelineWorkWeek,
        CalendarView.schedule,
      ],
      appointmentTimeTextFormat: 'HH:mm',
    );
  }
}
