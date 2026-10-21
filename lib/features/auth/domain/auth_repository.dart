class AppUser {
  const AppUser(
    this.id, {
    required this.email,
    this.displayName = '',
    this.phone = '',
  });
  final String id;
  final String email;
  final String displayName;
  final String phone;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

class AuthCancelled implements Exception {
  const AuthCancelled();
}

abstract interface class AuthRepository {
  Stream<AppUser?> watchUser();
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(String name, String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> resetPassword(String email);
  Future<void> signOut();
}
