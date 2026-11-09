import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'formatting.dart';

/// Longest period the form accepts (10 years).
const maxPeriodDays = 3650;

const _presets = [7, 14, 30];

class RingFormResult {
  final String name;
  final int periodDays;

  const RingFormResult(this.name, this.periodDays);
}

/// Create or edit a ring. Returns null if cancelled.
Future<RingFormResult?> showRingForm(
  BuildContext context, {
  String? initialName,
  int? initialPeriodDays,
}) => showDialog<RingFormResult>(
  context: context,
  builder: (_) => _RingFormDialog(
    initialName: initialName,
    initialPeriodDays: initialPeriodDays,
  ),
);

class _RingFormDialog extends StatefulWidget {
  final String? initialName;
  final int? initialPeriodDays;

  const _RingFormDialog({this.initialName, this.initialPeriodDays});

  @override
  State<_RingFormDialog> createState() => _RingFormDialogState();
}

class _RingFormDialogState extends State<_RingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _customDays;

  /// A preset value, or null for custom.
  int? _preset;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPeriodDays ?? 14;
    _name = TextEditingController(text: widget.initialName ?? '');
    _preset = _presets.contains(initial) ? initial : null;
    _customDays = TextEditingController(
      text: _preset == null ? '$initial' : '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _customDays.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final days = _preset ?? int.parse(_customDays.text);
    Navigator.of(context).pop(RingFormResult(_name.text.trim(), days));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit ring' : 'New ring'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Close friends',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              Text('How often?', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final days in _presets)
                    ChoiceChip(
                      label: Text(periodLabel(days)),
                      selected: _preset == days,
                      onSelected: (_) => setState(() => _preset = days),
                    ),
                  ChoiceChip(
                    label: const Text('Custom'),
                    selected: _preset == null,
                    onSelected: (_) => setState(() {
                      // Start from the preset that was selected, if any.
                      if (_customDays.text.isEmpty && _preset != null) {
                        _customDays.text = '$_preset';
                      }
                      _preset = null;
                    }),
                  ),
                ],
              ),
              if (_preset == null)
                TextFormField(
                  controller: _customDays,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Every how many days?',
                    suffixText: 'days',
                  ),
                  validator: (v) {
                    final days = int.tryParse(v ?? '');
                    if (days == null || days < 1) {
                      return 'Enter a number of days';
                    }
                    if (days > maxPeriodDays) {
                      return 'At most $maxPeriodDays days';
                    }
                    return null;
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
