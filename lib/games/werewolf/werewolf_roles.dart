import '../../models/role.dart';

class WerewolfRoles {
  // ─── Core village ───────────────────────────────────────────────────────────
  static const Role villager = Role(
    id: 'villager',
    name: 'Dân Làng',
    emoji: '👨‍🌾',
    team: RoleTeam.villager,
    description: 'Không có kỹ năng đặc biệt. Bỏ phiếu ban ngày để loại Ma Sói.',
  );

  static const Role seer = Role(
    id: 'seer',
    name: 'Tiên Tri',
    emoji: '🔮',
    team: RoleTeam.villager,
    description: 'Mỗi đêm, xem bài của 1 người để biết họ là Sói hay Dân.',
    hasNightAction: true,
    nightOrder: 3,
  );

  static const Role witch = Role(
    id: 'witch',
    name: 'Phù Thủy',
    emoji: '🧪',
    team: RoleTeam.villager,
    description: 'Có 1 bình cứu và 1 bình độc. Dùng mỗi bình 1 lần trong game.',
    hasNightAction: true,
    nightOrder: 4,
  );

  static const Role hunter = Role(
    id: 'hunter',
    name: 'Thợ Săn',
    emoji: '🏹',
    team: RoleTeam.villager,
    description: 'Khi bị chết (bất kỳ lý do), được bắn chết 1 người bất kỳ.',
  );

  static const Role fool = Role(
    id: 'fool',
    name: 'Thằng Ngốc',
    emoji: '🤪',
    team: RoleTeam.villager,
    description: 'Nếu bị vote chết ban ngày, lộ bài nhưng không chết. Hiệu ứng xảy ra 1 lần.',
  );

  static const Role bodyguard = Role(
    id: 'bodyguard',
    name: 'Hiệp Sĩ',
    emoji: '🛡️',
    team: RoleTeam.villager,
    description: 'Mỗi đêm, bảo vệ 1 người (không được bảo vệ cùng người 2 đêm liên tiếp).',
    hasNightAction: true,
    nightOrder: 1,
  );

  // ─── Ultimate village expansion ───────────────────────────────────────────────
  static const Role cupid = Role(
    id: 'cupid',
    name: 'Thần Tình Yêu',
    emoji: '💘',
    team: RoleTeam.villager,
    description:
        'Đêm đầu tiên, ghép 2 người thành một cặp tình nhân. Nếu một người chết, người kia chết theo vì đau buồn.',
    hasNightAction: true,
    nightOrder: 0,
  );

  static const Role elder = Role(
    id: 'elder',
    name: 'Già Làng',
    emoji: '👴',
    team: RoleTeam.villager,
    description:
        'Sống sót được lần đầu tiên bị Ma Sói cắn (cần bị cắn 2 lần mới chết). Không chống được độc hay xử tử.',
  );

  static const Role prince = Role(
    id: 'prince',
    name: 'Hoàng Tử',
    emoji: '🤴',
    team: RoleTeam.villager,
    description: 'Lần đầu bị làng vote xử tử sẽ lộ thân phận Hoàng Tử và không chết.',
  );

  static const Role apprenticeSeer = Role(
    id: 'apprentice_seer',
    name: 'Tiên Tri Tập Sự',
    emoji: '🔮',
    team: RoleTeam.villager,
    description: 'Là Dân thường cho tới khi Tiên Tri chết, sau đó trở thành Tiên Tri mới.',
  );

  static const Role mayor = Role(
    id: 'mayor',
    name: 'Trưởng Làng',
    emoji: '🎖️',
    team: RoleTeam.villager,
    description: 'Phiếu bầu ban ngày của Trưởng Làng được tính gấp đôi.',
  );

  static const Role littleGirl = Role(
    id: 'little_girl',
    name: 'Bé Gái',
    emoji: '👧',
    team: RoleTeam.villager,
    description:
        'Có thể hé mắt nhìn trộm khi Ma Sói thức để đoán Sói. Nếu bị Sói bắt gặp, có thể bị giết ngay.',
  );

  static const Role guardianAngel = Role(
    id: 'guardian_angel',
    name: 'Thiên Thần Hộ Mệnh',
    emoji: '😇',
    team: RoleTeam.villager,
    description: 'Mỗi đêm chọn bảo vệ 1 người khỏi mọi cái chết đêm đó. Không tự bảo vệ mình.',
    hasNightAction: true,
    nightOrder: 1,
  );

