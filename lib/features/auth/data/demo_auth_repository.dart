import 'dart:async';
import '../domain/auth_repository.dart';
import '../domain/customer_profile.dart';

class DemoAuthRepository implements AuthRepository, CustomerProfileRepository {
  final _users = StreamController<AppUser?>.broadcast();
  final _profiles = <String, CustomerProfile>{};
  final _accounts = <String, ({String name, String password})>{};
  AppUser? _user;

  @override
  Stream<AppUser?> watchUser() async* {
    yield _user;
    yield* _users.stream;
  }

  AppUser _signIn(String email, String name) {
    _user = AppUser('demo-$email', email: email, displayName: name);
    _users.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    email = email.trim().toLowerCase();
    if (_accounts.containsKey(email)) {
      throw const AuthFailure(
        'An account already uses this email. Sign in instead.',
      );
    }
    _accounts[email] = (name: name.trim(), password: password);
    return _signIn(email, name.trim());
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    email = email.trim().toLowerCase();
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const AuthFailure('The email or password is incorrect.');
    }
    return _signIn(email, account.name);
  }

  @override
  Future<AppUser> signInWithGoogle() async =>
      _signIn('google@example.com', 'Google Customer');
  @override
  Future<AppUser> signInWithApple() async =>
      _signIn('apple@example.com', 'Apple Customer');
  @override
  Future<void> resetPassword(String email) async {}
  @override
  Future<void> signOut() async {
    _user = null;
    _users.add(null);
  }

  @override
  Future<CustomerProfile?> get(String userId) async => _profiles[userId];
  @override
  Future<void> save(CustomerProfile profile) async {
    _profiles[profile.userId] = profile;
  }

  void dispose() => _users.close();
}
