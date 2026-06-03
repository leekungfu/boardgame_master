import 'base_game.dart';
import 'werewolf/werewolf_game.dart';

class GameRegistry {
  GameRegistry._();

  static final Map<String, BaseGame> _games = {
    WerewolfGame.instance.id: WerewolfGame.instance,
  };

  static List<BaseGame> get all => _games.values.toList();

  static BaseGame? getById(String id) => _games[id];
}

