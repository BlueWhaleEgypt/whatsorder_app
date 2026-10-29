import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sms_message_model.g.dart';

@JsonSerializable()
class SmsMessageModel extends Equatable {
  final String id;
  final String? components;
  final String? title;
  final int? orderId;
  final String? userId;

  @JsonKey(defaultValue: false)
  final bool pressed;

  const SmsMessageModel({
    required this.id,
    this.components,
    this.title,
    this.orderId,
    this.userId,
    this.pressed = false,
  });

  factory SmsMessageModel.fromJson(Map<String, dynamic> json) =>
      _$SmsMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$SmsMessageModelToJson(this);

  SmsMessageModel copyWith({bool? pressed}) {
    return SmsMessageModel(
      id: id,
      components: components,
      title: title,
      orderId: orderId,
      userId: userId,
      pressed: pressed ?? this.pressed,
    );
  }

  @override
  List<Object?> get props => [id, components, title, orderId, userId, pressed];
}
