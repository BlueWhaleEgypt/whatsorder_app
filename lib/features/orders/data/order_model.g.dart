// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['id'] as String,
  orderId: (json['orderId'] as num?)?.toInt(),
  isChecked: json['isChecked'] as bool? ?? false,
  view: json['view'] as bool? ?? false,
  price: json['price'] as num?,
  phone: json['phone'] as String?,
  components: json['components'] as String?,
  sector: json['sector'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  createdDate: json['createdDate'] as String?,
  cost: json['cost'] as num?,
  vendorId: json['vendorId'] as String?,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'isChecked': instance.isChecked,
      'view': instance.view,
      'price': instance.price,
      'phone': instance.phone,
      'components': instance.components,
      'sector': instance.sector,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'createdDate': instance.createdDate,
      'cost': instance.cost,
      'vendorId': instance.vendorId,
    };
