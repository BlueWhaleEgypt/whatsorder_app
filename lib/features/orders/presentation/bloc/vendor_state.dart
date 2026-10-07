import 'package:equatable/equatable.dart';
import 'package:whats_order/features/orders/data/vendor_response.dart';

abstract class VendorState extends Equatable {
  const VendorState();

  @override
  List<Object?> get props => [];
}

class VendorInitial extends VendorState {}

class VendorLoading extends VendorState {}

class VendorLoaded extends VendorState {
  final VendorResponse vendorResponse;

  const VendorLoaded({
    required this.vendorResponse,
  });

  @override
  List<Object?> get props => [vendorResponse];
}

class VendorError extends VendorState {
  final String message;

  const VendorError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}