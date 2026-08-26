import 'package:flutter_test/flutter_test.dart';
import 'package:gangho_ilji/main.dart' as app;

void main() {
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
    expect(app.gearArtwork('의복'), endsWith('item_armor.png'));
  });

  test('unknown content falls back safely', () {
    expect(app.areaArtwork('unknown'), isNull);
    expect(app.bossArtwork('unknown'), isNull);
    expect(app.enemyArtwork('unknown'), endsWith('enemy_bandit.png'));
  });
}
