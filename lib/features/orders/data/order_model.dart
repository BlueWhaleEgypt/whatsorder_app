import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

/*
|--------------------------------------------------------------------------
| OrderModel
|--------------------------------------------------------------------------
|
| A single row in the orders table shown on the home screen:
| Order ID / Date / Location / Details (edit) / a checked/unchecked state.
|
|--------------------------------------------------------------------------
*/

@JsonSerializable()
class OrderModel extends Equatable {
  final String id;
  final int? orderId;
  @JsonKey(defaultValue: false)
  final bool isChecked;
  @JsonKey(defaultValue: false)
  final bool view;
  final num? price;
  final String? phone;
  final String? components;
  final String? sector;
  final double? latitude;
  final double? longitude;
  final String? createdDate;
  final num? cost;
  final String? vendorId;
  const OrderModel(
      {required this.id,
      this.orderId,
      this.isChecked = false,
      this.view = false,
      this.price,
      this.phone,
      this.components,
      this.sector,
      this.latitude,
      this.longitude,
      this.createdDate,
      this.cost,
      this.vendorId});

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderModel copyWith({
    bool? isChecked,
    bool? view,
  }) {
    return OrderModel(
        id: id,
        orderId: orderId,
        isChecked: isChecked ?? this.isChecked,
        view: view ?? this.view,
        price: price,
        phone: phone,
        components: components,
        sector: sector,
        latitude: latitude,
        longitude: longitude,
        createdDate: createdDate,
        cost: cost,
        vendorId: vendorId);
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        isChecked,
        view,
        price,
        phone,
        components,
        sector,
        latitude,
        longitude,
        createdDate,
        cost,
        vendorId
      ];
}
