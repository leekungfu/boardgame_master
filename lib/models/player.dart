import 'role.dart';

class Player {
  final String id;
  final String name;
  final bool isAlive;
  final Role? role;

  const Player({
    required this.id,
    required this.name,
    this.isAlive = true,
    this.role,
  });

  Player copyWith({String? name, bool? isAlive, Object? role = _sentinel}) {
    return Player(
      id: id,
      name: name ?? this.name,
      isAlive: isAlive ?? this.isAlive,
      role: role == _sentinel ? this.role : role as Role?,
    );
  }
}

const _sentinel = Object();
