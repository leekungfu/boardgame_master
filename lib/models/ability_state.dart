class AbilityState {
  final bool witchSaveUsed;
  final bool witchKillUsed;
  final bool foolImmunityUsed;
  final bool hunterShotPending;
  final String? hunterShotTarget;
  final String? lastBodyguardTarget;

  const AbilityState({
    this.witchSaveUsed = false,
    this.witchKillUsed = false,
    this.foolImmunityUsed = false,
    this.hunterShotPending = false,
    this.hunterShotTarget,
    this.lastBodyguardTarget,
  });

  AbilityState copyWith({
    bool? witchSaveUsed,
    bool? witchKillUsed,
    bool? foolImmunityUsed,
    bool? hunterShotPending,
    Object? hunterShotTarget = _sentinel,
    Object? lastBodyguardTarget = _sentinel,
  }) {
    return AbilityState(
      witchSaveUsed: witchSaveUsed ?? this.witchSaveUsed,
      witchKillUsed: witchKillUsed ?? this.witchKillUsed,
      foolImmunityUsed: foolImmunityUsed ?? this.foolImmunityUsed,
      hunterShotPending: hunterShotPending ?? this.hunterShotPending,
      hunterShotTarget: hunterShotTarget == _sentinel ? this.hunterShotTarget : hunterShotTarget as String?,
      lastBodyguardTarget: lastBodyguardTarget == _sentinel ? this.lastBodyguardTarget : lastBodyguardTarget as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'witchSaveUsed': witchSaveUsed,
        'witchKillUsed': witchKillUsed,
        'foolImmunityUsed': foolImmunityUsed,
        'hunterShotPending': hunterShotPending,
        'hunterShotTarget': hunterShotTarget,
        'lastBodyguardTarget': lastBodyguardTarget,
      };

  factory AbilityState.fromJson(Map<String, dynamic> json) => AbilityState(
        witchSaveUsed: json['witchSaveUsed'] as bool? ?? false,
        witchKillUsed: json['witchKillUsed'] as bool? ?? false,
        foolImmunityUsed: json['foolImmunityUsed'] as bool? ?? false,
        hunterShotPending: json['hunterShotPending'] as bool? ?? false,
        hunterShotTarget: json['hunterShotTarget'] as String?,
        lastBodyguardTarget: json['lastBodyguardTarget'] as String?,
      );
}

const _sentinel = Object();
