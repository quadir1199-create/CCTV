import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/customer_profile.dart';

class FirebaseCustomerProfileRepository implements CustomerProfileRepository {
  FirebaseCustomerProfileRepository(this.firestore);
  final FirebaseFirestore firestore;
  CollectionReference<Map<String, dynamic>> get _profiles =>
      firestore.collection('users');

  @override
  Future<CustomerProfile?> get(String userId) async {
    final snapshot = await _profiles.doc(userId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return CustomerProfile(
      userId: userId,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
    );
  }

  @override
  Future<void> save(CustomerProfile profile) =>
      _profiles.doc(profile.userId).set({
        'fullName': profile.fullName.trim(),
        'email': profile.email.trim().toLowerCase(),
        'phone': profile.phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
