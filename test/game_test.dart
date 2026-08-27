import 'package:flutter_test/flutter_test.dart';
import 'package:gangho_ilji/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
}
