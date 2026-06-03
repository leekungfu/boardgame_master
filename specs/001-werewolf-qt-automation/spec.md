# Feature Specification: Werewolf QT Automation

**Feature Branch**: `001-werewolf-qt-automation`

**Created**: 2026-05-31

**Status**: Draft

**Input**: User description: "Xem lại codebase của project này và chỉnh sửa hợp lý để phục vụ nhu cầu quản trò cho game bài ma sói, mục đích là giúp bất kì ai cũng có thể trở thành quản trò mà không cần phải hiểu trò chơi, giúp họ hết sức tự động hóa có thể."

---

## Context

Đây là ứng dụng **chỉ dành cho một người duy nhất: Quản Trò (QT)**. Người chơi không nhìn thấy màn hình và không tương tác với ứng dụng — họ ngồi thành vòng tròn, chơi bằng bài vật lý ngoài đời thực. QT cầm điện thoại và điều phối toàn bộ trận đấu.

Trước đây, QT phải: thuộc luật chơi, nhớ thứ tự gọi vai từng đêm, nhớ ai còn sống, biết nói gì vào từng thời điểm, và tự tính xem tối hôm nay ai chết. Điều này khiến người mới không thể làm QT.

**Vai trò của ứng dụng**: Thay thế hoàn toàn trí nhớ và kiến thức luật của QT. App như một cuốn kịch bản có tương tác — QT chỉ cần đọc những gì app hiện ra và ghi nhận kết quả từng bước. App tự xử lý mọi logic phức tạp phía sau.

The app already has a working skeleton: game selection → player setup → role assignment → game master screen (phase-by-phase navigation). However, a first-time moderator (QT) using the app today still needs to:

- Manually pick and distribute roles without guidance
- Remember which special roles are still alive each night
- Mentally track Witch potion usage, Bodyguard protection restrictions, Hunter trigger, Fool immunity
- Decide what to say to players at each step
- Manually determine when the win condition is met

This feature closes those gaps so that **zero prior knowledge of Werewolf rules is required** to run a complete game session.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Auto Role Distribution (Priority: P1)

A first-time QT enters 8 player names and wants the app to suggest which roles to give everyone without needing to understand game balance.

**Why this priority**: Role setup is the first blocker before a game can begin. Without guidance, a new QT either delays the game or creates unbalanced setups that aren't fun.

**Independent Test**: Can be fully tested by entering 8 players, tapping "Auto-distribute roles," and verifying every player receives a role — producing a valid, balanced setup with no further QT input.

**Acceptance Scenarios**:

1. **Given** 8 players with no roles assigned, **When** the QT taps "Auto-distribute", **Then** the app assigns balanced roles (e.g., 2 Wolves, 1 Seer, 1 Witch, 1 Bodyguard, 3 Villagers) and displays a summary for review.
2. **Given** an auto-distributed set, **When** the QT swaps one player's role manually, **Then** the app re-validates and shows updated balance status (e.g., "2 Wolves vs 6 Villagers — balanced").
3. **Given** only 5 players, **When** auto-distribute is triggered, **Then** the app selects a minimal valid preset (1 Wolf, 1 Seer, 3 Villagers).
4. **Given** 12 players, **When** auto-distribute is triggered, **Then** the app scales roles proportionally and never produces a setup where Wolves equal or outnumber Villagers.

---

### User Story 2 — Guided Night Phase Script (Priority: P1)

Đêm xuống, QT không cần nhớ gì cả. App hiện từng bước một, kèm kịch bản lời nói cụ thể để QT đọc to cho người chơi nghe (người chơi nhắm mắt, không thấy màn hình). QT chỉ đọc và gõ kết quả — không cần biết luật.

**Why this priority**: Đêm là pha phức tạp nhất, dễ nhầm nhất. Gọi sai thứ tự hoặc quên một vai phá hỏng cả trận.

**Independent Test**: Bắt đầu game, chuyển sang đêm đầu. Xác minh app hiện 4 bước đúng thứ tự, mỗi bước có kịch bản lời nói riêng, chỉ bao gồm vai còn sống.

**Acceptance Scenarios**:

1. **Given** game đang chạy với Hiệp Sĩ, Ma Sói, Tiên Tri, và Phù Thủy còn sống, **When** đêm bắt đầu, **Then** app hiện 4 bước đúng thứ tự (Hiệp Sĩ → Ma Sói → Tiên Tri → Phù Thủy), mỗi bước có đoạn văn kịch bản QT đọc to (ví dụ: "Hiệp Sĩ hãy mở mắt và chỉ vào người bạn muốn bảo vệ đêm nay...").
2. **Given** Tiên Tri đã chết ở vòng trước, **When** đêm tiếp theo bắt đầu, **Then** bước Tiên Tri không xuất hiện — không cần QT can thiệp.
3. **Given** QT hoàn thành một bước đêm, **When** họ nhấn "Xong", **Then** app chuyển sang bước tiếp theo và đánh dấu bước cũ đã hoàn thành.
4. **Given** tất cả bước đêm đã xong, **When** QT nhấn "Kết thúc đêm", **Then** app chuyển sang pha công bố sáng hôm sau.

