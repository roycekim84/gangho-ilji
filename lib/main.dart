import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ink = Color(0xff14140f);
const paper = Color(0xffe4d6bc);
const gold = Color(0xffc89a4e);
const soft = Color(0xff9c927f);

void main() => runApp(const GanghoApp());

class GanghoApp extends StatelessWidget {
  const GanghoApp({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => Game()..boot(),
    child: MaterialApp(
      title: '강호일지',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'serif',
        colorScheme: const ColorScheme.dark(
          primary: gold,
          surface: Color(0xff211f19),
          onSurface: paper,
        ),
      ),
      home: const Shell(),
    ),
  );
}

class Area {
  Area(
    this.id,
    this.name,
    this.description,
    this.level,
    this.enemies,
    this.boss,
    this.tier,
  );
  final String id;
  final String name;
  final String description;
  final int level;
  final List<String> enemies;
  final String boss;
  final int tier;
  factory Area.fromJson(Map<String, dynamic> value) => Area(
    value['id'],
    value['name'],
    value['description'],
    value['recommendedLevel'],
    List<String>.from(value['enemies']),
    value['boss'],
    value['dropTier'],
  );
}

class Skill {
  Skill(
    this.id,
    this.name,
    this.school,
    this.grade,
    this.multiplier,
    this.cooldown,
    this.description,
  );
  final String id;
  final String name;
  final String school;
  final String grade;
  final double multiplier;
  final int cooldown;
  final String description;
  factory Skill.fromJson(Map<String, dynamic> value) => Skill(
    value['id'],
    value['name'],
    value['school'],
    value['grade'],
    (value['multiplier'] as num).toDouble(),
    value['cooldown'],
    value['description'],
  );
}

class Gear {
  Gear(
    this.id,
    this.name,
    this.slot,
    this.grade,
    this.quality,
    this.attack,
    this.defense, [
    this.locked = false,
  ]);
  String id;
  String name;
  String slot;
  String grade;
  int quality;
  int attack;
  int defense;
  bool locked;
  int get score => attack * 2 + defense + quality ~/ 5;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slot': slot,
    'grade': grade,
    'quality': quality,
    'attack': attack,
    'defense': defense,
    'locked': locked,
  };
  factory Gear.fromJson(Map<String, dynamic> value) => Gear(
    value['id'],
    value['name'],
    value['slot'],
    value['grade'],
    value['quality'],
    value['attack'],
    value['defense'],
    value['locked'] ?? false,
  );
}

class StoryEvent {
  StoryEvent(this.title, this.text, this.choices);
  final String title;
  final String text;
  final List<Map<String, dynamic>> choices;
  factory StoryEvent.fromJson(Map<String, dynamic> value) => StoryEvent(
    value['title'],
    value['text'],
    List<Map<String, dynamic>>.from(value['choices']),
  );
}

class Game extends ChangeNotifier {
  final Random random = Random();
  final List<Area> areas = [];
  final List<Skill> skills = [];
  final List<StoryEvent> events = [];
  List<Map<String, dynamic>> enemies = [];
  List<Map<String, dynamic>> bossData = [];
  List<Gear> bag = [];
  List<Gear> worn = [];
  List<String> logs = ['강호에 발을 들일 준비가 되었습니다.'];
  Set<String> bosses = {};
  Set<String> activeSkills = {'falling_leaf', 'iron_fist', 'breath'};
  Set<int> nodes = {};
  Timer? timer;
  StoryEvent? event;
  bool ready = false;
  bool playing = false;
  bool auto = true;
  bool fightingBoss = false;
  bool offline = false;
  bool ending = false;
  String hero = '무명';
  String realm = '삼류';
  String foe = '들개';
  int level = 1;
  int exp = 0;
  int silver = 80;
  int hp = 120;
  int maxHp = 120;
  int foeHp = 50;
  int foeMaxHp = 50;
  int foeAttack = 8;
  int area = 0;
  int unlocked = 0;
  int points = 0;
  int nodePoints = 0;
  int kills = 0;
  int strength = 8;
  int bone = 8;
  int agility = 8;
  int insight = 8;
  int vitality = 8;
  int energy = 8;
  int lastSkill = 0;
  DateTime lastSeen = DateTime.now();

