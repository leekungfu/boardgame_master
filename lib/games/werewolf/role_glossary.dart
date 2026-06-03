// GENERATED from the standardized role list. Display-only glossary for the
// role reference panel — playable mechanics live in werewolf_roles.dart.
import '../../models/role.dart';

class GlossaryRole {
  final String id;
  final String nameEn;
  final String nameVi;
  final RoleTeam team;
  final String description;
  const GlossaryRole(this.id, this.nameEn, this.nameVi, this.team, this.description);
}

class RoleGlossary {
  RoleGlossary._();
  static const List<GlossaryRole> all = [
    GlossaryRole('apprentice_seer', 'Apprentice Seer', 'Tiên tri tập sự', RoleTeam.villager, 'Thuộc phe dân làng. Khi Tiên tri chính chết, Apprentice Seer có thể thay thế và bắt đầu được soi vai người chơi vào ban đêm.'),
    GlossaryRole('aura_seer', 'Aura Seer', 'Tiên tri hào quang', RoleTeam.villager, 'Thuộc phe dân làng. Mỗi đêm có thể kiểm tra một người chơi để biết người đó có năng lực đặc biệt hay không.'),
    GlossaryRole('bodyguard', 'Bodyguard', 'Bảo vệ', RoleTeam.villager, 'Thuộc phe dân làng. Mỗi đêm chọn một người để bảo vệ khỏi bị giết. Tùy luật, Bodyguard có thể chết thay người được bảo vệ.'),
    GlossaryRole('cupid', 'Cupid', 'Thần tình yêu', RoleTeam.villager, 'Thuộc phe dân làng. Đêm đầu tiên chọn hai người chơi trở thành cặp đôi. Nếu một người chết, người còn lại cũng chết theo.'),
    GlossaryRole('diseased', 'Diseased', 'Người bệnh', RoleTeam.villager, 'Thuộc phe dân làng. Nếu bị Ma Sói giết vào ban đêm, Ma Sói sẽ bị mất lượt giết ở đêm tiếp theo.'),
    GlossaryRole('ghost', 'Ghost', 'Con ma', RoleTeam.villager, 'Thuộc phe dân làng. Sau khi chết vẫn có thể để lại manh mối hoặc tương tác hạn chế tùy luật chơi.'),
    GlossaryRole('hunter', 'Hunter', 'Thợ săn', RoleTeam.villager, 'Thuộc phe dân làng. Khi chết, có thể chọn bắn chết thêm một người chơi khác.'),
    GlossaryRole('idiot', 'Idiot', 'Thằng ngốc', RoleTeam.villager, 'Thuộc phe dân làng. Nếu bị treo cổ, thường không chết nhưng mất quyền biểu quyết trong các vòng sau.'),
    GlossaryRole('lycan', 'Lycan', 'Người hóa sói', RoleTeam.villager, 'Thuộc phe dân làng nhưng khi bị Tiên tri soi sẽ hiện là Ma Sói.'),
    GlossaryRole('magician', 'Magician', 'Nhà ảo thuật', RoleTeam.villager, 'Thuộc phe dân làng. Có thể tạo hiệu ứng đánh lạc hướng hoặc thay đổi kết quả kiểm tra tùy luật của bộ bài.'),
    GlossaryRole('martyr', 'Martyr', 'Tử vì đạo', RoleTeam.villager, 'Thuộc phe dân làng. Có thể hy sinh bản thân để cứu một người chơi khác khỏi bị chết.'),
    GlossaryRole('mason', 'Mason', 'Hội Tam Điểm', RoleTeam.villager, 'Thuộc phe dân làng. Các Mason biết nhau là dân làng ngay từ đầu hoặc trong đêm đầu tiên.'),
    GlossaryRole('mayor', 'Mayor', 'Thị trưởng', RoleTeam.villager, 'Thuộc phe dân làng. Phiếu bầu của Mayor thường có giá trị lớn hơn người chơi bình thường.'),
    GlossaryRole('old_hag', 'Old Hag', 'Phù thủy già', RoleTeam.villager, 'Thuộc phe dân làng. Mỗi đêm chọn một người bị đưa ra khỏi làng trong ngày hôm sau, khiến người đó không được nói chuyện hoặc bỏ phiếu.'),
    GlossaryRole('old_man', 'Old Man', 'Ông già', RoleTeam.villager, 'Thuộc phe dân làng. Có thể có điều kiện sống sót đặc biệt hoặc giới hạn năng lực của làng khi chết, tùy luật chơi.'),
    GlossaryRole('p_i', 'P.I.', 'Thám tử', RoleTeam.villager, 'Thuộc phe dân làng. Có thể điều tra một nhóm hoặc một người để tìm dấu hiệu liên quan đến Ma Sói.'),
    GlossaryRole('pacifist', 'Pacifist', 'Người yêu hòa bình', RoleTeam.villager, 'Thuộc phe dân làng. Luôn phải bỏ phiếu không treo cổ hoặc không được bỏ phiếu giết người khác, tùy luật chơi.'),
    GlossaryRole('priest', 'Priest', 'Thầy tu', RoleTeam.villager, 'Thuộc phe dân làng. Có thể bảo vệ hoặc ban phước cho một người chơi, tùy luật có thể ngăn bị giết hoặc ngăn biến đổi phe.'),
    GlossaryRole('prince', 'Prince', 'Hoàng tử', RoleTeam.villager, 'Thuộc phe dân làng. Nếu bị làng treo cổ, Prince thường được lật vai và sống sót.'),
    GlossaryRole('seer', 'Seer', 'Tiên tri', RoleTeam.villager, 'Thuộc phe dân làng. Mỗi đêm chọn một người chơi để kiểm tra xem người đó có phải Ma Sói hay không.'),
    GlossaryRole('spellcaster', 'Spellcaster', 'Người phù phép', RoleTeam.villager, 'Thuộc phe dân làng. Mỗi đêm có thể chọn một người bị câm trong ngày hôm sau, người đó không được nói chuyện.'),
    GlossaryRole('tough_guy', 'Tough Guy', 'Người cứng cỏi', RoleTeam.villager, 'Thuộc phe dân làng. Nếu bị Ma Sói tấn công, thường không chết ngay mà chết vào ngày hôm sau.'),
    GlossaryRole('troublemaker', 'Troublemaker', 'Kẻ phá rối', RoleTeam.villager, 'Thuộc phe dân làng. Có thể gây rối quá trình bỏ phiếu hoặc buộc làng có thêm lượt treo cổ, tùy luật chơi.'),
    GlossaryRole('villager', 'Villager', 'Dân làng', RoleTeam.villager, 'Thuộc phe dân làng. Không có năng lực ban đêm, mục tiêu là tìm và treo cổ toàn bộ Ma Sói.'),
    GlossaryRole('witch', 'Witch', 'Phù thủy', RoleTeam.villager, 'Thuộc phe dân làng. Thường có thuốc cứu và thuốc độc, có thể cứu một người bị giết hoặc giết một người khác.'),
    GlossaryRole('werewolf', 'Werewolf', 'Ma sói', RoleTeam.werewolf, 'Thuộc phe Ma Sói. Mỗi đêm cùng các Ma Sói khác chọn một người để giết. Mục tiêu là loại bỏ phe dân làng.'),
    GlossaryRole('wolf_cub', 'Wolf Cub', 'Sói con', RoleTeam.werewolf, 'Thuộc phe Ma Sói. Nếu Wolf Cub chết, Ma Sói thường được giết hai người trong đêm tiếp theo.'),
    GlossaryRole('lone_wolf', 'Lone Wolf', 'Sói cô đơn', RoleTeam.werewolf, 'Thuộc phe Ma Sói hoặc phe riêng tùy luật. Thường thắng khi là Ma Sói cuối cùng còn sống hoặc đạt điều kiện riêng.'),
    GlossaryRole('minion', 'Minion', 'Tay sai của sói', RoleTeam.werewolf, 'Thuộc phe Ma Sói nhưng không phải Ma Sói. Biết Ma Sói là ai và cố gắng giúp Ma Sói thắng.'),
    GlossaryRole('sorcerer', 'Sorcerer', 'Pháp sư sói', RoleTeam.werewolf, 'Thuộc phe Ma Sói. Mỗi đêm có thể tìm Tiên tri hoặc người có năng lực đặc biệt để hỗ trợ Ma Sói.'),
    GlossaryRole('cursed', 'Cursed', 'Kẻ bị nguyền rủa', RoleTeam.villager, 'Ban đầu thuộc phe dân làng. Nếu bị Ma Sói tấn công vào ban đêm, không chết mà biến thành Ma Sói.'),
    GlossaryRole('doppelganger', 'Doppelganger', 'Kẻ nhân bản', RoleTeam.neutral, 'Đêm đầu tiên chọn một người chơi. Khi người đó chết hoặc theo điều kiện luật chơi, Doppelganger nhận vai hoặc phe của người đó.'),
    GlossaryRole('drunk', 'Drunk', 'Kẻ say rượu', RoleTeam.neutral, 'Không biết vai thật của mình lúc đầu. Sau một số ngày hoặc theo hiệu lệnh quản trò, Drunk được đổi sang vai thật.'),
    GlossaryRole('cult_leader', 'Cult Leader', 'Trưởng giáo phái', RoleTeam.neutral, 'Thuộc phe thứ ba. Mỗi đêm có thể chiêu mộ người chơi vào giáo phái. Thắng khi giáo phái chiếm đa số hoặc đạt điều kiện riêng.'),
    GlossaryRole('hoodlum', 'Hoodlum', 'Du côn', RoleTeam.neutral, 'Thuộc phe thứ ba. Đầu game chọn vài mục tiêu. Hoodlum thắng nếu các mục tiêu đó chết và bản thân còn sống.'),
    GlossaryRole('tanner', 'Tanner', 'Kẻ chán đời', RoleTeam.neutral, 'Thuộc phe thứ ba. Mục tiêu là bị làng treo cổ. Nếu bị treo cổ, Tanner thắng.'),
    GlossaryRole('vampire', 'Vampire', 'Ma cà rồng', RoleTeam.neutral, 'Thuộc phe Ma Cà Rồng. Có thể thay thế hoặc đối đầu với Ma Sói tùy luật. Mục tiêu là loại bỏ các phe khác.'),
    GlossaryRole('teenage_werewolf', 'Teenage Werewolf', 'Sói tuổi teen', RoleTeam.werewolf, 'Vai Ma Sói đặc biệt. Cách hoạt động phụ thuộc luật mở rộng, thường có điều kiện hoặc hạn chế riêng khi thức dậy/giết người.'),
    GlossaryRole('big_bad_wolf', 'Big Bad Wolf', 'Sói đại ca', RoleTeam.werewolf, 'Vai Ma Sói mở rộng. Thường có năng lực mạnh hơn Ma Sói thường, ví dụ giết thêm hoặc có điều kiện giết đặc biệt.'),
    GlossaryRole('dire_wolf', 'Dire Wolf', 'Sói dữ', RoleTeam.werewolf, 'Vai Ma Sói mở rộng. Có thể có sức mạnh hoặc điều kiện giết đặc biệt tùy luật của bản mở rộng.'),
    GlossaryRole('fruit_wolf', 'Fruit Wolf', 'Sói ăn chay', RoleTeam.werewolf, 'Vai Ma Sói mở rộng. Thường thuộc phe sói nhưng có hạn chế hoặc hành vi hài hước liên quan đến việc không giết người.'),
    GlossaryRole('fang_face', 'Fang Face', 'Mặt nanh', RoleTeam.werewolf, 'Vai mở rộng liên quan đến phe sói. Có thể có cơ chế nhận diện hoặc biến đổi đặc biệt tùy luật.'),
    GlossaryRole('wolverine', 'Wolverine', 'Chó sói', RoleTeam.neutral, 'Vai mở rộng. Thường có khả năng sống dai hoặc phản công, tùy luật của nhóm chơi.'),
    GlossaryRole('virginia_woolf', 'Virginia Woolf', 'Virginia Woolf', RoleTeam.neutral, 'Vai mở rộng dạng đặc biệt/hài hước. Cách chơi phụ thuộc luật đi kèm bản mở rộng.'),
    GlossaryRole('alpha_wolf', 'Alpha Wolf', 'Sói Alpha', RoleTeam.werewolf, 'Thuộc phe Ma Sói. Có thể biến một người chơi khác thành Ma Sói hoặc thêm Ma Sói vào game, tùy luật.'),
    GlossaryRole('mystic_seer', 'Mystic Seer', 'Tiên tri huyền bí', RoleTeam.villager, 'Thuộc phe dân làng. Có khả năng soi nâng cao hơn Tiên tri thường, ví dụ biết chính xác vai hoặc loại vai.'),
    GlossaryRole('mad_bomber', 'Mad Bomber', 'Kẻ đánh bom', RoleTeam.neutral, 'Vai mở rộng. Có thể đặt bom hoặc gây chết nhiều người theo điều kiện nhất định.'),
    GlossaryRole('revealer', 'Revealer', 'Kẻ khám phá', RoleTeam.villager, 'Thuộc phe dân làng. Có thể lật vai một người chơi hoặc ép công khai thông tin vai, tùy luật.'),
    GlossaryRole('huntress', 'Huntress', 'Nữ thợ săn', RoleTeam.villager, 'Thuộc phe dân làng. Tương tự Hunter, có thể giết một người theo điều kiện nhất định.'),
    GlossaryRole('mentalist', 'Mentalist', 'Nhà tinh thần học', RoleTeam.villager, 'Thuộc phe dân làng. Có thể so sánh hoặc đọc thông tin giữa hai người chơi để suy luận phe.'),
    GlossaryRole('sasquatch', 'Sasquatch', 'Chân to', RoleTeam.neutral, 'Vai mở rộng. Có thể thuộc phe riêng hoặc có điều kiện biến đổi tùy luật chơi.'),
    GlossaryRole('nostradamus', 'Nostradamus', 'Nostradamus', RoleTeam.neutral, 'Vai mở rộng. Có thể đưa ra hoặc nhận thông tin tiên đoán về sự kiện trong game.'),
    GlossaryRole('bloody_mary', 'Bloody Mary', 'Bloody Mary', RoleTeam.neutral, 'Vai mở rộng. Thường có năng lực liên quan đến việc bị gọi tên, trả thù hoặc giết người theo điều kiện.'),
    GlossaryRole('leprechaun', 'Leprechaun', 'Yêu tinh', RoleTeam.neutral, 'Vai mở rộng. Thường có năng lực gây nhiễu, đổi kết quả hoặc tạo may rủi.'),
    GlossaryRole('chupacabra', 'Chupacabra', 'Chupacabra', RoleTeam.neutral, 'Vai mở rộng. Thường là phe riêng hoặc quái vật có khả năng giết độc lập.'),
    GlossaryRole('wolf_man', 'Wolf-man', 'Người sói', RoleTeam.neutral, 'Vai mở rộng. Có thể bị nhìn nhận như sói hoặc biến đổi liên quan đến Ma Sói tùy luật.'),
    GlossaryRole('beholder', 'Beholder', 'Kẻ quan sát', RoleTeam.villager, 'Thuộc phe dân làng. Thường biết Tiên tri là ai, nhưng Tiên tri không biết Beholder.'),
    GlossaryRole('count', 'Count', 'Bá tước', RoleTeam.neutral, 'Vai mở rộng. Có thể liên quan đến phe Ma Cà Rồng hoặc có điều kiện thắng riêng tùy luật.'),
    GlossaryRole('insomniac', 'Insomniac', 'Kẻ mất ngủ', RoleTeam.villager, 'Thuộc phe dân làng. Thức dậy vào ban đêm để biết vai hoặc trạng thái của mình có bị thay đổi không.'),
    GlossaryRole('the_thing', 'The Thing', 'The Thing', RoleTeam.neutral, 'Vai mở rộng. Có thể chạm hoặc tác động âm thầm lên người bên cạnh, tùy luật.'),
    GlossaryRole('dreamwolf', 'Dreamwolf', 'Sói chiêm bao', RoleTeam.werewolf, 'Thuộc phe Ma Sói nhưng thường không thức dậy cùng sói hoặc không biết đồng đội, tùy luật.'),
    GlossaryRole('bogeyman', 'Bogeyman', 'Ông kẹ', RoleTeam.neutral, 'Vai mở rộng. Thường là vai giết người hoặc gây sợ hãi theo điều kiện đặc biệt.'),
    GlossaryRole('frankenstein_s_monster', 'Frankenstein\'s Monster', 'Quái vật Frankenstein', RoleTeam.neutral, 'Vai mở rộng. Có thể được kích hoạt hoặc mạnh dần theo số người chết, tùy luật.'),
    GlossaryRole('the_blob', 'The Blob', 'Chất nhầy', RoleTeam.neutral, 'Vai mở rộng. Có thể lan rộng hoặc hấp thụ người chơi theo điều kiện riêng.'),
    GlossaryRole('zombie', 'Zombie', 'Thây ma', RoleTeam.neutral, 'Vai mở rộng. Có thể quay lại sau khi chết hoặc lây nhiễm người khác, tùy luật.'),
    GlossaryRole('dracula', 'Dracula', 'Dracula', RoleTeam.neutral, 'Vai mở rộng. Thường thuộc phe Ma Cà Rồng, có khả năng cắn hoặc biến đổi người chơi.'),
    GlossaryRole('the_mummy', 'The Mummy', 'Xác ướp', RoleTeam.neutral, 'Vai mở rộng. Có thể nguyền rủa hoặc giết người theo điều kiện riêng.'),
    GlossaryRole('teen_wolf', 'Teen Wolf', 'Sói tuổi teen', RoleTeam.werewolf, 'Vai mở rộng. Có cơ chế đặc biệt liên quan đến phe sói, thường mang tính hài hước hoặc điều kiện riêng.'),
  ];
}
