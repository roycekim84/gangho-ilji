import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gangho_ilji/main.dart' as app;
import 'package:provider/provider.dart';
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

  test('combat numbers use stable thousands separators', () {
    expect(app.formatCount(0), '0');
    expect(app.formatCount(999), '999');
    expect(app.formatCount(1284), '1,284');
    expect(app.formatCount(-4200), '-4,200');
  });

  test('area travel log uses a natural destination sentence', () {
    final game = app.Game();
    game.areas.add(app.Area('test', '청죽림', '대나무 숲', 1, ['들개'], '숲의 수문장', 0));
    game.enemies = [
      {'name': '들개', 'hp': 10, 'attack': 1},
    ];
    game.goArea(0);
    expect(game.logs.first, '청죽림에 발걸음을 옮겼습니다.');
  });

  test('random gear names match their equipment slots', () {
    final game = app.Game();
    const suffixes = {
      '무기': ['검', '도', '창'],
      '머리': ['투구', '관'],
      '의복': ['도포', '장포'],
      '손': ['호완', '수갑'],
      '신발': ['보', '화'],
      '허리띠': ['요대', '허리띠'],
      '목걸이': ['목걸이', '주'],
      '옥패': ['패', '옥패'],
    };
    for (var i = 0; i < 120; i++) {
      final gear = game.randomGear(1);
      expect(
        suffixes[gear.slot]!.any(gear.name.endsWith),
        isTrue,
        reason: '${gear.slot}: ${gear.name}',
      );
    }
  });

  test('legacy gear names can be repaired to their saved slot', () {
    expect(app.repairGearName('현무도포', '머리'), '현무투구');
    expect(app.repairGearName('백호호완', '손'), '백호호완');
    expect(app.repairGearName('해진 도포', '의복'), '해진 도포');
  });

  testWidgets('bottom navigation exposes selected semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: app.GameNav(selectedIndex: 0, onDestinationSelected: (_) {}),
        ),
      ),
    );
    final navSemantics = tester.getSemantics(find.text('강호').first);
    expect(navSemantics.label, contains('강호 탭'));
    semantics.dispose();
  });

  testWidgets('combat meter exposes its numeric value', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: app.Meter(value: .5, color: Colors.red, text: 'HP  50 / 100'),
      ),
    );
    final meter = tester.getSemantics(find.byType(app.Meter));
    expect(meter.label, contains('HP  50 / 100'));
    expect(meter.value, 'HP  50 / 100');
    semantics.dispose();
  });

  testWidgets('main battle actions expose contextual semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final game = app.Game();
    game.areas.add(app.Area('test', '청죽림', '대나무 숲', 1, ['들개'], '숲의 수문장', 0));
    game.enemies = [
      {'name': '들개', 'hp': 10, 'attack': 1},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<app.Game>.value(
          value: game,
          child: const Scaffold(body: app.MainJianghu()),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('지역 변경').first).label,
      contains('지역 변경'),
    );
    expect(
      tester.getSemantics(find.text('정지').first).label,
      contains('자동 전투 정지'),
    );
    semantics.dispose();
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
        (index) =>
            app.Skill('skill$index', '초식 $index', '검법', '범품', 1.2, 3, '시험용 무공'),
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
    game.areas.add(app.Area('a0', '첫 길', '시험의 길', 1, ['들개'], '수문장', 0));
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
    expect(game.silver, silverBefore + 77);
    expect(game.logs.first, '기연의 결과: 낯선 노인을 돕는다');
  });

  test('skipping a fate event resumes the automatic battle flow', () {
    final game = app.Game();
    game.event = app.StoryEvent('갈림길', '비가 내리는 밤', [
      {'text': '지나간다', 'effect': 'none', 'value': 0},
    ]);
    game.skipEvent();
    expect(game.event, isNull);
    expect(game.logs.first, '기연을 지나쳤습니다.');
  });

  test('unselected fate events auto-dismiss after the choice window', () {
    final game = app.Game();
    game.ready = true;
    game.playing = true;
    game.event = app.StoryEvent('갈림길', '비가 내리는 밤', const []);
    game.eventStartedAt = DateTime.now().subtract(
      app.Game.fateChoiceTimeout + const Duration(seconds: 1),
    );
    game.tick();
    expect(game.event, isNull);
    expect(game.logs.first, '기연을 지나쳤습니다.');
  });

  test('fate countdown starts at five seconds', () {
    final game = app.Game();
    expect(game.fateSecondsRemaining, 5);
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

  test('corrupted local save is ignored during boot', () async {
    SharedPreferences.setMockInitialValues({'gangho_save': '{broken'});
    final game = app.Game();
    await game.boot();
    expect(game.ready, isTrue);
    expect(game.playing, isFalse);
    game.dispose();
  });
}