  Area get place => areas[area];
  int get need => 40 + level * 35;
  int get attack =>
      12 +
      strength * 2 +
      energy ~/ 2 +
      worn.fold<int>(0, (sum, item) => sum + item.attack) +
      nodes.where((id) => id % 7 == 0).length * 3;
  int get defense =>
      4 +
      bone * 2 +
      worn.fold<int>(0, (sum, item) => sum + item.defense) +
      nodes.where((id) => id % 7 == 1).length * 2;
  int get critical => 5 + insight + nodes.where((id) => id % 7 == 2).length * 2;
  int get mastery => kills ~/ 2 + activeSkills.length * 8;

  Future<void> boot() async {
    final rawAreas =
        jsonDecode(await rootBundle.loadString('assets/data/areas.json'))
            as List;
    final rawSkills =
        jsonDecode(await rootBundle.loadString('assets/data/skills.json'))
            as List;
    final rawEvents =
        jsonDecode(await rootBundle.loadString('assets/data/events.json'))
            as List;
    final rawEnemies =
        jsonDecode(await rootBundle.loadString('assets/data/enemies.json'))
            as List;
    final rawBosses =
        jsonDecode(await rootBundle.loadString('assets/data/bosses.json'))
            as List;
    areas.addAll(rawAreas.map((x) => Area.fromJson(x)));
    skills.addAll(rawSkills.map((x) => Skill.fromJson(x)));
    events.addAll(rawEvents.map((x) => StoryEvent.fromJson(x)));
    enemies = rawEnemies.map((x) => Map<String, dynamic>.from(x)).toList();
    bossData = rawBosses.map((x) => Map<String, dynamic>.from(x)).toList();
    await _load();
    ready = true;
    offline = playing && DateTime.now().difference(lastSeen).inMinutes > 0;
    timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('gangho_save');
    if (raw == null) return;
    final value = jsonDecode(raw);
    playing = true;
    hero = value['hero'] ?? hero;
    realm = value['realm'] ?? realm;
    level = value['level'] ?? level;
    exp = value['exp'] ?? exp;
    silver = value['silver'] ?? silver;
    area = value['area'] ?? area;
    unlocked = value['unlocked'] ?? unlocked;
    points = value['points'] ?? points;
    nodePoints = value['nodePoints'] ?? nodePoints;
    kills = value['kills'] ?? kills;
    strength = value['strength'] ?? strength;
    bone = value['bone'] ?? bone;
    agility = value['agility'] ?? agility;
    insight = value['insight'] ?? insight;
    vitality = value['vitality'] ?? vitality;
    energy = value['energy'] ?? energy;
    bosses = Set<String>.from(value['bosses'] ?? []);
    activeSkills = Set<String>.from(value['activeSkills'] ?? activeSkills);
    nodes = Set<int>.from(value['nodes'] ?? []);
    bag = (value['bag'] as List? ?? []).map((x) => Gear.fromJson(x)).toList();
    worn = (value['worn'] as List? ?? []).map((x) => Gear.fromJson(x)).toList();
    ending = value['ending'] ?? false;
    lastSeen = DateTime.tryParse(value['lastSeen'] ?? '') ?? DateTime.now();
    refreshHp();
    spawn();
  }

  Future<void> save() async {
    if (!playing) return;
    final prefs = await SharedPreferences.getInstance();
    final value = {
      'hero': hero,
      'realm': realm,
      'level': level,
      'exp': exp,
      'silver': silver,
      'area': area,
      'unlocked': unlocked,
      'points': points,
      'nodePoints': nodePoints,
      'kills': kills,
      'strength': strength,
      'bone': bone,
      'agility': agility,
      'insight': insight,
      'vitality': vitality,
      'energy': energy,
      'bosses': bosses.toList(),
      'activeSkills': activeSkills.toList(),
      'nodes': nodes.toList(),
      'bag': bag.map((x) => x.toJson()).toList(),
      'worn': worn.map((x) => x.toJson()).toList(),
      'ending': ending,
      'lastSeen': DateTime.now().toIso8601String(),
    };
    await prefs.setString('gangho_save', jsonEncode(value));
  }

  void start(String value) {
    hero = value.trim().isEmpty ? '독고진' : value.trim();
    playing = true;
    logs = [hero + ', 낙양의 먼 길에 첫발을 내딛습니다.'];
    bag = [makeGear('무명인의 낡은 검', '무기', 0), makeGear('해진 도포', '의복', 0)];
    equip(bag.first);
    spawn();
    save();
    notifyListeners();
  }

