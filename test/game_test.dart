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
    expect(app.gearArtwork('목걸이'), endsWith('item_necklace.png'));
    expect(app.gearArtwork('옥패'), endsWith('item_jade_tablet.png'));
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

  test('offline rewards clamp to the one-minute and eight-hour boundaries', () {
    final game = app.Game();
    game.areas.add(
      app.Area('a0', '첫 길', '시험의 길', 1, ['들개'], '수문장', 0),
    );
    game.playing = true;
    game.area = 0;
    game.offline = true;
    game.lastSeen = DateTime.now().subtract(const Duration(minutes: 600));
    final silverBefore = game.silver;
    final expBefore = game.exp;

    game.claimOffline();

    expect(game.offline, isFalse);
    expect(game.silver, silverBefore + 480 * 4);
    expect(game.exp, expBefore + (480 * 4 ~/ 2));

    game.offline = true;
    game.lastSeen = DateTime.now();
    final silverAtMinimum = game.silver;
    game.claimOffline();
    expect(game.silver, silverAtMinimum + 4);
  });

  test('local save restores progression into a fresh game instance', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = app.Game();
    await saved.boot();
    saved.start('복원시험자');
    saved.area = 2;
    saved.unlocked = 3;
    saved.level = 17;
    saved.silver = 4321;
    saved.points = 4;
    saved.nodes = {0, 1};
    saved.bag.add(app.Gear('saved-gear', '복원 장비', '머리', '양품', 90, 4, 5));
    await saved.save();

    final restored = app.Game();
    await restored.boot();

    expect(restored.playing, isTrue);
    expect(restored.hero, '복원시험자');
    expect(restored.area, 2);
    expect(restored.unlocked, 3);
    expect(restored.level, 17);
    expect(restored.silver, 4321);
    expect(restored.points, 4);
    expect(restored.nodes, containsAll(<int>[0, 1]));
    expect(restored.bag.any((gear) => gear.id == 'saved-gear'), isTrue);

    saved.dispose();
    restored.dispose();
  });

  test('fate choice applies its effect and exposes a dismissible result', () {
    final game = app.Game();
    final choice = <String, dynamic>{
      'text': '낯선 노인을 돕는다',
      'effect': 'silver',
      'value': 77,
    };
    game.event = app.StoryEvent('갈림길', '비가 내리는 밤', [choice]);
    final silverBefore = game.silver;

    game.resolve(choice);

    expect(game.event, isNull);
    expect(game.eventResult, '낯선 노인을 돕는다');
    expect(game.silver, silverBefore + 77);
    game.dismissEventResult();
    expect(game.eventResult, isNull);
  });

  test('realm breakthroughs honor level, boss, energy, and mastery gates', () {
    final game = app.Game();
    game.level = 10;
    game.bosses = {'a0'};
    game.checkRealm();
    expect(game.realm, '이류');

    game.level = 24;
    game.energy = 60;
    game.bosses = {'a0', 'a1', 'a2'};
    game.checkRealm();
    expect(game.realm, '일류');

    game.level = 40;
    game.kills = 312;
    game.bosses = {'a0', 'a1', 'a2', 'a3', 'a4', 'a5'};
    game.checkRealm();
    expect(game.mastery, greaterThanOrEqualTo(180));
    expect(game.realm, '절정');
  });
}
