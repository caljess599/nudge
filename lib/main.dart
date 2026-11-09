import 'package:flutter/material.dart';

import 'app.dart';
import 'core/clock.dart';
import 'data/open_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NudgeApp(db: openAppDatabase(), clock: const SystemClock()));
}
