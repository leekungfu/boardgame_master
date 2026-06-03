import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/role.dart';

/// Thematic Phosphor (Fill) icon for each role, replacing the generic emojis
/// with a cohesive, higher-depth icon set. Falls back to a team icon for any
/// role not explicitly mapped (covers the full glossary).
class RoleIcons {
  RoleIcons._();

  static const Map<String, IconData> _byId = {
    // Villagers — core
    'villager': PhosphorIconsFill.user,
    'seer': PhosphorIconsFill.eye,
    'apprentice_seer': PhosphorIconsFill.eye,
    'aura_seer': PhosphorIconsFill.eye,
    'mystic_seer': PhosphorIconsFill.eye,
    'beholder': PhosphorIconsFill.eye,
    'nostradamus': PhosphorIconsFill.eye,
    'revealer': PhosphorIconsFill.eye,
    'witch': PhosphorIconsFill.flask,
    'hunter': PhosphorIconsFill.crosshairSimple,
    'huntress': PhosphorIconsFill.crosshairSimple,
    'fool': PhosphorIconsFill.maskHappy,
    'idiot': PhosphorIconsFill.maskHappy,
    'bodyguard': PhosphorIconsFill.shieldCheck,
    'guardian_angel': PhosphorIconsFill.shieldCheck,
    'priest': PhosphorIconsFill.shieldCheck,
    'martyr': PhosphorIconsFill.heart,
    'pacifist': PhosphorIconsFill.heart,
    'cupid': PhosphorIconsFill.heart,
    'prince': PhosphorIconsFill.crown,
    'mayor': PhosphorIconsFill.medal,
    'little_girl': PhosphorIconsFill.baby,
    'scapegoat': PhosphorIconsFill.scales,
    'detective': PhosphorIconsFill.magnifyingGlass,
    'p_i': PhosphorIconsFill.magnifyingGlass,
    'mentalist': PhosphorIconsFill.eye,
    'insomniac': PhosphorIconsFill.moonStars,
    'mason': PhosphorIconsFill.users,
    'magician': PhosphorIconsFill.magicWand,
    'spellcaster': PhosphorIconsFill.magicWand,
    'old_hag': PhosphorIconsFill.magicWand,
    'troublemaker': PhosphorIconsFill.lightning,
    'ghost': PhosphorIconsFill.ghost,
    'lycan': PhosphorIconsFill.pawPrint,
    'cursed': PhosphorIconsFill.pawPrint,
    'doppelganger': PhosphorIconsFill.users,

    // Werewolves
    'werewolf': PhosphorIconsFill.pawPrint,
    'wolf_cub': PhosphorIconsFill.pawPrint,
    'white_wolf': PhosphorIconsFill.pawPrint,
    'lone_wolf': PhosphorIconsFill.pawPrint,
    'big_bad_wolf': PhosphorIconsFill.pawPrint,
    'dire_wolf': PhosphorIconsFill.pawPrint,
    'fruit_wolf': PhosphorIconsFill.pawPrint,
    'fang_face': PhosphorIconsFill.pawPrint,
    'wolverine': PhosphorIconsFill.pawPrint,
    'alpha_wolf': PhosphorIconsFill.pawPrint,
    'dreamwolf': PhosphorIconsFill.pawPrint,
    'wolf_man': PhosphorIconsFill.pawPrint,
    'teen_wolf': PhosphorIconsFill.pawPrint,
    'teenage_werewolf': PhosphorIconsFill.pawPrint,
    'sorcerer': PhosphorIconsFill.magicWand,
    'minion': PhosphorIconsFill.skull,

    // Solo / third party
    'serial_killer': PhosphorIconsFill.knife,
    'tanner': PhosphorIconsFill.skull,
    'hoodlum': PhosphorIconsFill.knife,
    'cult_leader': PhosphorIconsFill.users,
    'mad_bomber': PhosphorIconsFill.bomb,
    'leprechaun': PhosphorIconsFill.sparkle,
    'bogeyman': PhosphorIconsFill.skull,
    'zombie': PhosphorIconsFill.skull,
    'the_mummy': PhosphorIconsFill.skull,
    'frankenstein_s_monster': PhosphorIconsFill.lightning,
    'the_blob': PhosphorIconsFill.drop,
    'the_thing': PhosphorIconsFill.skull,
    'chupacabra': PhosphorIconsFill.pawPrint,
    'sasquatch': PhosphorIconsFill.pawPrint,

    // Vampires
    'vampire': PhosphorIconsFill.drop,
    'dracula': PhosphorIconsFill.drop,
    'count': PhosphorIconsFill.drop,
    'bloody_mary': PhosphorIconsFill.drop,
  };

  /// Convenience for a nullable [Role].
  static IconData forRole(Role? role) => iconFor(role?.id, role?.team ?? RoleTeam.villager);

  static IconData iconFor(String? id, RoleTeam team) {
    final mapped = id == null ? null : _byId[id];
    if (mapped != null) return mapped;
    switch (team) {
      case RoleTeam.werewolf:
        return PhosphorIconsFill.pawPrint;
      case RoleTeam.neutral:
        return PhosphorIconsFill.skull;
      case RoleTeam.villager:
        return PhosphorIconsFill.user;
    }
  }
}
