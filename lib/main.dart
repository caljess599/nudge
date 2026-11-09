import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'contacts/device_contacts_source.dart';
import 'contacts/fake_contacts_source.dart';
import 'contacts/reach_out_launcher.dart';
import 'core/clock.dart';
import 'data/open_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const device = DeviceContactsSource();
  runApp(
    NudgeApp(
      db: openAppDatabase(),
      clock: const SystemClock(),
      // Debug builds add fake contacts so emulators have someone to pick.
      contactsSource: kDebugMode ? const DebugContactsSource(device) : device,
      launcher: const UrlReachOutLauncher(),
    ),
  );
}
