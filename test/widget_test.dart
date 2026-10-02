import 'package:flutter_test/flutter_test.dart';
import 'package:match_manager/app/data/models/board_model.dart';
import 'package:match_manager/app/data/models/member_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BoardModel and MemberModel JSON serialization test for Mess Manager', () {
    final member = MemberModel(
      id: 'm1',
      name: 'Noman',
      phone: '01700000000',
      role: MemberRole.manager,
      joinedAt: DateTime.now(),
    );

    final board = BoardModel(
      id: 'b1',
      title: 'Dhanmondi Bachelor Mess 2026',
      sportType: 'bachelor_mess',
      description: 'Test bachelor mess',
      boardCode: 'MESS-1234',
      managerId: 'm1',
      managerName: 'Noman',
      themeColorValue: 0xFF059669,
      createdAt: DateTime.now(),
      members: [member],
    );

    final json = board.toJson();
    final restored = BoardModel.fromJson(json);

    expect(restored.id, 'b1');
    expect(restored.title, 'Dhanmondi Bachelor Mess 2026');
    expect(restored.members.length, 1);
    expect(restored.members.first.name, 'Noman');
    expect(restored.members.first.role, MemberRole.manager);
  });
}
