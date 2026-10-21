import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/complaint.dart';

class FirebaseComplaintRepository implements ComplaintRepository {
  FirebaseComplaintRepository(this.firestore);
  final FirebaseFirestore firestore;
  @override
  Stream<List<Complaint>> watchComplaints(String ownerId) => firestore
      .collection('complaints')
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs.map((doc) {
          final data = doc.data();
          return Complaint(
            id: doc.id,
            ownerId: data['ownerId'] as String,
            product: data['product'] as String,
            serialNumber: data['serialNumber'] as String,
            description: data['description'] as String,
            address: data['address'] as String,
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: ComplaintStatus.values.byName(data['status'] as String),
          );
        }).toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      });
  @override
  Future<String> submit(String ownerId, ComplaintDraft draft) async {
    final doc = await firestore.collection('complaints').add({
      'ownerId': ownerId,
      'product': draft.product.trim(),
      'serialNumber': draft.serialNumber.trim(),
      'description': draft.description.trim(),
      'address': draft.address.trim(),
      'status': ComplaintStatus.submitted.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
