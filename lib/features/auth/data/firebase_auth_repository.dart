import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_repository.dart';

AuthFailure firebaseAuthFailure(
  FirebaseAuthException error,
) => AuthFailure(switch (error.code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'The email or password is incorrect.',
  'invalid-email' => 'Enter a valid email address.',
  'email-already-in-use' =>
    'An account already uses this email. Sign in instead.',
  'weak-password' => 'Choose a stronger password with at least 8 characters.',
  'operation-not-allowed' =>
    'This sign-in method is not enabled yet. Contact support.',
  'account-exists-with-different-credential' =>
    'This email already uses another sign-in method. Sign in with that method first.',
  'user-disabled' => 'This account has been disabled. Contact support.',
  'network-request-failed' => 'Check your internet connection and try again.',
  'too-many-requests' =>
    'Too many attempts. Wait a little before trying again.',
  _ => 'Could not sign in. Please try again.',
});

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth);
  final FirebaseAuth auth;
  Future<void>? _googleInitialization;
  bool _usedGoogle = false;

  AppUser _map(User user) => AppUser(
    user.uid,
    email: user.email ?? '',
    displayName: user.displayName ?? '',
    phone: user.phoneNumber ?? '',
  );

  @override
  Stream<AppUser?> watchUser() =>
      auth.authStateChanges().map((user) => user == null ? null : _map(user));

  Future<AppUser> _authenticate(
    Future<UserCredential> Function() action,
  ) async {
    try {
      final result = await action();
      final user = result.user;
      if (user == null) {
        throw const AuthFailure(
          'Your account is not ready. Try signing in again.',
        );
      }
      return _map(user);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'web-context-cancelled' ||
          error.code == 'popup-closed-by-user' ||
          error.code == 'canceled') {
        throw const AuthCancelled();
      }
      throw firebaseAuthFailure(error);
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _authenticate(
        () => auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<AppUser> signUpWithEmail(String name, String email, String password) =>
      _authenticate(() async {
        final result = await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await result.user?.updateDisplayName(name.trim());
        return result;
      });

  @override
  Future<AppUser> signInWithGoogle() async {
    if (kIsWeb) {
      return _authenticate(() => auth.signInWithPopup(GoogleAuthProvider()));
    }
    final iosClientId = auth.app.options.iosClientId;
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        (iosClientId == null || iosClientId.isEmpty)) {
      throw const AuthFailure(
        'Google sign-in is not configured for iOS yet. Contact support.',
      );
    }
    try {
      final google = GoogleSignIn.instance;
      await (_googleInitialization ??= google.initialize(
        clientId: iosClientId,
      ));
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AuthFailure(
          'Google could not verify this account. Try again.',
        );
      }
      final user = await _authenticate(
        () => auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: token),
        ),
      );
      _usedGoogle = true;
      return user;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelled();
      }
      throw const AuthFailure(
        'Google sign-in is unavailable. Check the Google provider and app configuration.',
      );
    }
  }

  @override
  Future<AppUser> signInWithApple() {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    return _authenticate(
      () => kIsWeb
          ? auth.signInWithPopup(provider)
          : auth.signInWithProvider(provider),
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      // Do not disclose whether an email has an account.
      if (error.code != 'user-not-found') throw firebaseAuthFailure(error);
    }
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
    if (_usedGoogle && !kIsWeb) {
      _usedGoogle = false;
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Firebase session is already signed out. */
      }
    }
  }
}