  void refreshHp() {
    maxHp = 80 + vitality * 12 + level * 16;
    hp = min(maxHp, hp == 0 ? maxHp : hp);
  }

  void spawn({bool boss = false}) {
    fightingBoss = boss;
    foe = boss
        ? place.boss
        : place.enemies[random.nextInt(place.enemies.length)];
    final data = boss
        ? bossData.firstWhere((item) => item['name'] == foe)
        : enemies.firstWhere((item) => item['name'] == foe);
    foeMaxHp = data['hp'] as int;
    foeAttack = data['attack'] as int;
    foeHp = foeMaxHp;
  }

  void tick() {
    if (!ready || !playing || !auto || event != null || ending) return;
    fight();
  }

  void fight() {
    final dodged = random.nextInt(100) < agility ~/ 3;
    if (dodged) {
      log(hero + '이(가) 공격을 흘려냈습니다.');
    } else {
      final damage = max(1, foeAttack - defense ~/ 6);
      hp -= damage;
      log(foe + '의 공격, ' + damage.toString() + ' 피해.');
    }
    var damage = max(1, attack - area * 5 + random.nextInt(8));
    if (random.nextInt(100) < critical) {
      damage = (damage * 1.7).round();
      log('치명타!');
    }
    final usable = skills
        .where((skill) => activeSkills.contains(skill.id))
        .toList();
    if (usable.isNotEmpty &&
        kills + logs.length - lastSkill >= usable.first.cooldown) {
      final skill = usable[random.nextInt(usable.length)];
      damage = (damage * skill.multiplier).round();
      lastSkill = kills + logs.length;
      log(skill.name + ' 발동! ' + damage.toString() + ' 피해.');
    }
    foeHp -= damage;
    log(hero + '의 반격, ' + damage.toString() + ' 피해.');
    if (hp <= 0) {
      hp = maxHp;
      log('기혈이 다해 객잔에서 정신을 차렸습니다.');
    }
    if (foeHp <= 0) victory();
    notifyListeners();
  }

  void victory() {
    final gainExp = (12 + area * 9) * (fightingBoss ? 8 : 1);
    final gainSilver = (7 + area * 7) * (fightingBoss ? 12 : 1);
    exp += gainExp;
    silver += gainSilver;
    kills++;
    log(
      foe +
          ' 격파! 경험치 +' +
          gainExp.toString() +
          ', 은자 +' +
          gainSilver.toString(),
    );
    if (fightingBoss) {
      bosses.add(place.id);
      unlocked = min(6, max(unlocked, area + 1));
      log('【' + place.boss + '】을 꺾고 새 길을 열었습니다!');
      if (area == 6) ending = true;
      fightingBoss = false;
    } else if (random.nextInt(100) < 20) {
      final gear = randomGear(place.tier);
      bag.add(gear);
      log('◆ ' + gear.grade + ' 장비 「' + gear.name + '」을 얻었습니다.');
    }
    if (!fightingBoss && random.nextInt(100) < 7)
      event = events[random.nextInt(events.length)];
    while (exp >= need) {
      exp -= need;
      level++;
      points += 3;
      nodePoints++;
      refreshHp();
      log('레벨 ' + level.toString() + ' 달성! 능력치 3, 경맥점 1 획득.');
      checkRealm();
    }
    spawn();
    save();
  }

  void checkRealm() {
    if (realm == '삼류' && level >= 10 && bosses.isNotEmpty) {
      realm = '이류';
      log('경지 돌파: 이류 무인이 되었습니다!');
    }
    if (realm == '이류' && level >= 24 && bosses.length >= 3 && energy >= 60) {
      realm = '일류';
      log('경지 돌파: 일류 무인이 되었습니다!');
    }
    if (realm == '일류' && level >= 40 && bosses.length >= 6 && mastery >= 180) {
      realm = '절정';
      log('경지 돌파: 절정에 올랐습니다!');
    }
  }

  Gear makeGear(String title, String slot, int tier) => Gear(
    DateTime.now().microsecondsSinceEpoch.toString() + slot,
    title,
    slot,
    const ['범품', '양품', '명품', '보물'][tier],
    72 + random.nextInt(26),
    slot == '무기' ? 5 + tier * 7 : tier * 2,
    slot == '무기' ? tier : 3 + tier * 5,
  );

