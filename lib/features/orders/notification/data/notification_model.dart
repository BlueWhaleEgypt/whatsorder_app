import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel extends Equatable {
  final String? id;
  final String? components;
  final String? title;
  final int? orderId;
  final double? latitude;
  final double? longitude;
  final bool? pressed;

  const NotificationModel({
    this.id,
    this.components,
    this.title,
    this.orderId,
    this.latitude,
    this.longitude,
    this.pressed,
  });

  /// `pressed == true` means the user already opened this notification
  /// (read). `false`/`null` means unread.
  bool get isRead => pressed == true;

  NotificationModel copyWith({bool? pressed}) => NotificationModel(
    id: id,
    components: components,
    title: title,
    orderId: orderId,
    latitude: latitude,
    longitude: longitude,
    pressed: pressed ?? this.pressed,
  );

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    components,
    title,
    orderId,
    latitude,
    longitude,
    pressed,
  ];
}
