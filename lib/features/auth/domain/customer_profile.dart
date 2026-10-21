class CustomerProfile {
  const CustomerProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
  });
  final String userId;
  final String fullName;
  final String email;
  final String phone;
}

abstract interface class CustomerProfileRepository {
  Future<CustomerProfile?> get(String userId);
  Future<void> save(CustomerProfile profile);
}
