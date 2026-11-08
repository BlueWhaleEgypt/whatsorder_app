import 'package:whats_order/features/settings/data/product/product_model.dart';

/*
|--------------------------------------------------------------------------
| ProductsListing — what the products screen shows for a given product
| list, search text, sector filter and requested page.
|
| Pure and immutable: filtering, the sector options and pagination are all
| computed once here, so widgets only render the result. The requested page
| is clamped, so a shrinking list (new search, refresh) never points past
| the last page.
|--------------------------------------------------------------------------
*/

class ProductsListing {
  static const int pageSize = 8;

  /// Sector id -> name for every sector that has at least one product.
  final Map<String, String> sectors;

  /// Number of products before any filter is applied.
  final int totalCount;

  /// Number of products matching the search and sector filter.
  final int filteredCount;

  /// Products of the current page.
  final List<ProductModel> pageItems;

  /// Zero-based, already clamped into `[0, pageCount - 1]`.
  final int page;
  final int pageCount;

  const ProductsListing._({
    required this.sectors,
    required this.totalCount,
    required this.filteredCount,
    required this.pageItems,
    required this.page,
    required this.pageCount,
  });

  factory ProductsListing.from(
    List<ProductModel> products, {
    String query = '',
    String? sectorId,
    int page = 0,
  }) {
    final needle = query.trim().toLowerCase();

    final sectors = <String, String>{
      for (final p in products)
        if (p.sectorId.isNotEmpty) p.sectorId: p.sectorName,
    };

    final filtered = products.where((p) {
      final matchesSector = sectorId == null || p.sectorId == sectorId;
      final matchesQuery =
          needle.isEmpty ||
          p.name.toLowerCase().contains(needle) ||
          p.note.toLowerCase().contains(needle);
      return matchesSector && matchesQuery;
    }).toList();

    final pageCount = (filtered.length / pageSize).ceil().clamp(1, 9999);
    final clampedPage = page.clamp(0, pageCount - 1);
    final start = clampedPage * pageSize;

    return ProductsListing._(
      sectors: sectors,
      totalCount: products.length,
      filteredCount: filtered.length,
      pageItems: filtered.skip(start).take(pageSize).toList(growable: false),
      page: clampedPage,
      pageCount: pageCount,
    );
  }

  /// Zero-based index (within the filtered list) of the first page item.
  int get firstIndex => page * pageSize;

  bool get isEmpty => pageItems.isEmpty;

  /// Whether [sectorId] can still be selected for [products].
  static bool hasSector(List<ProductModel> products, String sectorId) =>
      products.any((p) => p.sectorId == sectorId);
}
