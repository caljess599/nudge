import 'package:flutter/material.dart';

import '../app.dart';
import '../contacts/contacts_source.dart';
import '../core/models.dart';
import '../core/reach_methods.dart';
import 'reach_out.dart';

/// Choose how to reach [member]: no preference, a phone-based method with
/// a specific number (or their mobile by default), a Signal username link
/// or Telegram username, or a custom link.
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

  /// Signal/Telegram: reach them by username instead of phone number,
  /// e.g. when they hide their number.
  late bool _byUsername = _savedUsername != null;

  /// Chosen number; null means "mobile (or first) number".
  late String? _number =
      widget.member.reachVia?.usesPhoneNumber == true && _savedUsername == null
      ? widget.member.reachValue
      : null;

  late final _username = TextEditingController(text: _savedUsername ?? '');
  String? _usernameError;

  String? get _savedUsername {
    final method = widget.member.reachVia;
    final value = widget.member.reachValue;
    if (method == null || value == null) return null;
    return isUsernameValue(method, value) ? value : null;
  }

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
    _username.dispose();
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
    } else if (method != null && method.supportsUsername && _byUsername) {
      value = switch (method) {
        ReachMethod.signal => parseSignalUsernameLink(
          _username.text,
        )?.toString(),
        _ => parseTelegramUsername(_username.text),
      };
      if (value == null) {
        setState(
          () => _usernameError = method == ReachMethod.signal
              ? 'Paste the link they shared, starting with https://signal.me/'
              : 'Enter a username like @name',
        );
        return;
      }
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
          _usernameError = null;
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
            if (method != null && method.supportsUsername)
              _numberOrUsername(method),
            if (method != null && method.supportsUsername && _byUsername)
              _usernameField(method)
            else if (method != null && method.usesPhoneNumber)
              ..._numberChoice(),
            if (method == ReachMethod.link) _linkField(),
            if (method != null && method.isMessagingApp)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Text(
                  '${method.label} opens only if it\'s installed. Nudge '
                  'never opens it in a browser, so the '
                  '${_byUsername && method.supportsUsername ? 'username' : 'number'} '
                  'isn\'t sent to any website.',
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

  Widget _numberOrUsername(ReachMethod method) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.phone_outlined),
          label: Text('Phone number'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.alternate_email),
          label: Text('Username'),
        ),
      ],
      selected: {_byUsername},
      onSelectionChanged: (s) => setState(() {
        _byUsername = s.single;
        _usernameError = null;
      }),
    ),
  );

  Widget _usernameField(ReachMethod method) {
    final signal = method == ReachMethod.signal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _username,
        keyboardType: signal ? TextInputType.url : TextInputType.text,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: signal ? 'Signal username link' : 'Telegram username',
          hintText: signal ? 'https://signal.me/#…' : '@name',
          helperText: signal
              ? 'For people who hide their number on Signal. Ask them to '
                    'share their username link from their Signal profile, '
                    'then paste it here.'
              : 'Their @username, or a t.me/ link.',
          helperMaxLines: 3,
          errorText: _usernameError,
          errorMaxLines: 2,
        ),
        onChanged: (_) {
          if (_usernameError != null) setState(() => _usernameError = null);
        },
      ),
    );
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
