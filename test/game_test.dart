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
  });

  test('unknown content falls back safely', () {
    expect(app.areaArtwork('unknown'), isNull);
    expect(app.bossArtwork('unknown'), isNull);
    expect(app.enemyArtwork('unknown'), endsWith('enemy_bandit.png'));
  });
}
