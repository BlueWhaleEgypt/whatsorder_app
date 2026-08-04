import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sector_model_login.g.dart';

@JsonSerializable()
class SectorModelLogin extends Equatable {
  final String? id;
  final String? name;
  final String? note;
  final num? cost;
  final bool? view;

  const SectorModelLogin({
    this.id,
    this.name,
    this.note,
    this.cost,
    this.view,
  });

  factory SectorModelLogin.fromJson(Map<String, dynamic> json) =>
      _$SectorModelLoginFromJson(json);

  Map<String, dynamic> toJson() => _$SectorModelLoginToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        note,
        cost,
        view,
      ];
}
