import 'package:equatable/equatable.dart';
import 'package:whats_order/features/settings/data/product/add_product_request.dart';
import 'package:whats_order/features/settings/data/product/update_product_request.dart';

abstract class AddProductEvent extends Equatable {
  const AddProductEvent();

  @override
  List<Object?> get props => [];
}

class SubmitAddProductEvent extends AddProductEvent {
  final AddProductRequest request;

  const SubmitAddProductEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class SubmitUpdateProductEvent extends AddProductEvent {
  final UpdateProductRequest request;

  const SubmitUpdateProductEvent(this.request);

  @override
  List<Object?> get props => [request];
}
