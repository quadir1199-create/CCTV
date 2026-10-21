import 'package:flutter_test/flutter_test.dart';
import 'package:cctv_service/features/complaints/domain/complaint.dart';
import 'package:cctv_service/features/complaints/data/demo_complaint_repository.dart';

void main() {
  test('invalid complaint never reaches repository', () {
    final repository = DemoComplaintRepository();
    addTearDown(repository.dispose);
    expect(
      () => SubmitComplaint(repository)(
        'demo',
        const ComplaintDraft(
          product: 'Camera',
          serialNumber: '',
          description: 'short',
          address: 'Doha',
        ),
      ),
      throwsFormatException,
    );
  });
  test('repository isolates customers', () async {
    final repository = DemoComplaintRepository();
    addTearDown(repository.dispose);
    await SubmitComplaint(repository)(
      'customer-b',
      const ComplaintDraft(
        product: 'Dome',
        serialNumber: 'SN-B',
        description: 'Image has stopped working.',
        address: 'Doha',
      ),
    );
    final items = await repository.watchComplaints('customer-b').first;
    expect(items, hasLength(1));
    expect(items.single.ownerId, 'customer-b');
  });
}
