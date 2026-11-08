import 'package:whats_order/features/settings/data/product/add_product_request.dart';

/// PUT /api/auth/vendor-services/{id}: the same fields as adding a product.
class UpdateProductRequest {
  final String id;
  final AddProductRequest product;

  const UpdateProductRequest({required this.id, required this.product});
}
