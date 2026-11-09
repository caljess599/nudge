import 'package:flutter/material.dart';

import '../app.dart';
import '../contacts/contacts_source.dart';
import '../core/models.dart';
import '../core/reach_methods.dart';
import 'reach_out.dart';

/// Choose how to reach [member]: no preference, a phone-based method with
/// a specific number (or their mobile by default), or a custom link.
class ReachPreferenceScreen extends StatefulWidget {
  final Member member;
  final PhoneContact? contact;

  const ReachPreferenceScreen({
    super.key,
    required this.member,
    required this.contact,
  });

  @override
  State<ReachPreferenceScreen> createState() => _ReachPreferenceScreenState();
}

class _ReachPreferenceScreenState extends State<ReachPreferenceScreen> {
  late ReachMethod? _method = widget.member.reachVia;

  /// Chosen number; null means "mobile (or first) number".
  late String? _number = widget.member.reachVia?.usesPhoneNumber == true
      ? widget.member.reachValue
      : null;

  late final _link = TextEditingController(
    text: widget.member.reachVia == ReachMethod.link
        ? widget.member.reachValue ?? ''
        : '',
  );
  String? _linkError;

  List<PhoneNumber> get _phones => sortedPhones(widget.contact);

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final method = _method;
    String? value;
    if (method == ReachMethod.link) {
      final uri = parseCustomLink(_link.text);
      if (uri == null) {
        setState(() => _linkError = 'Enter a link, e.g. https://m.me/name');
        return;
      }
      value = uri.toString();
    } else if (method != null) {
      value = _number;
    }
    await AppScope.of(context).db
        .setReachPreference(widget.member.id, method, value: value);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = _method;
    return Scaffold(
      appBar: AppBar(
        title: Text('Reach ${widget.member.displayName} via'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: RadioGroup<ReachMethod?>(
        groupValue: _method,
        onChanged: (m) => setState(() {
          _method = m;
          _linkError = null;
        }),
        child: ListView(
          children: [
            const RadioListTile<ReachMethod?>(
              value: null,
              title: Text('No preference'),
              subtitle: Text('Show Call, Text and the contact card'),
            ),
            for (final m in ReachMethod.values)
              RadioListTile<ReachMethod?>(
                value: m,
                title: Text(m.label),
                secondary: Icon(reachIcon(m)),
              ),
            const Divider(),
            if (method != null && method.usesPhoneNumber) ..._numberChoice(),
            if (method == ReachMethod.link) _linkField(),
            if (method != null && method.isMessagingApp)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Text(
                  '${method.label} opens only if it\'s installed. Nudge '
                  'never opens it in a browser, so the number isn\'t sent '
                  'to any website.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _numberChoice() {
    final phones = _phones;
    final method = _method!;
    if (phones.isEmpty) {
      return [
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('No phone number found for this contact'),
        ),
      ];
    }
    final chosen = _number ?? phones.first.number;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('Number', style: Theme.of(context).textTheme.titleSmall),
      ),
      RadioGroup<String?>(
        groupValue: _number,
        onChanged: (n) => setState(() => _number = n),
        child: Column(
          children: [
            RadioListTile<String?>(
              value: null,
              title: Text(
                phones.first.isMobile ? 'Mobile number' : 'Their number',
              ),
              subtitle: Text(
                '${phones.first.number}. Follows changes in your contacts.',
              ),
            ),
            // With one number, the default already covers it.
            if (phones.length > 1)
              for (final p in phones)
                RadioListTile<String?>(
                  value: p.number,
                  title: Text(p.number),
                  subtitle: p.label.isEmpty ? null : Text(p.label),
                ),
          ],
        ),
      ),
      if (method.needsInternationalNumber && !hasCountryCode(chosen))
        ListTile(
          leading: Icon(
            Icons.warning_amber_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            '${method.label} needs the number with its country code '
            '(starting with +). Add it in your contacts if this doesn\'t '
            'open the right chat.',
          ),
        ),
    ];
  }

  Widget _linkField() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: TextField(
      controller: _link,
      keyboardType: TextInputType.url,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Link',
        hintText: 'https://m.me/name',
        helperText: 'For Messenger, Instagram and other apps',
        errorText: _linkError,
      ),
      onChanged: (_) {
        if (_linkError != null) setState(() => _linkError = null);
      },
    ),
  );
}
