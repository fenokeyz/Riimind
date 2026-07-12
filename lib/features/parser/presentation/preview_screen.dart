import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/parsed_event.dart';
import 'widgets/preview_field_card.dart';

/// Read-only review of the event extracted by Gemini.
///
/// Layout, top to bottom:
/// - AppBar with back button
/// - Warning card (only when date or time is empty)
/// - Hero card with the event title
/// - Date, Time, Location, Description cards (in that order)
/// - Sticky bottom bar with **Edit message** and **Continue**
///
/// "Continue" opens the native calendar editor so the user can review and
/// save the event outside Riimind.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({required this.event, super.key});

  final ParsedEvent? event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = event;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: e == null
          ? const _MissingEvent()
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (e.date.isEmpty || e.time.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: PreviewMissingInfoCard(),
                            ),
                          _TitleCard(title: e.title, theme: theme),
                          const SizedBox(height: 16),
                          PreviewFieldCard(
                            field: PreviewField(
                              icon: Icons.calendar_today_rounded,
                              label: 'Date',
                              value: e.date,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PreviewFieldCard(
                            field: PreviewField(
                              icon: Icons.schedule_rounded,
                              label: 'Time',
                              value: e.time,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PreviewFieldCard(
                            field: PreviewField(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: e.location,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PreviewFieldCard(
                            field: PreviewField(
                              icon: Icons.notes_rounded,
                              label: 'Description',
                              value: e.description,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BottomBar(
                    onEdit: () => context.pop(),
                    onContinue: () => _onContinue(context, e),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _onContinue(BuildContext context, ParsedEvent event) async {
    try {
      final opened = await Add2Calendar.addEvent2Cal(_toCalendarEvent(event));
      if (!opened) {
        throw StateError("Couldn't open the calendar event editor.");
      }
    } catch (error) {
      if (context.mounted) _showCalendarErrorDialog(context, error);
    }
  }

  Event _toCalendarEvent(ParsedEvent event) {
    final date = _parseDate(event.date);

    if (event.time.trim().isEmpty) {
      return Event(
        title: event.title.isEmpty ? 'Untitled event' : event.title,
        description: event.description,
        location: event.location,
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
        allDay: true,
      );
    }

    final time = _parseTime(event.time);
    final start = DateTime(date.year, date.month, date.day, time.$1, time.$2);
    return Event(
      title: event.title.isEmpty ? 'Untitled event' : event.title,
      description: event.description,
      location: event.location,
      startDate: start,
      endDate: start.add(const Duration(hours: 1)),
    );
  }

  DateTime _parseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const FormatException(
        'A valid date is needed before this event can be added to Calendar.',
      );
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw const FormatException(
        'A valid date is needed before this event can be added to Calendar.',
      );
    }
    return date;
  }

  (int, int) _parseTime(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) {
      throw const FormatException(
        'The event time must use the HH:mm format before it can be added to Calendar.',
      );
    }
    return (int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  void _showCalendarErrorDialog(BuildContext context, Object error) {
    final message = error is FormatException
        ? error.message
        : kDebugMode
        ? error.toString()
        : 'Please try again.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Couldn't open Calendar"),
        content: Text(
          'Riimind couldn\'t prepare this event for your calendar. $message',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final hasTitle = title.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasTitle ? title : PreviewField.notDetected,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: hasTitle
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onEdit, required this.onContinue});

  final VoidCallback onEdit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edit message'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingEvent extends StatelessWidget {
  const _MissingEvent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No event to preview.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
