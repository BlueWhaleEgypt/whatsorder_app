import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductsEvent extends ProductsEvent {
  final String vendorId;

  const FetchProductsEvent({required this.vendorId});

  @override
  List<Object?> get props => [vendorId];
}
