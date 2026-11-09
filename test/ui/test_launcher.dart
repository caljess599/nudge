import 'package:nudge/contacts/reach_out_launcher.dart';

/// Records Call/Text requests instead of opening other apps.
class RecordingLauncher implements ReachOutLauncher {
  final calls = <String>[];
  final texts = <String>[];
  final bool succeeds;

  RecordingLauncher({this.succeeds = true});

  @override
  Future<bool> call(String number) async {
    if (succeeds) calls.add(number);
    return succeeds;
  }

  @override
  Future<bool> text(String number) async {
    if (succeeds) texts.add(number);
    return succeeds;
  }
}
