import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cctv_service/core/providers.dart';
import 'package:cctv_service/features/complaints/data/demo_complaint_repository.dart';
import 'package:cctv_service/features/complaints/presentation/service_app.dart';

void main() {
  testWidgets('customer registers complaint and sees it on dashboard', (
    tester,
  ) async {
    final repository = DemoComplaintRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoModeProvider.overrideWithValue(true),
          complaintRepositoryProvider.overrideWithValue(repository),
        ],
        child: const ServiceApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('New customer? Create an account'));
    await tester.tap(find.text('New customer? Create an account'));
    await tester.pumpAndSettle();
    final signupFields = find.byType(TextFormField);
    await tester.enterText(signupFields.at(0), 'Sam Customer');
    await tester.enterText(signupFields.at(1), 'sam@example.com');
    await tester.enterText(signupFields.at(2), 'Test-password-123');
    await tester.enterText(signupFields.at(3), 'Test-password-123');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register complaint'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Dome camera');
    await tester.enterText(fields.at(1), 'SN-1234');
    await tester.enterText(
      fields.at(2),
      'Camera disconnects every five minutes.',
    );
    await tester.enterText(fields.at(3), 'Doha, office entrance');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Submit complaint'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Submit complaint'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Complaint registered. Follow progress in your service requests.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Dome camera'), findsOneWidget);
    await tester.ensureVisible(find.text('Dome camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dome camera'));
    await tester.pumpAndSettle();
    expect(find.text('Current status'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Camera disconnects every five minutes.'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Camera disconnects every five minutes.'), findsOneWidget);
  });
}