---

### User Story 3 — Night Action Recording (Priority: P1)

Trong từng bước đêm, QT quan sát tín hiệu của người chơi (ví dụ: Ma Sói chỉ tay vào nạn nhân trong bóng tối) và ghi nhận vào app ngay tại chỗ. Khi sáng đến, app tự tổng hợp tất cả tương tác và thông báo kết quả — QT không cần tự tính toán bất cứ điều gì.

**Why this priority**: Nếu phải tự nhớ "Ma Sói chọn A, Phù Thủy cứu A, vậy sáng không ai chết", QT cực kỳ dễ nhầm và làm chậm trò chơi.

**Independent Test**: Ghi nhận Ma Sói chọn Người A, Phù Thủy dùng bình cứu cho Người A. Vào sáng, xác minh app thông báo "Không ai chết đêm qua" mà không cần QT tự tính.

**Acceptance Scenarios**:

1. **Given** Ma Sói chọn Người A và Phù Thủy dùng bình cứu cho Người A, **When** sáng bắt đầu, **Then** app tự tổng hợp và hiển thị "Không có ai chết đêm nay" — QT chỉ cần đọc to thông báo này.
2. **Given** Ma Sói chọn Người B và không ai cứu, **When** sáng bắt đầu, **Then** app thông báo Người B đã chết và cập nhật danh sách còn sống ngay lập tức.
3. **Given** Hiệp Sĩ bảo vệ Người C và Ma Sói cũng chọn Người C, **When** sáng bắt đầu, **Then** app tự giải quyết bảo vệ và thông báo không ai chết — QT không cần biết rule này tồn tại.
4. **Given** Phù Thủy đã dùng bình độc ở vòng trước, **When** bước Phù Thủy xuất hiện ở vòng sau, **Then** tùy chọn bình độc bị ẩn/mờ — QT không thể ghi nhận một bình đã hết.

---

### User Story 4 — Day Voting Management (Priority: P2)

During the day phase, the QT uses the app to manage nominations and track votes against each suspect, then records the execution result with a single tap.

**Why this priority**: New QTs often lose track of vote counts or forget who was nominated. This feature removes the cognitive load of vote tallying.

**Independent Test**: Open day voting with 6 alive players. Nominate 2 suspects and assign votes. Verify the app tallies votes and identifies the player to be executed.

**Acceptance Scenarios**:

1. **Given** 6 alive players, **When** QT nominates 2 suspects and enters vote counts, **Then** the app highlights the player with the most votes as the execution candidate.
2. **Given** a tie vote, **When** vote counts are equal, **Then** the app prompts QT to resolve the tie (options: re-vote, no execution, or random).
3. **Given** the execution target is confirmed, **When** QT taps "Execute", **Then** the player is marked dead, their role is revealed, and the win condition is auto-checked.
4. **Given** the executed player is the Fool, **When** execution is confirmed, **Then** the app announces the Fool immunity rule and does NOT mark the player as dead (first time only).

---

### User Story 5 — Special Ability Tracker (Priority: P2)

