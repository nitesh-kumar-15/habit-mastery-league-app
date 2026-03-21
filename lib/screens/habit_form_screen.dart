import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/habit_repository.dart';
import '../utils/app_dates.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habitId});

  final int? habitId;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  String _category = 'General';
  String _frequency = 'daily';
  DateTime _startDate = DateTime.now();

  static const _categories = ['Study', 'Health', 'Productivity', 'Finance', 'General'];
  static const _frequencies = [
    ('daily', 'Daily'),
    ('weekdays', 'Weekdays only'),
    ('weekly', 'Weekly focus'),
  ];

  String? _titleError;

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final repo = context.read<HabitRepository>();
    final h = await repo.getHabit(widget.habitId!);
    if (h != null && mounted) {
      setState(() {
        _title.text = h.title;
        _description.text = h.description;
        _category = h.category;
        _frequency = h.frequency;
        _startDate = AppDates.parseDate(h.startDate);
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _titleError = null);
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }
    // compare only calendar dates to avoid time drift.
    final today = DateTime.now();
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(today.year, today.month, today.day);
    if (start.isAfter(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date cannot be in the future.')),
      );
      return;
    }

    final repo = context.read<HabitRepository>();
    final startStr = AppDates.formatDate(_startDate);
    try {
      if (widget.habitId == null) {
        await repo.insertHabit(
          title: title,
          description: _description.text,
          category: _category,
          frequency: _frequency,
          startDate: startStr,
        );
      } else {
        final existing = await repo.getHabit(widget.habitId!);
        if (existing == null) return;
        await repo.updateHabit(
          existing.copyWith(
            title: title,
            description: _description.text,
            category: _category,
            frequency: _frequency,
            startDate: startStr,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save. Please try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _save(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.habitId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit habit' : 'New habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _titleError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _category,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'General'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _frequency,
                  items: _frequencies
                      .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                      .toList(),
                  onChanged: (v) => setState(() => _frequency = v ?? 'daily'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(DateFormat.yMMMd().format(_startDate)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(editing ? 'Save changes' : 'Create habit'),
            ),
          ],
        ),
      ),
    );
  }
}
