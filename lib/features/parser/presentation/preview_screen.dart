import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/parsed_event.dart';

/// Lets the user review and correct an extracted event before opening the
/// platform calendar editor.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({required this.event, super.key});

  final ParsedEvent? event;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  DateTime? _date;
  TimeOfDay? _time;
  bool _isOpeningCalendar = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _date = _tryParseDate(event?.date ?? '');
    _time = _tryParseTime(event?.time ?? '');
    _titleController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_onFormChanged)
      ..dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  bool get _canContinue =>
      !_isOpeningCalendar &&
      _titleController.text.trim().isNotEmpty &&
      _date != null;

  @override
  Widget build(BuildContext context) {
    if (widget.event == null) return const _MissingEvent();

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review event'),
        leading: IconButton(
          tooltip: 'Back to message',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(theme: theme),
                    const SizedBox(height: 20),
                    _FormSection(
                      title: 'Event details',
                      children: [
                        TextField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.event_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PickerField(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: _date == null
                              ? 'Choose a date'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(_date!),
                          isPlaceholder: _date == null,
                          onTap: _pickDate,
                          onClear: _date == null
                              ? null
                              : () => setState(() => _date = null),
                        ),
                        const SizedBox(height: 12),
                        _PickerField(
                          icon: _time == null
                              ? Icons.today_outlined
                              : Icons.schedule_rounded,
                          label: 'Time',
                          value: _time == null
                              ? 'All-day event'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatTimeOfDay(_time!),
                          isPlaceholder: false,
                          onTap: _pickTime,
                          onClear: _time == null
                              ? null
                              : () => setState(() => _time = null),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _locationController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          minLines: 3,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],
                    ),
                    if (_date == null) ...[
                      const SizedBox(height: 16),
                      _InfoCard(
                        icon: Icons.info_outline_rounded,
                        message:
                            'Choose a date before continuing. Leave time empty for an all-day event.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _BottomBar(
              isLoading: _isOpeningCalendar,
              canContinue: _canContinue,
              onEditMessage: () => context.pop(),
              onContinue: _openCalendar,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _openCalendar() async {
    if (!_canContinue || _date == null) return;
    setState(() => _isOpeningCalendar = true);

    try {
      final opened = await Add2Calendar.addEvent2Cal(_toCalendarEvent());
      if (!opened) {
        throw const _CalendarOpenException(
          'Calendar access was denied or no calendar app is available.',
        );
      }
      if (mounted) await _showCalendarOpenedDialog();
    } on _CalendarOpenException catch (error) {
      if (mounted) _showFailureDialog(error.message);
    } catch (_) {
      if (mounted) {
        _showFailureDialog('Please check calendar access and try again.');
      }
    } finally {
      if (mounted) setState(() => _isOpeningCalendar = false);
    }
  }

  Event _toCalendarEvent() {
    final date = _date!;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (_time == null) {
      return Event(
        title: title,
        description: description,
        location: location,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(
          date.year,
          date.month,
          date.day,
        ).add(const Duration(days: 1)),
        allDay: true,
      );
    }

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      _time!.hour,
      _time!.minute,
    );
    return Event(
      title: title,
      description: description,
      location: location,
      startDate: start,
      endDate: start.add(const Duration(hours: 1)),
    );
  }

  Future<void> _showCalendarOpenedDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.calendar_month_rounded),
        title: const Text('Calendar opened'),
        content: const Text(
          'Review the event in your calendar and tap Save to finish adding it.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded),
        title: const Text("Couldn't open Calendar"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  DateTime? _tryParseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final date = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    return date.year.toString().padLeft(4, '0') == match.group(1) &&
            date.month.toString().padLeft(2, '0') == match.group(2) &&
            date.day.toString().padLeft(2, '0') == match.group(3)
        ? date
        : null;
  }

  TimeOfDay? _tryParseTime(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_calendar_rounded,
            color: colors.onPrimaryContainer,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check the details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Make any changes before opening Calendar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      ...children,
    ],
  );
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(icon, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isPlaceholder
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear $label',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isLoading,
    required this.canContinue,
    required this.onEditMessage,
    required this.onContinue,
  });

  final bool isLoading;
  final bool canContinue;
  final VoidCallback onEditMessage;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onEditMessage,
              child: const Text('Edit message'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: canContinue ? onContinue : null,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calendar_month_rounded),
              label: Text(isLoading ? 'Opening…' : 'Continue'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissingEvent extends StatelessWidget {
  const _MissingEvent();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review event')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No event to review.'),
      ),
    ),
  );
}

class _CalendarOpenException implements Exception {
  const _CalendarOpenException(this.message);
  final String message;
}