The app passively tracks consumable abilities (Witch's two potions, Fool's one-time immunity, Hunter's death trigger) and automatically prompts the QT when these abilities become relevant.

**Why this priority**: Forgetting a triggered ability (e.g., Hunter dying without getting a shot) is one of the most common QT mistakes.

**Independent Test**: Mark the Hunter as dead during night. Verify the app immediately prompts "Thợ Săn vừa chết — họ được bắn 1 người. Chọn mục tiêu."

**Acceptance Scenarios**:

1. **Given** Hunter is killed (by Wolves or execution), **When** the death is recorded, **Then** the app immediately shows a target picker for the Hunter's retaliatory shot before continuing.
2. **Given** Witch has used the save potion in Round 1, **When** Witch's night step appears in Round 2+, **Then** the save option is hidden and only the kill option is shown (if not yet used).
3. **Given** Fool was vote-executed for the first time, **When** execution is confirmed, **Then** the app reveals the Fool's role to all, skips the death, and marks the immunity as consumed.
4. **Given** Fool is killed by any means (not vote), **When** the death is recorded, **Then** Fool dies normally (immunity only applies to execution).

---

### User Story 6 — QT Reference Card During Game (Priority: P3)

Trong lúc chơi, QT cần nhanh chóng tra cứu kỹ năng của một vai bất kỳ mà không cần rời khỏi màn hình game hiện tại. Ví dụ: QT quên Thằng Ngốc hoạt động thế nào, cần tra ngay trong 5 giây mà không phá vỡ luồng game.

**Why this priority**: Người chơi đôi khi hỏi QT về luật — QT cần tra cứu nhanh ngay trên màn hình mà không cần thoát game hay dùng điện thoại khác.

**Independent Test**: Trong màn hình game đang chạy, mở tra cứu vai, chọn "Thằng Ngốc", xác minh mô tả kỹ năng hiện ra đúng, đóng lại và màn hình game không thay đổi trạng thái.

**Acceptance Scenarios**:

1. **Given** game đang chạy, **When** QT nhấn biểu tượng tra cứu vai, **Then** một panel trượt lên hiển thị danh sách tất cả vai trong game hiện tại kèm mô tả kỹ năng ngắn gọn bằng tiếng Việt.
2. **Given** panel tra cứu đang mở, **When** QT chọn một vai, **Then** app hiện mô tả đầy đủ kỹ năng của vai đó, trạng thái còn sống/đã chết, và nếu có — số lần dùng kỹ năng còn lại (ví dụ: Phù Thủy còn bình cứu không).
3. **Given** QT xem xong, **When** họ đóng panel, **Then** màn hình game quay lại đúng bước đang dở, không mất bất kỳ dữ liệu nào.

---

### Edge Cases

- What happens when only the minimum 5 players are present and not all desired roles can fit?
- How does the app handle a mid-game crash or accidental app close — is session state preserved?
- What if the QT mistakenly marks a player dead and wants to undo?
- What happens when all Wolves die before any Villagers — is win condition detected immediately?
- What if the Hunter is killed by the Witch's poison — does the Hunter ability still trigger?

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide at least one balanced role preset per player count (5–20 players) that can be applied with a single action.
- **FR-002**: System MUST display narration text for QT to read aloud at each night step, specific to the role being called.
- **FR-003**: System MUST display only the night steps for roles that are currently alive, dynamically rebuilding the checklist each round.
- **FR-004**: System MUST provide input controls during each night step for QT to record the action outcome (kill target, save/poison target, bodyguard target, seer result).
- **FR-005**: System MUST auto-resolve night interactions (protection vs. kill, save vs. kill) before displaying the morning announcement.
- **FR-006**: System MUST support nomination and vote-count entry for the day execution vote.
- **FR-007**: System MUST auto-check win condition after every death (night or day) and surface the result immediately.
- **FR-008**: System MUST track Witch potion usage (save and kill each usable once per game) and visually disable unavailable options.
- **FR-009**: System MUST interrupt the normal flow and prompt QT to resolve the Hunter's retaliatory shot whenever the Hunter dies.
- **FR-010**: System MUST implement Fool immunity: first vote-execution of the Fool reveals role and skips death; subsequent deaths proceed normally.
- **FR-011**: System MUST provide an in-game role reference panel that QT can open at any time to view the skill description and current ability state of any role in the active game, without disrupting game state.
- **FR-012**: System MUST allow QT to undo the most recent death marking within the same phase.
- **FR-013**: System MUST persist game state so that closing and reopening the app within the same session restores the exact game state.

### Key Entities *(include if feature involves data)*

- **GameSession**: Tracks round, phase, player states, game result. Extended with night action log and ability usage flags.
- **NightActionRecord**: Per-round record of Wolf target, Bodyguard target, Witch save target, Witch kill target, Seer target and result.
- **AbilityState**: Per-role, per-game consumable flag (Witch save used, Witch kill used, Fool immunity triggered, Hunter shot pending).
- **RolePreset**: A named set of role counts indexed by player count, used for auto-distribution.
- **VoteTally**: Per-day record of nominations and vote counts.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time QT with no prior Werewolf knowledge can run a complete 5-player game from setup to result in under 15 minutes.
- **SC-002**: Zero game-breaking errors (wrong role called at night, missed death resolution, incorrect win condition) occur when QT follows only the in-app prompts.
- **SC-003**: Role setup time drops from manual assignment (estimated 3–5 minutes for 8 players) to under 30 seconds using auto-distribution.
- **SC-004**: All triggered special abilities (Hunter shot, Fool immunity, Witch potion exhaustion) are surfaced to the QT without the QT needing to remember them.
- **SC-005**: 90% of QT actions during a game session require at most one tap to complete (no multi-step mental calculation required).
- **SC-006**: Session state survives an app restart during an active game round without data loss.

---

## Assumptions

- **App là công cụ độc quyền của QT**: Người chơi không nhìn thấy màn hình, không chạm vào điện thoại. Họ chơi bằng bài vật lý ngoài đời thực. App chỉ là "não" của QT.
- **Giao bài cho người chơi là việc vật lý**: QT tự phát bài (thẻ bài thật hoặc mảnh giấy) hoặc nói riêng cho từng người. App ghi nhận phân công vai để QT tham chiếu trong game — không cần người chơi xác nhận qua app.
- The existing 7 roles (Villager, Werewolf, Seer, Witch, Hunter, Fool, Bodyguard) cover the initial scope; new roles are out of scope for this feature.
- Bodyguard restriction (cannot protect same person two nights in a row) is enforced by the app automatically.
- Internet connectivity is not required; all logic is local to the device.
- The app is used in portrait orientation on a phone (existing constraint).
- The Witch may only see the kill outcome of a night before deciding to save — this order is preserved by placing the Witch step last among night roles.
- A game session is "same session" if the app process was not killed; background/foreground transitions preserve in-memory state. Full crash recovery (FR-013) uses local storage.