  static const Role scapegoat = Role(
    id: 'scapegoat',
    name: 'Vật Tế',
    emoji: '🐐',
    team: RoleTeam.villager,
    description: 'Khi vote hòa, Vật Tế sẽ là người bị xử tử thay cho cả làng.',
  );

  static const Role detective = Role(
    id: 'detective',
    name: 'Thám Tử',
    emoji: '🕵️',
    team: RoleTeam.villager,
    description: 'Mỗi đêm chọn 2 người để biết họ có cùng phe hay không (không biết phe cụ thể).',
    hasNightAction: true,
    nightOrder: 3,
  );

  // ─── Core & expansion werewolves ──────────────────────────────────────────────
  static const Role werewolf = Role(
    id: 'werewolf',
    name: 'Ma Sói',
    emoji: '🐺',
    team: RoleTeam.werewolf,
    description: 'Mỗi đêm, Ma Sói thức dậy và cùng nhau chọn 1 người để giết.',
    hasNightAction: true,
    nightOrder: 2,
  );

  static const Role wolfCub = Role(
    id: 'wolf_cub',
    name: 'Sói Con',
    emoji: '🐶',
    team: RoleTeam.werewolf,
    description: 'Là Sói. Khi Sói Con chết, đêm kế tiếp bầy Sói được cắn 2 người thay vì 1.',
    hasNightAction: true,
    nightOrder: 2,
  );

  static const Role minion = Role(
    id: 'minion',
    name: 'Tay Sai',
    emoji: '😈',
    team: RoleTeam.werewolf,
    description:
        'Biết ai là Ma Sói nhưng bản thân không phải Sói (Tiên Tri soi ra Dân). Thắng cùng phe Sói.',
  );

  static const Role sorcerer = Role(
    id: 'sorcerer',
    name: 'Thầy Pháp',
    emoji: '🧙',
    team: RoleTeam.werewolf,
    description: 'Phe Sói. Mỗi đêm soi 1 người để biết người đó có phải Tiên Tri hay không.',
    hasNightAction: true,
    nightOrder: 3,
  );

  static const Role whiteWolf = Role(
    id: 'white_wolf',
    name: 'Sói Trắng',
    emoji: '🦊',
    team: RoleTeam.werewolf,
    description:
        'Phe Sói nhưng mục tiêu là kẻ sống sót cuối cùng. Cứ cách một đêm có thể cắn thêm 1 con Sói khác.',
    hasNightAction: true,
    nightOrder: 5,
  );

  // ─── Neutral / solo ─────────────────────────────────────────────────────────
  static const Role serialKiller = Role(
    id: 'serial_killer',
    name: 'Sát Nhân Hàng Loạt',
    emoji: '🔪',
    team: RoleTeam.neutral,
    description: 'Mỗi đêm âm thầm giết 1 người. Thắng khi là người duy nhất còn sống.',
    hasNightAction: true,
    nightOrder: 6,
  );

  static const Role tanner = Role(
    id: 'tanner',
    name: 'Kẻ Chán Đời',
    emoji: '🪢',
    team: RoleTeam.neutral,
    description: 'Mục tiêu duy nhất là bị làng vote xử tử. Nếu bị xử tử, Kẻ Chán Đời thắng một mình.',
  );

  static const Role cursed = Role(
    id: 'cursed',
    name: 'Kẻ Bị Nguyền',
    emoji: '😾',
    team: RoleTeam.villager,
    description:
        'Là Dân Làng cho tới khi bị Ma Sói cắn — thay vì chết, sẽ biến thành Ma Sói và gia nhập bầy.',
  );

  static const List<Role> all = [
    // Village core
    villager,
    seer,
    witch,
    hunter,
    fool,
    bodyguard,
    // Village expansion
    cupid,
    elder,
    prince,
    apprenticeSeer,
    mayor,
    littleGirl,
    guardianAngel,
    scapegoat,
    detective,
    // Werewolves
    werewolf,
    wolfCub,
    minion,
    sorcerer,
    whiteWolf,
    // Neutral
    serialKiller,
    tanner,
    cursed,
  ];
}
