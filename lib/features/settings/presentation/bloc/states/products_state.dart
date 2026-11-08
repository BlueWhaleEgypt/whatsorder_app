import 'package:equatable/equatable.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitialState extends ProductsState {
  const ProductsInitialState();
}

class ProductsLoadingState extends ProductsState {
  const ProductsLoadingState();
}

class ProductsLoadedState extends ProductsState {
  final List<ProductModel> products;

  const ProductsLoadedState(this.products);

  @override
  List<Object?> get props => [products.map((p) => p.id).toList()];
}

class ProductsErrorState extends ProductsState {
  final String message;

  const ProductsErrorState(this.message);

  @override
  List<Object?> get props => [identityHashCode(this)];
}
