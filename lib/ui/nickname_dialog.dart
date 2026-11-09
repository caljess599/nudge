import 'package:flutter/material.dart';

import '../core/models.dart';

/// Edit the Nudge-only name for [member]. Returns the new nickname (empty
/// means "use the contact name"), or null if cancelled.
Future<String?> showNicknameDialog(BuildContext context, Member member) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NicknameDialog(member: member),
    );

class _NicknameDialog extends StatefulWidget {
  final Member member;

  const _NicknameDialog({required this.member});

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final _controller = TextEditingController(
    text: widget.member.nickname ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nickname'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          hintText: widget.member.cachedName,
          helperText:
              'Shown only in Nudge. Leave empty to use '
              '"${widget.member.cachedName}" from your contacts.',
          helperMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
