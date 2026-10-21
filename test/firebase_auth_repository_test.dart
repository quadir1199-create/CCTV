import 'package:cctv_service/features/auth/data/firebase_auth_repository.dart';
import 'package:cctv_service/features/auth/domain/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingAuth extends Fake implements FirebaseAuth {
  String code = 'invalid-credential';
  String? receivedEmail, receivedPassword;
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    receivedEmail = email;
    receivedPassword = password;
    throw FirebaseAuthException(code: code, message: 'private server details');
  }

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    throw FirebaseAuthException(code: 'web-context-cancelled');
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    throw FirebaseAuthException(code: code);
  }
}

void main() {
  test(
    'email login trims email, preserves password and maps native errors',
    () async {
      final auth = FailingAuth();
      await expectLater(
        FirebaseAuthRepository(
          auth,
        ).signInWithEmail(' sam@example.com ', ' password '),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'The email or password is incorrect.',
          ),
        ),
      );
      expect(auth.receivedEmail, 'sam@example.com');
      expect(auth.receivedPassword, ' password ');
    },
  );
  test(
    'Apple cancellation is not reported as an authentication failure',
    () async {
      await expectLater(
        FirebaseAuthRepository(FailingAuth()).signInWithApple(),
        throwsA(isA<AuthCancelled>()),
      );
    },
  );
  test('password reset does not reveal nonexistent accounts', () async {
    await FirebaseAuthRepository(
      FailingAuth()..code = 'user-not-found',
    ).resetPassword('missing@example.com');
  });
}
