import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'firebase_options.dart';
import 'features/complaints/data/demo_complaint_repository.dart';
import 'features/complaints/presentation/service_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demo = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  if (!demo) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Firebase could not start. Check the Firebase configuration and try again.',
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
  }
  final repository = demo ? DemoComplaintRepository() : null;
  runApp(
    ProviderScope(
      overrides: [
        demoModeProvider.overrideWithValue(demo),
        if (repository != null)
          complaintRepositoryProvider.overrideWithValue(repository),
      ],
      child: const ServiceApp(),
    ),
  );
}
