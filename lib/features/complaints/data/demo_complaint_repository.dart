import 'dart:async';
import '../domain/complaint.dart';

class DemoComplaintRepository implements ComplaintRepository {
  final _changes = StreamController<void>.broadcast();
  final _items = <Complaint>[
    Complaint(
      id: 'DEMO-1042',
      ownerId: 'demo-+97455551234',
      product: 'Outdoor bullet camera',
      serialNumber: 'CAM-2026-0841',
      description: 'Night vision image appears blurry after sunset.',
      address: 'Demo installation address',
      createdAt: DateTime(2026, 10, 1),
      status: ComplaintStatus.inProgress,
    ),
  ];
  @override
  Stream<List<Complaint>> watchComplaints(String ownerId) async* {
    List<Complaint> snapshot() =>
        List.unmodifiable(_items.where((c) => c.ownerId == ownerId));
    yield snapshot();
    await for (final _ in _changes.stream) {
      yield snapshot();
    }
  }

  @override
  Future<String> submit(String ownerId, ComplaintDraft draft) async {
    final id = 'DEMO-${DateTime.now().microsecondsSinceEpoch}';
    _items.insert(
      0,
      Complaint(
        id: id,
        ownerId: ownerId,
        product: draft.product.trim(),
        serialNumber: draft.serialNumber.trim(),
        description: draft.description.trim(),
        address: draft.address.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _changes.add(null);
    return id;
  }

  void dispose() => _changes.close();
}
