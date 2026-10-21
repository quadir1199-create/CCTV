enum ComplaintStatus { submitted, assigned, inProgress, resolved }

class Complaint {
  const Complaint({
    required this.id,
    required this.ownerId,
    required this.product,
    required this.serialNumber,
    required this.description,
    required this.address,
    required this.createdAt,
    this.status = ComplaintStatus.submitted,
  });
  final String id, ownerId, product, serialNumber, description, address;
  final DateTime createdAt;
  final ComplaintStatus status;
}

class ComplaintDraft {
  const ComplaintDraft({
    required this.product,
    required this.serialNumber,
    required this.description,
    required this.address,
  });
  final String product, serialNumber, description, address;
  void validate() {
    if (product.trim().isEmpty ||
        serialNumber.trim().isEmpty ||
        description.trim().length < 10 ||
        address.trim().isEmpty) {
      throw const FormatException(
        'Enter product, serial number, address and an issue of at least 10 characters.',
      );
    }
    if (product.length > 100 ||
        serialNumber.length > 100 ||
        description.length > 2000 ||
        address.length > 500) {
      throw const FormatException(
        'One or more fields exceed the allowed length.',
      );
    }
  }
}

abstract interface class ComplaintRepository {
  Stream<List<Complaint>> watchComplaints(String ownerId);
  Future<String> submit(String ownerId, ComplaintDraft draft);
}

class SubmitComplaint {
  const SubmitComplaint(this.repository);
  final ComplaintRepository repository;
  Future<String> call(String ownerId, ComplaintDraft draft) {
    draft.validate();
    if (ownerId.isEmpty) {
      throw StateError('Sign in before submitting a complaint.');
    }
    return repository.submit(ownerId, draft);
  }
}
