import 'package:flutter_test/flutter_test.dart';
import 'package:gangho_ilji/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test('content artwork mappings cover all seven areas', () {
    const areas = [
      'luoyang',
      'bamboo',
      'blackwind',
      'shanxi',
      'yunnan',
      'blood',
      'demon',
    ];
    for (final id in areas) {
      expect(app.areaArtwork(id), isNotNull);
      expect(app.bossArtwork(id), isNotNull);
      expect(app.enemyArtwork(id), contains('assets/images/'));
    }
    expect(app.gearArtwork('무기'), endsWith('item_sword.png'));
    expect(app.gearArtwork('머리'), endsWith('item_helmet.png'));
    expect(app.gearArtwork('목걸이'), endsWith('item_jade_pendant.png'));
    expect(app.gearArtwork('옥패'), endsWith('item_jade_pendant.png'));
    expect(app.gearArtwork('의복'), endsWith('item_armor.png'));
  });

  test('unknown content falls back safely', () {
    expect(app.areaArtwork('unknown'), isNull);
    expect(app.bossArtwork('unknown'), isNull);
    expect(app.enemyArtwork('unknown'), endsWith('enemy_bandit.png'));
  });

  test('boss victory unlocks the next area in the local progression loop', () {
    final game = app.Game();
    game.areas.addAll([
      app.Area('a0', '첫 길', '시험의 길', 1, ['들개'], '첫 수문장', 0),
      app.Area('a1', '다음 길', '이어지는 길', 2, ['들개'], '다음 수문장', 0),
    ]);
    game.enemies = [
      {'name': '들개', 'hp': 10, 'attack': 1},
    ];
    game.bossData = [
      {'name': '첫 수문장', 'hp': 1, 'attack': 1},
    ];
    game.events.add(
      app.StoryEvent('시험', '짧은 기연', [
        {'text': '지나간다', 'effect': 'none', 'value': 0},
      ]),
    );
    game.playing = true;
    game.ready = true;
    game.challenge();

    expect(game.fightingBoss, isTrue);
    expect(game.foe, '첫 수문장');
    game.fight();

    expect(game.bosses, contains('a0'));
    expect(game.unlocked, 1);
    expect(game.fightingBoss, isFalse);
  });

  test('equipment replacement and lock state protect inventory items', () {
    final game = app.Game();
    final first = app.Gear('first', '낡은 검', '무기', '범품', 80, 5, 1);
    final upgrade = app.Gear('upgrade', '청강검', '무기', '양품', 92, 12, 3);
    game.playing = true;
    game.bag.addAll([first, upgrade]);

    game.equip(first);
    expect(game.worn.single.id, 'first');
    expect(game.bag.any((item) => item.id == 'first'), isFalse);

    game.equip(upgrade);
    expect(game.worn.single.id, 'upgrade');
    expect(game.bag.any((item) => item.id == 'first'), isTrue);

    final protectedGear = game.bag.singleWhere((item) => item.id == 'first');
    game.lock(protectedGear);
    final silverBefore = game.silver;
    game.breakGear(protectedGear);
    expect(game.bag.any((item) => item.id == 'first'), isTrue);
    expect(game.silver, silverBefore);

    game.lock(protectedGear);
    game.breakGear(protectedGear);
    expect(game.bag.any((item) => item.id == 'first'), isFalse);
    expect(game.silver, greaterThan(silverBefore));
  });

  test('martial slots and meridian nodes affect combat summaries', () {
    final game = app.Game();
    game.skills.addAll(
      List.generate(
        6,
        (index) => app.Skill(
          'skill$index',
          '초식 $index',
          '검법',
          '범품',
          1.2,
          3,
          '시험용 무공',
        ),
      ),
    );
    game.activeSkills.clear();
    final masteryBefore = game.mastery;
    for (var index = 0; index < 5; index++) {
      game.skill('skill$index');
    }
    game.skill('skill5');

    expect(game.activeSkills.length, 5);
    expect(game.mastery, masteryBefore + 40);
    expect(game.activeSkills, isNot(contains('skill5')));

    game.nodePoints = 3;
    final attackBefore = game.attack;
    final defenseBefore = game.defense;
    final criticalBefore = game.critical;
    expect(game.canOpen(0), isTrue);
    game.open(0);
    expect(game.attack, attackBefore + 3);
    expect(game.canOpen(1), isTrue);
    game.open(1);
    expect(game.defense, defenseBefore + 2);
    game.open(2);
    expect(game.critical, criticalBefore + 2);
  });
}
