import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cctv_service/core/providers.dart';
import 'package:cctv_service/features/auth/domain/auth_repository.dart';
import 'package:cctv_service/features/auth/domain/customer_profile.dart';
import 'package:cctv_service/features/complaints/data/demo_complaint_repository.dart';
import 'package:cctv_service/features/complaints/presentation/service_app.dart';

class TestAuth implements AuthRepository {
  final changes = StreamController<AppUser?>.broadcast();
  final authentication = Completer<void>();
  AppUser? user;
  bool cancelSocial = false;
  String? resetEmail;
  @override
  Stream<AppUser?> watchUser() async* {
    yield user;
    yield* changes.stream;
  }

  Future<AppUser> authenticate() async {
    if (cancelSocial) throw const AuthCancelled();
    user = const AppUser(
      'test-user',
      email: 'sam@example.com',
      displayName: 'Sam Customer',
    );
    changes.add(user);
    await authentication.future;
    return user!;
  }

  @override
  Future<AppUser> signUpWithEmail(String name, String email, String password) =>
      authenticate();
  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      authenticate();
  @override
  Future<AppUser> signInWithGoogle() => authenticate();
  @override
  Future<AppUser> signInWithApple() => authenticate();
  @override
  Future<void> resetPassword(String email) async {
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {}
}

class TestProfiles implements CustomerProfileRepository {
  final saving = Completer<void>();
  CustomerProfile? profile;
  @override
  Future<CustomerProfile?> get(String id) async => profile;
  @override
  Future<void> save(CustomerProfile value) async {
    await saving.future;
    profile = value;
  }
}

void main() {
  Future<void> setup(
    WidgetTester tester,
    TestAuth auth,
    TestProfiles profiles,
  ) async {
    final complaints = DemoComplaintRepository();
    addTearDown(auth.changes.close);
    addTearDown(complaints.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          customerProfileRepositoryProvider.overrideWithValue(profiles),
          complaintRepositoryProvider.overrideWithValue(complaints),
        ],
        child: const ServiceApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final method in ['email', 'Google', 'Apple']) {
    testWidgets(
      '$method signup survives early auth event until profile is saved',
      (tester) async {
        final auth = TestAuth();
        final profiles = TestProfiles();
        await setup(tester, auth, profiles);
        if (method == 'email') {
          await tester.ensureVisible(
            find.text('New customer? Create an account'),
          );
          await tester.tap(find.text('New customer? Create an account'));
          await tester.pumpAndSettle();
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Sam Customer');
          await tester.enterText(fields.at(1), 'sam@example.com');
          await tester.enterText(fields.at(2), 'Test-password-123');
          await tester.enterText(fields.at(3), 'Test-password-123');
          await tester.ensureVisible(find.text('Create account'));
          await tester.tap(find.text('Create account'));
        } else {
          await tester.ensureVisible(find.text('Continue with $method'));
          await tester.tap(find.text('Continue with $method'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Please wait…'), findsOneWidget);
        expect(find.text('Complete your profile'), findsNothing);
        auth.authentication.complete();
        await tester.pumpAndSettle();
        expect(find.text('Please wait…'), findsOneWidget);
        profiles.saving.complete();
        await tester.pumpAndSettle();
        expect(profiles.profile?.email, 'sam@example.com');
        expect(find.text('Hello, Sam'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('password reset requires only email and shows a neutral response', (
    tester,
  ) async {
    final auth = TestAuth();
    final profiles = TestProfiles();
    await setup(tester, auth, profiles);
    await tester.enterText(find.byType(TextFormField).first, 'sam@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, 'sam@example.com');
    expect(
      find.text(
        'If an account exists for this email, a password reset link has been sent.',
      ),
      findsOneWidget,
    );
  });
  testWidgets('cancelling social login leaves the form usable', (tester) async {
    final auth = TestAuth()..cancelSocial = true;
    final profiles = TestProfiles();
    await setup(tester, auth, profiles);
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Please wait…'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
