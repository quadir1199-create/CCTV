import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/customer_profile.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/data/firebase_customer_profile_repository.dart';
import '../features/auth/data/demo_auth_repository.dart';
import '../features/complaints/domain/complaint.dart';
import '../features/complaints/data/firebase_complaint_repository.dart';

final demoModeProvider = Provider<bool>((ref) => false);
final authFlowBusyProvider = NotifierProvider<AuthFlowBusy, bool>(
  AuthFlowBusy.new,
);

class AuthFlowBusy extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(demoModeProvider)
      ? ref.watch(demoAuthRepositoryProvider)
      : FirebaseAuthRepository(FirebaseAuth.instance),
);
final demoAuthRepositoryProvider = Provider<DemoAuthRepository>((ref) {
  final repository = DemoAuthRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
final customerProfileRepositoryProvider = Provider<CustomerProfileRepository>(
  (ref) => ref.watch(demoModeProvider)
      ? ref.watch(demoAuthRepositoryProvider)
      : FirebaseCustomerProfileRepository(FirebaseFirestore.instance),
);
final complaintRepositoryProvider = Provider<ComplaintRepository>(
  (ref) => FirebaseComplaintRepository(FirebaseFirestore.instance),
);
final currentUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchUser(),
);
final customerProfileProvider = FutureProvider<CustomerProfile?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  return ref.watch(customerProfileRepositoryProvider).get(user.id);
});
final complaintsProvider = StreamProvider<List<Complaint>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user == null
      ? Stream.value([])
      : ref.watch(complaintRepositoryProvider).watchComplaints(user.id);
});
final submitComplaintProvider = Provider(
  (ref) => SubmitComplaint(ref.watch(complaintRepositoryProvider)),
);
final submissionProvider = AsyncNotifierProvider<SubmissionController, void>(
  SubmissionController.new,
);

class SubmissionController extends AsyncNotifier<void> {
  @override
  void build() {}
  Future<String?> submit(ComplaintDraft draft) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw StateError('Please sign in again.');
      id = await ref.read(submitComplaintProvider)(user.id, draft);
    });
    return id;
  }
}
