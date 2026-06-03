class VoteEntry {
  final String playerId;
  final int voteCount;

  const VoteEntry({required this.playerId, this.voteCount = 0});

  VoteEntry copyWith({int? voteCount}) =>
      VoteEntry(playerId: playerId, voteCount: voteCount ?? this.voteCount);

  Map<String, dynamic> toJson() => {'playerId': playerId, 'voteCount': voteCount};

  factory VoteEntry.fromJson(Map<String, dynamic> j) =>
      VoteEntry(playerId: j['playerId'] as String, voteCount: j['voteCount'] as int? ?? 0);
}

class VoteTally {
  final int round;
  final List<VoteEntry> nominations;
  final bool resolved;
  final String? executedPlayerId;
  final bool wasTied;

  const VoteTally({
    required this.round,
    this.nominations = const [],
    this.resolved = false,
    this.executedPlayerId,
    this.wasTied = false,
  });

  VoteTally copyWith({
    List<VoteEntry>? nominations,
    bool? resolved,
    Object? executedPlayerId = _s,
    bool? wasTied,
  }) {
    return VoteTally(
      round: round,
      nominations: nominations ?? List.from(this.nominations),
      resolved: resolved ?? this.resolved,
      executedPlayerId: executedPlayerId == _s ? this.executedPlayerId : executedPlayerId as String?,
      wasTied: wasTied ?? this.wasTied,
    );
  }

  VoteTally resolve() {
    if (nominations.isEmpty) return copyWith(resolved: true);
    final maxVotes = nominations.map((e) => e.voteCount).reduce((a, b) => a > b ? a : b);
    final winners = nominations.where((e) => e.voteCount == maxVotes).toList();
    if (winners.length == 1) {
      return copyWith(resolved: true, executedPlayerId: winners.first.playerId, wasTied: false);
    }
    return copyWith(resolved: true, executedPlayerId: null, wasTied: true);
  }

  Map<String, dynamic> toJson() => {
        'round': round,
        'nominations': nominations.map((e) => e.toJson()).toList(),
        'resolved': resolved,
        'executedPlayerId': executedPlayerId,
        'wasTied': wasTied,
      };

  factory VoteTally.fromJson(Map<String, dynamic> json) => VoteTally(
        round: json['round'] as int,
        nominations: (json['nominations'] as List<dynamic>?)
                ?.map((e) => VoteEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        resolved: json['resolved'] as bool? ?? false,
        executedPlayerId: json['executedPlayerId'] as String?,
        wasTied: json['wasTied'] as bool? ?? false,
      );
}

const _s = Object();
