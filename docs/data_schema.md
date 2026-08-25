# 데이터 스키마

`assets/data/areas.json`: id, name, description, recommendedLevel, enemies, bossId, unlockBoss, drops

`enemies.json`: id, name, areaId, hp, attack, defense, exp, silver

`bosses.json`: id, name, areaId, hp, attack, defense, rewardSilver, rewardExp

`skills.json`: id, name, school, grade, multiplier, cooldown, description

`meridians.json`: id, branch, x, y, parentId, cost, label, stat, value

`events.json`: id, areaId, title, text, choices[{text,effect,value}]

`GameSave`: player, unlockedArea, defeatedBosses, inventory, equipped, skills, meridians, logs, lastSeenAt, endingSeen. 콘텐츠 원본은 읽기 전용이며 런타임 저장 데이터는 id 참조를 사용한다.
