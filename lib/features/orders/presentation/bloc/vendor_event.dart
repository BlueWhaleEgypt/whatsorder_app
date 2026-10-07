import 'package:equatable/equatable.dart';

abstract class VendorEvent extends Equatable {
  const VendorEvent();

  @override
  List<Object?> get props => [];
}

class FetchVendorEvent extends VendorEvent {
  const FetchVendorEvent();

  @override
  List<Object?> get props => [];
}
