import 'package:equatable/equatable.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';

abstract class AddProductState extends Equatable {
  const AddProductState();

  @override
  List<Object?> get props => [];
}

class AddProductInitial extends AddProductState {
  const AddProductInitial();
}

class AddProductLoading extends AddProductState {
  const AddProductLoading();
}

class AddProductSuccess extends AddProductState {
  final String message;
  final ProductModel? product;

  const AddProductSuccess(this.message, {this.product});

  @override
  List<Object?> get props => [message, product?.id];
}

class AddProductError extends AddProductState {
  final String message;

  const AddProductError(this.message);

  // Every error is its own event so repeated failures still reach the UI.
  @override
  List<Object?> get props => [identityHashCode(this)];
}
