import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  final int? id;
  final String name;
  final DateTime createdAt;
  final bool isActive;

  const Habit({
    this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, createdAt, isActive];
}