/*
|--------------------------------------------------------------------------
| SectorModel
|--------------------------------------------------------------------------
|
| Represents a single business sector returned by GET /api/auth/sector.
| id   — UUID used as the sectorId field in the sign-up request.
| name — Display name (may contain Arabic + emoji).
| note — Short description of the sector.
| cost — Subscription cost for the sector.
| view — Whether this sector is publicly visible.
|
|--------------------------------------------------------------------------
*/

class SectorModel {
  final String id;
  final String name;
  final String note;
  final int cost;
  final bool view;

  const SectorModel({
    required this.id,
    required this.name,
    required this.note,
    required this.cost,
    required this.view,
  });

  factory SectorModel.fromJson(Map<String, dynamic> json) {
    return SectorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      note: json['note'] as String? ?? '',
      cost: (json['cost'] as num).toInt(),
      view: json['view'] as bool? ?? true,
    );
  }
}
