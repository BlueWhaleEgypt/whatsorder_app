
class SectorRequest {
  final String action;
  final String? userId;
  final String? sectorId;

  const SectorRequest._({
    required this.action,
    this.userId,
    this.sectorId,
  });

  factory SectorRequest.add({
    required String userId,
    required String sectorId,
  }) {
    return SectorRequest._(
      action: 'add',
      userId: userId,
      sectorId: sectorId,
    );
  }

  factory SectorRequest.delete({
    required String userId,
    required String sectorId,
  }) {
    return SectorRequest._(
      action: 'delete',
      userId: userId,
      sectorId: sectorId,
    );
  }
}
