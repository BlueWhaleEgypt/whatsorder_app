import 'package:equatable/equatable.dart';

abstract class DeleteProductEvent extends Equatable {
  const DeleteProductEvent();

  @override
  List<Object?> get props => [];
}

class SubmitDeleteProductEvent extends DeleteProductEvent {
  final String productId;

  const SubmitDeleteProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}
