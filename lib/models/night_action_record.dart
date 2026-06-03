class NightActionRecord {
  final int round;
  final String? wolfTarget;
  final String? bodyguardTarget;
  final String? witchSaveTarget;
  final String? witchKillTarget;
  final String? seerTarget;
  final bool? seerResultIsWolf;
  final bool resolved;

  const NightActionRecord({
    required this.round,
    this.wolfTarget,
    this.bodyguardTarget,
    this.witchSaveTarget,
    this.witchKillTarget,
    this.seerTarget,
    this.seerResultIsWolf,
    this.resolved = false,
  });

  NightActionRecord copyWith({
    Object? wolfTarget = _s,
    Object? bodyguardTarget = _s,
    Object? witchSaveTarget = _s,
    Object? witchKillTarget = _s,
    Object? seerTarget = _s,
    Object? seerResultIsWolf = _s,
    bool? resolved,
  }) {
    return NightActionRecord(
      round: round,
      wolfTarget: wolfTarget == _s ? this.wolfTarget : wolfTarget as String?,
      bodyguardTarget: bodyguardTarget == _s ? this.bodyguardTarget : bodyguardTarget as String?,
      witchSaveTarget: witchSaveTarget == _s ? this.witchSaveTarget : witchSaveTarget as String?,
      witchKillTarget: witchKillTarget == _s ? this.witchKillTarget : witchKillTarget as String?,
      seerTarget: seerTarget == _s ? this.seerTarget : seerTarget as String?,
      seerResultIsWolf: seerResultIsWolf == _s ? this.seerResultIsWolf : seerResultIsWolf as bool?,
      resolved: resolved ?? this.resolved,
    );
  }

  List<String> resolveDeaths() {
    final blocked = <String>{};
    if (bodyguardTarget != null) blocked.add(bodyguardTarget!);
    if (witchSaveTarget != null) blocked.add(witchSaveTarget!);

    final died = <String>{};
    // Wolf attack: blocked by bodyguard protection or witch save.
    if (wolfTarget != null && !blocked.contains(wolfTarget)) {
      died.add(wolfTarget!);
    }
    // Witch poison: always lethal, bypasses protection.
    if (witchKillTarget != null) {
      died.add(witchKillTarget!);
    }
    return died.toList();
  }

  Map<String, dynamic> toJson() => {
        'round': round,
        'wolfTarget': wolfTarget,
        'bodyguardTarget': bodyguardTarget,
        'witchSaveTarget': witchSaveTarget,
        'witchKillTarget': witchKillTarget,
        'seerTarget': seerTarget,
        'seerResultIsWolf': seerResultIsWolf,
        'resolved': resolved,
      };

  factory NightActionRecord.fromJson(Map<String, dynamic> json) => NightActionRecord(
        round: json['round'] as int,
        wolfTarget: json['wolfTarget'] as String?,
        bodyguardTarget: json['bodyguardTarget'] as String?,
        witchSaveTarget: json['witchSaveTarget'] as String?,
        witchKillTarget: json['witchKillTarget'] as String?,
        seerTarget: json['seerTarget'] as String?,
        seerResultIsWolf: json['seerResultIsWolf'] as bool?,
        resolved: json['resolved'] as bool? ?? false,
      );
}

const _s = Object();