  Gear randomGear(int tier) {
    const slots = ['무기', '머리', '의복', '손', '신발', '허리띠', '목걸이', '옥패'];
    const prefixes = ['청운', '흑철', '유성', '백호', '현무', '적염'];
    const suffixes = ['검', '투구', '도포', '호완', '보', '요대', '옥', '패'];
    final slot = slots[random.nextInt(slots.length)];
    final rank = min(3, tier + (random.nextInt(100) < 12 ? 1 : 0));
    return makeGear(
      prefixes[random.nextInt(prefixes.length)] +
          suffixes[random.nextInt(suffixes.length)],
      slot,
      rank,
    );
  }

  void log(String text) {
    logs.insert(0, text);
    if (logs.length > 80) logs.removeLast();
  }

  void toggleAuto() {
    auto = !auto;
    save();
    notifyListeners();
  }

  void goArea(int index) {
    if (index > unlocked) return;
    area = index;
    spawn();
    log(areas[index].name + '(으)로 발걸음을 옮깁니다.');
    save();
    notifyListeners();
  }

  void challenge() {
    if (bosses.contains(place.id)) return;
    spawn(boss: true);
    log('【' + place.boss + '】에게 도전합니다.');
    notifyListeners();
  }

  void stat(String title) {
    if (points == 0) return;
    points--;
    if (title == '근력') strength++;
    if (title == '근골') bone++;
    if (title == '민첩') agility++;
    if (title == '오성') insight++;
    if (title == '기혈') {
      vitality++;
      refreshHp();
    }
    if (title == '내력') energy++;
    save();
    notifyListeners();
  }

  void equip(Gear gear) {
    final old = worn.where((item) => item.slot == gear.slot).toList();
    worn.removeWhere((item) => item.slot == gear.slot);
    if (old.isNotEmpty) bag.add(old.first);
    bag.removeWhere((item) => item.id == gear.id);
    worn.add(gear);
    save();
    notifyListeners();
  }

  void lock(Gear gear) {
    gear.locked = !gear.locked;
    save();
    notifyListeners();
  }

  void breakGear(Gear gear) {
    if (gear.locked) return;
    bag.removeWhere((item) => item.id == gear.id);
    silver += 12 + gear.score;
    save();
    notifyListeners();
  }

  void skill(String id) {
    if (activeSkills.contains(id))
      activeSkills.remove(id);
    else if (activeSkills.length < 5)
      activeSkills.add(id);
    else
      return;
    save();
    notifyListeners();
  }

  bool canOpen(int id) =>
      !nodes.contains(id) &&
      nodePoints > 0 &&
      (id == 0 || nodes.contains((id - 1) ~/ 3));
  void open(int id) {
    if (!canOpen(id)) return;
    nodes.add(id);
    nodePoints--;
    save();
    notifyListeners();
  }

  void resetNodes() {
    nodePoints += nodes.length;
    nodes.clear();
    save();
    notifyListeners();
  }

  void resolve(Map<String, dynamic> choice) {
    final kind = choice['effect'];
    final value = choice['value'] as int;
    if (kind == 'silver') silver += value;
    if (kind == 'exp') exp += value;
    if (kind == 'stat') insight += value;
    if (kind == 'heal') hp = min(maxHp, hp + value);
    if (kind == 'item') bag.add(randomGear(place.tier));
    log('기연의 결과: ' + choice['text']);
    event = null;
    save();
    notifyListeners();
  }

  void claimOffline() {
    final minutes = min(
      480,
      max(1, DateTime.now().difference(lastSeen).inMinutes),
    );
    final unit = 4 + area * 3;
    exp += minutes * unit ~/ 2;
    silver += minutes * unit;
    kills += minutes;
    if (random.nextBool()) bag.add(randomGear(place.tier));
    offline = false;
    log('오프라인 ' + minutes.toString() + '분의 수련 보상을 받았습니다.');
    save();
    notifyListeners();
  }

  void closeEnding() {
    ending = false;
    save();
    notifyListeners();
  }

  @override
  void dispose() {
    save();
    timer?.cancel();
    super.dispose();
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    if (!game.ready)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: ink,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: game.playing ? const Home() : const Start(),
          ),
        ),
      ),
    );
  }
}

