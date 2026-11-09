import 'package:nudge/contacts/reach_out_launcher.dart';
import 'package:nudge/core/reach_methods.dart';

/// Records what would be opened instead of opening other apps.
class RecordingLauncher implements ReachOutLauncher {
  final opened = <(ReachMethod, String)>[];

  /// Methods whose app "isn't installed".
  final Set<ReachMethod> unavailable;

  RecordingLauncher({this.unavailable = const {}});

  List<String> get calls => _values(ReachMethod.call);
  List<String> get texts => _values(ReachMethod.text);

  List<String> _values(ReachMethod method) => [
    for (final (m, v) in opened)
      if (m == method) v,
  ];

  @override
  Future<bool> open(ReachMethod method, String value) async {
    if (unavailable.contains(method)) return false;
    opened.add((method, value));
    return true;
  }
}
