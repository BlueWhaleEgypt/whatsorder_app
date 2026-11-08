import 'package:equatable/equatable.dart';

abstract class DeleteProductState extends Equatable {
  const DeleteProductState();

  @override
  List<Object?> get props => [];
}

class DeleteProductInitial extends DeleteProductState {
  const DeleteProductInitial();
}

class DeleteProductLoading extends DeleteProductState {
  final String productId;

  const DeleteProductLoading(this.productId);

  @override
  List<Object?> get props => [productId];
}

class DeleteProductSuccess extends DeleteProductState {
  final String message;

  const DeleteProductSuccess(this.message);

  // Every success is its own event so deleting twice still reaches the UI.
  @override
  List<Object?> get props => [identityHashCode(this)];
}

class DeleteProductError extends DeleteProductState {
  final String message;

  const DeleteProductError(this.message);

  @override
  List<Object?> get props => [identityHashCode(this)];
}