class Start extends StatefulWidget {
  const Start({super.key});
  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  final controller = TextEditingController(text: '독고진');
  @override
  Widget build(BuildContext context) => InkPaper(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.landscape, size: 92, color: gold),
          const SizedBox(height: 18),
          const Text(
            '강호일지',
            style: TextStyle(
              fontSize: 43,
              fontWeight: FontWeight.bold,
              color: paper,
            ),
          ),
          const Text('江 湖 日 誌 · 무협 방치형 RPG', style: TextStyle(color: soft)),
          const SizedBox(height: 45),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: '무인의 이름',
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.read<Game>().start(controller.text),
            child: const Text('새로운 강호를 시작한다'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                showDialog(context: context, builder: (_) => const Guide()),
            child: const Text('강호의 법도'),
          ),
          const Spacer(),
          const Text(
            '로컬 완성판 알파 · 모든 기록은 이 기기에 저장됩니다.',
            style: TextStyle(fontSize: 11, color: soft),
          ),
        ],
      ),
    ),
  );
}

class Guide extends StatelessWidget {
  const Guide({super.key});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('강호의 법도'),
    content: const Text(
      '사냥은 자동으로 이어집니다. 장비, 능력치, 무공과 경맥을 세팅해 지역 보스를 쓰러뜨리십시오. 보스 승리로 다음 길이 열리고 천마봉에서 이야기가 끝납니다.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('알겠다'),
      ),
    ],
  );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final pages = [
      const Jianghu(),
      const Warrior(),
      const Martial(),
      const Bag(),
      const Chronicle(),
    ];
    return Stack(
      children: [
        Column(
          children: [
            Status(game: game),
            Expanded(child: pages[tab]),
            NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() => tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '강호',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '무인',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_tree_outlined),
                  selectedIcon: Icon(Icons.account_tree),
                  label: '무도',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: '행낭',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: '강호록',
                ),
              ],
            ),
          ],
        ),
        if (game.offline) Offline(game: game),
        if (game.event != null) EventCard(game: game),
        if (game.ending) Ending(game: game),
      ],
    );
  }
}

class Status extends StatelessWidget {
  const Status({super.key, required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xff28251e),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 9),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: gold,
          child: Icon(Icons.person, color: ink),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.hero + ' · ' + game.realm + ' Lv.' + game.level.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Meter(
                value: game.hp / game.maxHp,
                color: const Color(0xffb84a42),
                text: '기혈 ' + game.hp.toString() + '/' + game.maxHp.toString(),
              ),
              const SizedBox(height: 3),
              Meter(
                value: game.exp / game.need,
                color: const Color(0xff4e9b75),
                text: '수련 ' + game.exp.toString() + '/' + game.need.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            const Icon(Icons.monetization_on, color: gold, size: 18),
            Text(game.silver.toString(), style: const TextStyle(color: gold)),
          ],
        ),
      ],
    ),
  );
}

