# Research: Werewolf QT Automation

**Phase 0 output** | **Date**: 2026-05-31

---

## 1. Local State Persistence in Flutter

**Decision**: `shared_preferences` for JSON string storage.

**Rationale**: The only persistence requirement is one active game session (a flat JSON blob of ~1–5 KB). `shared_preferences` is the lightest-weight option, already well-supported in Flutter's ecosystem, and adds no schema migration complexity. The alternative (`hive`, `sqflite`) would be over-engineered for a single-key store.

**Alternatives considered**:
- `hive_flutter` — fast binary NoSQL, better for large datasets; overkill for one session object.
- `sqflite` — relational DB; unnecessary for unstructured session state.
- `path_provider` + JSON file — works but more boilerplate than `shared_preferences`.

**Implementation note**: On every `GameNotifier` state mutation, serialize the full `GameSession` (including `AbilityState` and `NightActionRecord` list) to a JSON string and write to key `active_game_session`. On app launch, read and deserialize. Key cleared on `endGame()`.

---

## 2. Night Action Resolution Logic

**Decision**: Rule-based priority chain computed at morning boundary.

**Rules** (applied in order):
1. Bodyguard target set → any Wolf kill on that target is blocked (Wolf kill = null).
2. Witch save target set → any Wolf kill on that target is blocked (takes precedence after step 1 check, but save overrides even if Bodyguard did not protect).
3. Witch kill target set → that player dies (independent of Wolf kill).
4. Result: `List<String> died = [wolfKill (if not blocked), witchKillTarget (if set)]`.

**Edge case — Hunter**:
- If any player in `died` has role `hunter`, immediately set `AbilityState.hunterShotPending = true` and surface the Hunter target picker before advancing to morning announcement.

**Edge case — Fool**:
- Fool immunity applies only to day-vote execution, not to night deaths. If Fool is in `died`, mark them dead normally.

**Rationale**: Stateless rule chain — no circular dependencies, easy to unit test.

---

## 3. Werewolf Role Preset Table (5–20 players)

**Decision**: Hardcoded `Map<int, RolePreset>` in `werewolf_presets.dart`.

**Balance principle**: Wolves ≤ floor(N/3), always at least 1. Special roles scale with player count to keep Villager team's information advantage proportional.

| Players | Wolves | Seer | Witch | Bodyguard | Hunter | Fool | Villagers |
|---------|--------|------|-------|-----------|--------|------|-----------|
| 5       | 1      | 1    | 0     | 0         | 0      | 0    | 3         |
| 6       | 1      | 1    | 1     | 0         | 0      | 0    | 3         |
| 7       | 2      | 1    | 1     | 0         | 0      | 0    | 3         |
| 8       | 2      | 1    | 1     | 1         | 0      | 0    | 3         |
| 9       | 2      | 1    | 1     | 1         | 1      | 0    | 3         |
| 10      | 3      | 1    | 1     | 1         | 1      | 0    | 3         |
| 11      | 3      | 1    | 1     | 1         | 1      | 1    | 3         |
| 12      | 3      | 1    | 1     | 1         | 1      | 1    | 4         |
| 13      | 4      | 1    | 1     | 1         | 1      | 1    | 4         |
| 14      | 4      | 1    | 1     | 1         | 1      | 1    | 5         |
| 15      | 5      | 1    | 1     | 1         | 1      | 1    | 5         |
| 16      | 5      | 1    | 1     | 1         | 1      | 1    | 6         |
| 17      | 5      | 1    | 1     | 1         | 1      | 1    | 7         |
| 18      | 6      | 1    | 1     | 1         | 1      | 1    | 7         |
| 19      | 6      | 1    | 1     | 1         | 1      | 1    | 8         |
| 20      | 6      | 1    | 1     | 1         | 1      | 1    | 9         |

**Rationale**: Keeps Wolves at ~1/3 of players. At 5–6 players the Witch is omitted to avoid giving Villagers too much power. Villagers never drop below 3 to ensure meaningful discussion.

---

## 4. Night Phase Script Text (Narration Templates)

**Decision**: Static strings stored directly in `GamePhase.scriptText`, built per-round.

**Template per role** (Vietnamese, read aloud by QT):

| Role | Script |
|------|--------|
| Intro | "Tất cả người chơi nhắm mắt lại. Đêm buông xuống làng..." |
| Bodyguard | "Hiệp Sĩ, hãy mở mắt. Chỉ vào người bạn muốn bảo vệ đêm nay. (Không được chọn người bạn đã chọn đêm qua)" |
| Wolves | "Ma Sói, hãy mở mắt. Nhận mặt đồng đội. Thống nhất chọn 1 nạn nhân và chỉ cho QT thấy." |
| Seer | "Tiên Tri, hãy mở mắt. Chỉ vào người bạn muốn kiểm tra. QT sẽ ra hiệu: 👍 Dân / 👎 Sói." |
| Witch | "Phù Thủy, hãy mở mắt. [QT chỉ vào người bị sói chọn]. Bạn có dùng bình cứu không? [nếu còn]. Bạn có dùng bình độc không? [nếu còn]. Nhắm mắt lại." |
| Morning (no death) | "Tất cả mở mắt. Đêm qua bình yên — không ai chết." |
| Morning (deaths) | "Tất cả mở mắt. Đêm qua, {tên} đã không thức dậy nữa." |

---

## 5. Day Voting Flow

**Decision**: QT manually enters vote counts per nominated player; app highlights winner.

**Rationale**: Physical game — players raise hands or vote by show. QT counts and enters the number. No automated vote collection possible (players not on app).

**Tie resolution options presented to QT**:
1. "Bỏ phiếu lại" (re-vote) — most common house rule
2. "Không xử tử hôm nay" (skip execution) — safe default
3. "Chọn ngẫu nhiên" (random) — app picks one tied player randomly

---

## 6. Bodyguard Same-Night Restriction

**Decision**: Track `lastBodyguardTarget` in `AbilityState`; disable that player in the picker UI on subsequent rounds.

**Rule**: Bodyguard cannot choose the same person two consecutive nights. After each night, `lastBodyguardTarget` is updated. The restriction resets if the Bodyguard dies.

---

## 7. Seer Night Result Recording

**Decision**: QT records seer result (wolf or villager) for reference. Not shown to other players. Stored in `NightActionRecord.seerResult` for QT's own tracking across rounds.

**UX**: During Seer step, QT sees the target player's actual role (only on QT device) and records the outcome with one tap. The result is stored and visible in the role reference panel for that round.

---

## 8. Android Studio Configuration

**Decision**: Rely on existing `android/local.properties` (already correct) + Flutter plugin run configuration.

**Findings**:
- `android/local.properties` already has correct `sdk.dir` and `flutter.sdk` paths for this machine.
- No Kotlin/Gradle changes needed for the new features (`shared_preferences` auto-configures via Flutter plugin system).
- Android Studio run configuration: standard Flutter "Run/Debug Configuration" targeting `lib/main.dart`.
- `shared_preferences` requires minSdkVersion ≥ 16 (default Flutter projects use 21+ — no issue).

All setup steps documented in `quickstart.md`.
