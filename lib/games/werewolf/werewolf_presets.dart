class RolePreset {
  final int playerCount;
  final Map<String, int> roleCounts;

  const RolePreset({required this.playerCount, required this.roleCounts});
}

class WerewolfPresets {
  WerewolfPresets._();

  static const Map<int, RolePreset> table = {
    5: RolePreset(playerCount: 5, roleCounts: {'werewolf': 1, 'seer': 1, 'villager': 3}),
    6: RolePreset(playerCount: 6, roleCounts: {'werewolf': 1, 'seer': 1, 'witch': 1, 'villager': 3}),
    7: RolePreset(playerCount: 7, roleCounts: {'werewolf': 2, 'seer': 1, 'witch': 1, 'villager': 3}),
    8: RolePreset(playerCount: 8, roleCounts: {'werewolf': 2, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'villager': 3}),
    9: RolePreset(playerCount: 9, roleCounts: {'werewolf': 2, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'villager': 3}),
    10: RolePreset(playerCount: 10, roleCounts: {'werewolf': 3, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'villager': 3}),
    11: RolePreset(playerCount: 11, roleCounts: {'werewolf': 3, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 3}),
    12: RolePreset(playerCount: 12, roleCounts: {'werewolf': 3, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 4}),
    13: RolePreset(playerCount: 13, roleCounts: {'werewolf': 4, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 4}),
    14: RolePreset(playerCount: 14, roleCounts: {'werewolf': 4, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 5}),
    15: RolePreset(playerCount: 15, roleCounts: {'werewolf': 5, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 5}),
    16: RolePreset(playerCount: 16, roleCounts: {'werewolf': 5, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 6}),
    17: RolePreset(playerCount: 17, roleCounts: {'werewolf': 5, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 7}),
    18: RolePreset(playerCount: 18, roleCounts: {'werewolf': 6, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 7}),
    19: RolePreset(playerCount: 19, roleCounts: {'werewolf': 6, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 8}),
    20: RolePreset(playerCount: 20, roleCounts: {'werewolf': 6, 'seer': 1, 'witch': 1, 'bodyguard': 1, 'hunter': 1, 'fool': 1, 'villager': 9}),
  };
}