class Meter extends StatelessWidget {
  const Meter({
    super.key,
    required this.value,
    required this.color,
    required this.text,
  });
  final double value;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 14,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      FractionallySizedBox(
        widthFactor: value.clamp(0, 1),
        child: Container(
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
      Positioned.fill(
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 9, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}

class InkPaper extends StatelessWidget {
  const InkPaper({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [ink, Color(0xff272219), ink],
      ),
    ),
    child: child,
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xff211f1a),
      border: Border.all(color: const Color(0xff635239)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

class Jianghu extends StatelessWidget {
  const Jianghu({super.key});
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Panel(
          child: Column(
            children: [
              Text(
                game.place.name,
                style: const TextStyle(
                  fontSize: 20,
                  color: gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                game.place.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: soft),
              ),
              const Divider(),
              Text(
                game.fightingBoss ? '지역 보스' : '배회 중인 적',
                style: const TextStyle(color: soft),
              ),
              Text(game.foe, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 7),
              Meter(
                value: game.foeHp / game.foeMaxHp,
                color: const Color(0xffa43d36),
                text:
                    '적 기혈 ' +
                    max(0, game.foeHp).toString() +
                    '/' +
                    game.foeMaxHp.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: SizedBox(
            height: 245,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '전투 기록',
                  style: TextStyle(color: gold, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: game.logs.length,
                    itemBuilder: (_, index) {
                      final line = game.logs[index];
                      final positive =
                          line.contains('격파') ||
                          line.contains('획득') ||
                          line.contains('돌파');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 12,
                            color: positive ? const Color(0xff7ec88c) : paper,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: game.toggleAuto,
                icon: Icon(game.auto ? Icons.pause : Icons.play_arrow),
                label: Text(game.auto ? '자동전투 중' : '전투 재개'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => map(context),
                icon: const Icon(Icons.map_outlined),
                label: const Text('지역 이동'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: game.bosses.contains(game.place.id)
                ? null
                : game.challenge,
            icon: const Icon(Icons.shield),
            label: Text(
              game.bosses.contains(game.place.id)
                  ? '지역 보스 격파 완료'
                  : game.place.boss + '에게 도전',
            ),
          ),
        ),
      ],
    );
  }

  void map(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xff211f1a),
    builder: (_) => Consumer<Game>(
      builder: (context, game, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          children: [
            const Text('강호 지도', style: TextStyle(fontSize: 20, color: gold)),
            ...List.generate(game.areas.length, (index) {
              final item = game.areas[index];
              final available = index <= game.unlocked;
              return Card(
                color: const Color(0xff302b22),
                child: ListTile(
                  enabled: available,
                  leading: Icon(
                    available ? Icons.place : Icons.lock,
                    color: available ? gold : soft,
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '권장 Lv.' +
                        item.level.toString() +
                        ' · ' +
                        (game.bosses.contains(item.id) ? '보스 격파' : '진행 중'),
                  ),
                  trailing: index == game.area
                      ? const Text('현재', style: TextStyle(color: gold))
                      : null,
                  onTap: available
                      ? () {
                          game.goArea(index);
                          Navigator.pop(context);
                        }
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

class Warrior extends StatelessWidget {
  const Warrior({super.key});
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final stats = [
      ['근력', game.strength.toString(), '공격력'],
      ['근골', game.bone.toString(), '방어력'],
      ['민첩', game.agility.toString(), '회피'],
      ['오성', game.insight.toString(), '치명타'],
      ['기혈', game.vitality.toString(), '최대 기혈'],
      ['내력', game.energy.toString(), '무공 위력'],
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Panel(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xff54432d),
                child: Icon(Icons.person, size: 48, color: paper),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.hero,
                    style: const TextStyle(fontSize: 25, color: gold),
                  ),
                  Text(
                    game.realm +
                        ' · Lv.' +
                        game.level.toString() +
                        ' · 전투력 ' +
                        (game.attack * 4 + game.defense * 2).toString(),
                  ),
                  Text(
                    '남은 능력치 ' + game.points.toString(),
                    style: const TextStyle(color: Color(0xff7ec88c)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('기본 능력', style: TextStyle(color: gold)),
              ),
              ...stats.map(
                (item) => ListTile(
                  dense: true,
                  title: Text(item[0] + '  ' + item[1]),
                  subtitle: Text(
                    item[2],
                    style: const TextStyle(fontSize: 11, color: soft),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: gold),
                    onPressed: game.points > 0
                        ? () => game.stat(item[0])
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('전투 능력', style: TextStyle(color: gold)),
              Text(
                '공격력 ' +
                    game.attack.toString() +
                    ' · 방어력 ' +
                    game.defense.toString() +
                    ' · 치명 ' +
                    game.critical.toString() +
                    '% · 무공 숙련 ' +
                    game.mastery.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Martial extends StatefulWidget {
  const Martial({super.key});
  @override
  State<Martial> createState() => _MartialState();
}

class _MartialState extends State<Martial> {
  bool showMeridian = false;
  @override
  Widget build(BuildContext context) => showMeridian
      ? Meridian(back: () => setState(() => showMeridian = false))
      : Skills(openMeridian: () => setState(() => showMeridian = true));
}

class Skills extends StatelessWidget {
  const Skills({super.key, required this.openMeridian});
  final VoidCallback openMeridian;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('무공 세팅', style: TextStyle(fontSize: 22, color: gold)),
            ),
            OutlinedButton.icon(
              onPressed: openMeridian,
              icon: const Icon(Icons.account_tree),
              label: const Text('경맥도'),
            ),
          ],
        ),
        Text(
          '장착 ' + game.activeSkills.length.toString() + '/5 · 전투에서 자동 발동합니다.',
          style: const TextStyle(color: soft),
        ),
        const SizedBox(height: 10),
        ...game.skills.map((skill) {
          final active = game.activeSkills.contains(skill.id);
          final known =
              active || game.level >= 5 + game.skills.indexOf(skill) * 3;
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                enabled: known,
                leading: Icon(
                  active ? Icons.check_circle : Icons.menu_book,
                  color: active ? gold : soft,
                ),
                title: Text(skill.name),
                subtitle: Text(
                  skill.school +
                      ' · ' +
                      skill.grade +
                      ' · 위력 x' +
                      skill.multiplier.toString() +
                      ' · ' +
                      skill.description,
                ),
                trailing: Switch(
                  value: active,
                  onChanged: known ? (_) => game.skill(skill.id) : null,
                ),
                onTap: known ? () => game.skill(skill.id) : null,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class Meridian extends StatelessWidget {
  const Meridian({super.key, required this.back});
  final VoidCallback back;
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              IconButton(onPressed: back, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  '경맥도 · 남은 경맥점 ' + game.nodePoints.toString(),
                  style: const TextStyle(fontSize: 19, color: gold),
                ),
              ),
              TextButton(onPressed: game.resetNodes, child: const Text('초기화')),
            ],
          ),
        ),
        const Text(
          '노드를 열어 외공·내공·경공의 기초를 단련합니다.',
          style: TextStyle(color: soft, fontSize: 12),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: .7,
            maxScale: 2.8,
            child: CustomPaint(
              painter: MeridianLines(game.nodes),
              child: SizedBox(
                width: 500,
                height: 600,
                child: Stack(
                  children: List.generate(90, (index) {
                    final angle = (index % 15) * pi * 2 / 15;
                    final ring = index ~/ 15;
                    final x = 220 + cos(angle) * (55 + ring * 34);
                    final y = 285 + sin(angle) * (55 + ring * 34);
                    final opened = game.nodes.contains(index);
                    final available = game.canOpen(index);
                    return Positioned(
                      left: x,
                      top: y,
                      child: GestureDetector(
                        onTap: () => game.open(index),
                        child: Tooltip(
                          message: const [
                            '외공',
                            '내공',
                            '검맥',
                            '도맥',
                            '권맥',
                            '경공',
                            '암기',
                          ][index % 7],
                          child: Container(
                            width: index == 0 ? 35 : 24,
                            height: index == 0 ? 35 : 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: opened
                                  ? gold
                                  : available
                                  ? const Color(0xff67563e)
                                  : const Color(0xff29271f),
                              border: Border.all(color: opened ? paper : soft),
                            ),
                            child: Center(
                              child: Text(
                                index == 0 ? '정' : (index + 1).toString(),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: paper,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MeridianLines extends CustomPainter {
  MeridianLines(this.opened);
  final Set<int> opened;
  @override
  void paint(Canvas canvas, Size size) {
    final brush = Paint()..strokeWidth = 1;
    for (var index = 1; index < 90; index++) {
      final child = index - 1;
      final parent = (index - 1) ~/ 3;
      final childX =
          232 + cos((child % 15) * pi * 2 / 15) * (67 + (child ~/ 15) * 34);
      final childY =
          297 + sin((child % 15) * pi * 2 / 15) * (67 + (child ~/ 15) * 34);
      final parentX =
          232 + cos((parent % 15) * pi * 2 / 15) * (67 + (parent ~/ 15) * 34);
      final parentY =
          297 + sin((parent % 15) * pi * 2 / 15) * (67 + (parent ~/ 15) * 34);
      brush.color = opened.contains(index) && opened.contains(parent)
          ? gold
          : const Color(0xff4b4437);
      canvas.drawLine(Offset(childX, childY), Offset(parentX, parentY), brush);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Bag extends StatelessWidget {
  const Bag({super.key});
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final all = [...game.worn, ...game.bag];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '행낭 · ' + game.bag.length.toString() + '개',
          style: const TextStyle(fontSize: 22, color: gold),
        ),
        const Text('장비를 비교하고 장착하거나 분해합니다.', style: TextStyle(color: soft)),
        const SizedBox(height: 10),
        if (all.isEmpty) const Panel(child: Text('아직 얻은 장비가 없습니다.')),
        ...all.map((gear) {
          final equipped = game.worn.any((item) => item.id == gear.id);
          final same = game.worn
              .where((item) => item.slot == gear.slot)
              .firstOrNull;
          final delta = same == null ? 0 : gear.score - same.score;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        equipped ? Icons.verified : Icons.inventory,
                        color: gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gear.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gear.grade == '보물'
                                ? const Color(0xffe1b65d)
                                : paper,
                          ),
                        ),
                      ),
                      Text(gear.grade),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    gear.slot +
                        ' · 품질 ' +
                        gear.quality.toString() +
                        '% · 공격 ' +
                        gear.attack.toString() +
                        ' · 방어 ' +
                        gear.defense.toString(),
                  ),
                  if (same != null && !equipped)
                    Text(
                      '현재 ' +
                          same.name +
                          ' 대비 ' +
                          (delta >= 0 ? '+' : '') +
                          delta.toString(),
                      style: TextStyle(
                        color: delta >= 0
                            ? const Color(0xff7ec88c)
                            : const Color(0xffd27364),
                      ),
                    ),
                  if (!equipped)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => game.equip(gear),
                          child: const Text('장착'),
                        ),
                        TextButton(
                          onPressed: () => game.lock(gear),
                          child: Text(gear.locked ? '잠금 해제' : '잠금'),
                        ),
                        TextButton(
                          onPressed: gear.locked
                              ? null
                              : () => game.breakGear(gear),
                          child: const Text('분해'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class Chronicle extends StatelessWidget {
  const Chronicle({super.key});
  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('강호록', style: TextStyle(fontSize: 22, color: gold)),
        const SizedBox(height: 10),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('행적', style: TextStyle(color: gold)),
              Text(
                '누적 격파 ' +
                    game.kills.toString() +
                    ' · 도달 지역 ' +
                    (game.unlocked + 1).toString() +
                    '/7 · 보스 격파 ' +
                    game.bosses.length.toString() +
                    '/7',
              ),
              const Divider(),
              const Text('경지 돌파 조건', style: TextStyle(color: gold)),
              const Text(
                '이류: Lv.10 + 첫 보스\n일류: Lv.24 + 3보스 + 내력 60\n절정: Lv.40 + 6보스 + 무공 숙련 180',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('강호의 인물', style: TextStyle(color: gold)),
              ...game.areas.map(
                (item) => Text(
                  (game.bosses.contains(item.id) ? '✓ ' : '○ ') + item.boss,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          child: Text(
            game.ending
                ? '천마 잔영을 물리쳤습니다. 강호는 당신의 이름을 기억합니다.'
                : '아직 닫힌 장이 남아 있습니다.',
            style: const TextStyle(color: soft),
          ),
        ),
      ],
    );
  }
}

class Offline extends StatelessWidget {
  const Offline({super.key, required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    final minutes = DateTime.now()
        .difference(game.lastSeen)
        .inMinutes
        .clamp(1, 480);
    final unit = 4 + game.area * 3;
    return Overlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nightlight_round, size: 55, color: gold),
          const Text(
            '객잔의 밤이 지났습니다',
            style: TextStyle(fontSize: 23, color: gold),
          ),
          const SizedBox(height: 8),
          Text(minutes.toString() + '분 동안 ' + game.place.name + '에서 수련했습니다.'),
          Text(
            '예상 보상: 경험치 ' +
                (minutes * unit ~/ 2).toString() +
                ' · 은자 ' +
                (minutes * unit).toString(),
            style: const TextStyle(color: soft),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: game.claimOffline,
            child: const Text('모두 받기'),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    final item = game.event!;
    return Overlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: gold, size: 48),
          Text(
            '기연 · ' + item.title,
            style: const TextStyle(fontSize: 22, color: gold),
          ),
          const SizedBox(height: 12),
          Text(item.text, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ...item.choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => game.resolve(choice),
                  child: Text(choice['text']),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Ending extends StatelessWidget {
  const Ending({super.key, required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) => Overlay(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_fire_department, size: 58, color: gold),
        const Text('강호일지 · 종장', style: TextStyle(fontSize: 25, color: gold)),
        const SizedBox(height: 12),
        Text(
          game.hero +
              '은(는) 천마봉의 검은 구름을 거두었습니다.\n무명으로 시작한 이름은 이제 강호의 바람 속에 남습니다.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        FilledButton(
          onPressed: game.closeEnding,
          child: const Text('강호로 돌아간다'),
        ),
      ],
    ),
  );
}

class Overlay extends StatelessWidget {
  const Overlay({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Panel(child: child),
        ),
      ),
    ),
  );
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
