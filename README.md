# 🎮 Board Game Master

App hỗ trợ Quản Trò (QT) điều phối các board game như Ma Sói.

## Tech Stack

- **Flutter** (iOS-first, dễ mở rộng Android sau)
- **Riverpod** - State management
- **Go Router** - Navigation (optional, dùng Navigator trực tiếp ở MVP)

## Kiến trúc

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart          # Dark theme, colors, typography
│
├── models/                     # Pure data classes (immutable)
│   ├── player.dart
│   ├── role.dart
│   ├── game_phase.dart
│   └── game_session.dart
│
├── games/                      # Game engine (extensible)
│   ├── base_game.dart          ← Abstract class mọi game phải impl
│   ├── game_registry.dart      ← Đăng ký game vào đây
│   └── werewolf/
│       ├── werewolf_game.dart  ← Logic Ma Sói
│       └── werewolf_roles.dart ← Định nghĩa tất cả roles
│
├── providers/
│   └── game_provider.dart      # Riverpod StateNotifier
│
├── screens/
│   ├── home_screen.dart        # Chọn game
│   ├── setup/
│   │   ├── player_setup_screen.dart    # Thêm người chơi
│   │   └── role_assignment_screen.dart # QT giao vai
│   └── game/
│       └── game_master_screen.dart     # Điều phối game
│
└── widgets/
    └── countdown_timer.dart    # Timer widget tái sử dụng
```

## User Flow

```
Home → Chọn Ma Sói
  → Thêm người chơi (5-20 người)
    → Giao vai trò (QT tap từng người, chọn vai)
      → Game Master Screen
          ├── Step-by-step phases (đêm → ngày)
          ├── Timer cho phase thảo luận
          ├── Ghi chú riêng cho QT (ẩn/hiện)
          └── Quản lý alive/dead players
```

## Thêm game mới

1. Tạo folder `lib/games/your_game/`
2. Tạo `your_game_roles.dart` - định nghĩa các roles
3. Tạo `your_game.dart` - extends `BaseGame`, implement:
    - `validateRoleSetup()`
    - `buildPhases()`
    - `buildRoundPhases()`
    - `checkWinCondition()`
4. Đăng ký vào `GameRegistry._games`

## Setup

```bash
flutter pub get
flutter run
```

## Roles Ma Sói hiện có

| Role | Team | Đêm | Mô tả |
|------|------|-----|--------|
| 👨‍🌾 Dân Làng | Dân | ❌ | Bỏ phiếu ban ngày |
| 🐺 Ma Sói | Sói | ✅ (#2) | Giết mỗi đêm |
| 🔮 Tiên Tri | Dân | ✅ (#3) | Xem bài 1 người |
| 🧪 Phù Thủy | Dân | ✅ (#4) | Cứu/giết 1 lần |
| 🏹 Thợ Săn | Dân | ❌ | Bắn khi chết |
| 🤪 Thằng Ngốc | Dân | ❌ | Lộ bài nếu bị vote |
| 🛡️ Hiệp Sĩ | Dân | ✅ (#1) | Bảo vệ 1 người/đêm |

## TODO

- [ ] Âm thanh (nhạc đêm, ngày)
- [ ] Animation chuyển phase (fade night/day)
- [ ] Lưu lịch sử game
- [ ] Custom phase timer duration
- [ ] Thêm game mới (Coup, One Night Ultimate Werewolf)