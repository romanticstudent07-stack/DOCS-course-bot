#!/usr/bin/env bash
# ============================================================
# tools/checks.sh — реальный runner CI-чеков DOCS-course-bot
# Источник соответствия: architecture/build/ci-checks.yaml
# ============================================================
set -euo pipefail

FAIL=0
FAILED_LIST=""

fail() {
  echo "❌ FAIL: $1"
  FAIL=1
  FAILED_LIST="$FAILED_LIST
  - $1"
}

pass() {
  echo "✅ $1"
}

# ------------------------------------------------------------
# Всегда работаем из корня репозитория, а не из той папки,
# откуда скрипт запустили (иначе пути architecture/... не найдутся)
# ------------------------------------------------------------
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$REPO_ROOT" ]; then
  cd "$REPO_ROOT"
fi
if [ ! -d architecture ]; then
  echo "❌ Не найдена папка architecture/. Запускайте из корня репозитория."
  exit 2
fi

# ------------------------------------------------------------
# Файлы, которые НЕ являются корпусом и потому не должны
# ловиться текстовыми проверками:
#   ci-checks.yaml         — спецификация самих проверок;
#   _WIP-...               — исторический служебный журнал (помечен HISTORICAL);
#   17-SPLIT-PROTOCOL.md   — содержит примеры grep-команд с текстом ссылок;
#   17-99-yaml-full.md     — дословный перенос исходного YAML block_17
#                            (все упоминания banned_* внутри — из оригинала,
#                            помечены Р477 (И2) прямо в тексте контракта).
# ------------------------------------------------------------
SPEC_FILE="architecture/build/ci-checks.yaml"
WIP_FILE="architecture/_WIP-architecture-split.md"
DEFECTS_FILE="architecture/appendix/D-source-defects.md"
CMDREG_FILE="architecture/build/bot-commands-registry.yaml"
SPLIT_PROTOCOL_FILE="architecture/17-SPLIT-PROTOCOL.md"
YAML_FULL_FILE="architecture/17/17-99-yaml-full.md"

echo "── [1/15] errata_link_path"
BAD_ERRATA=$(grep -RIn '\[errata-unified\.md\](errata-unified\.md)' architecture/ \
  | grep -v '^architecture/normative/' \
  | grep -v "^$SPEC_FILE" \
  | grep -v "^$WIP_FILE" \
  | grep -v "^$SPLIT_PROTOCOL_FILE" \
  || true)
if [ -n "$BAD_ERRATA" ]; then
  echo "$BAD_ERRATA"
  fail "ссылка [errata-unified.md](errata-unified.md) вне normative/ должна быть с префиксом normative/"
else
  pass "errata_link_path"
fi

echo "── [2/15] no_place_command"
BAD_PLACE=$(grep -RIn '/place\|P6_place_command' architecture/ \
  | grep -v 'architecture/12-reserve.md' \
  | grep -v 'architecture/README.md' \
  | grep -v 'architecture/appendix/A-patch1-global-rules.md' \
  | grep -v 'architecture/appendix/B-failsafe-registry.md' \
  | grep -v 'architecture/appendix/C-registries.md' \
  | grep -v 'architecture/_WIP-architecture-split.md' \
  | grep -v "^$SPEC_FILE" \
  | grep -v 'Историческая справка' \
  | grep -v 'исключена навсегда' \
  | grep -v 'hard-reject' \
  | grep -v 'не восстанавливается' \
  | grep -v 'NR-17.5' \
  | grep -v 'NR_17_5' \
  | grep -v 'never restored' \
  | grep -v 'Формулировка' \
  | grep -v 'v3.1' || true)
if [ -n "$BAD_PLACE" ]; then
  echo "$BAD_PLACE"
  fail "найдены упоминания /place как действующей команды"
else
  pass "no_place_command"
fi

echo "── [3/15] wip_pointer_dead"
BAD_WIP=$(grep -RIn '_WIP-architecture-split' architecture/ \
  | grep -v '^architecture/_WIP-architecture-split.md' \
  | grep -v 'architecture/appendix/D-source-defects.md' \
  | grep -v "^$SPEC_FILE" \
  | grep -v 'исторический' \
  | grep -v 'историч' \
  | grep -v 'historical' \
  | grep -v 'HISTORICAL' \
  | grep -v 'ранее' \
  | grep -v 'Ранее' \
  | grep -v 'не используется' \
  | grep -v 'заменяет' || true)
if [ -n "$BAD_WIP" ]; then
  echo "$BAD_WIP"
  fail "найдены ссылки на _WIP-architecture-split.md как на источник истины"
else
  pass "wip_pointer_dead"
fi

echo "── [4/15] errata_backrefs_present"
MISSING=""
for f in architecture/{00,01,02,03,04,05,06,07,08,09,10-lifecycle-return,12-reserve,13-past-material-access,14-data-durability,15-content-antipiracy,16-payment,17-author-panel,99-legal}*.md architecture/normative/{I1,I2,I3,I4}*.md; do
  [ -f "$f" ] || continue
  if ! grep -q 'ERRATA-UNIFIED\|SEAM-PATCH-1\|Переопределено\|Уточнено' "$f"; then
    MISSING="$MISSING $f"
  fi
done
if [ -n "$MISSING" ]; then
  fail "нет врезки ERRATA-UNIFIED в:$MISSING"
else
  pass "errata_backrefs_present"
fi

echo "── [5/15] no_live_banned_states"
BAD_BAN=$(grep -RIn 'banned_soft\|banned_hard' architecture/ \
  | grep -v 'architecture/normative/I2-wave-b.md' \
  | grep -v "^$SPEC_FILE" \
  | grep -v "^$YAML_FULL_FILE" \
  | grep -v 'удалён' \
  | grep -v 'Р477' \
  | grep -v 'sleeping' \
  | grep -v 'forbidden_auto_transitions_to' \
  | grep -v 'block: true' \
  | grep -v 'WARN' \
  | grep -v 'allowed_with_warning' \
  | grep -v 'send_blocked_hard_ban' \
  | grep -v 'NR-17.14' \
  | grep -v 'NR_17_14' \
  | grep -v 'эскалация' \
  | grep -v 'axis_states' \
  || true)
if [ -n "$BAD_BAN" ]; then
  echo "$BAD_BAN"
  fail "живые упоминания banned_soft/banned_hard без пометки Р477"
else
  pass "no_live_banned_states"
fi

echo "── [6/15] precedence_single_source (positive)"
if [ ! -f architecture/normative/README.md ]; then
  fail "нет файла architecture/normative/README.md — цепочку старшинства негде объявить"
elif grep -q 'корпус v3 → И1 → И2 → И3' architecture/normative/README.md; then
  pass "precedence_single_source (объявлено в normative/README.md)"
else
  fail "цепочка старшинства не объявлена в architecture/normative/README.md"
fi

echo "── [7/15] precedence_single_source (negative)"
BAD_PRE=$(grep -RIn 'ниже в цепочке старшинства' architecture/ \
  | grep -v "^$SPEC_FILE" \
  | grep -v 'forbidden_phrase' \
  | grep -v "^$WIP_FILE" || true)
if [ -n "$BAD_PRE" ]; then
  echo "$BAD_PRE"
  fail "запрещённая фраза «ниже в цепочке старшинства» встречается вне канона"
else
  pass "precedence_single_source (запрещённая фраза не встречается)"
fi

echo "── [8/15] ci_checks_yaml_indent"
if [ ! -f "$SPEC_FILE" ]; then
  fail "нет файла $SPEC_FILE"
elif grep -nE '^ [^ -]' "$SPEC_FILE" > /dev/null; then
  fail "нарушены отступы в architecture/build/ci-checks.yaml (элементы должны начинаться с '  - ')"
else
  pass "ci_checks_yaml_indent"
fi

echo "── [9/15] no_broken_links (warning)"
# Простая эвристика: относительные .md-ссылки должны существовать
WARNS=0
while IFS=: read -r file line ref; do
  [ -n "${file:-}" ] || continue
  # спецификацию проверок, исторический журнал и файлы с примерами grep-команд не проверяем
  case "$file" in
    "$SPEC_FILE"|"$WIP_FILE"|"$SPLIT_PROTOCOL_FILE") continue ;;
  esac
  target=$(echo "$ref" | sed -nE 's/.*\(([^)]+\.md)(#[^)]*)?\).*/\1/p')
  if [ -z "$target" ]; then
    continue
  fi
  case "$target" in
    http*|mailto*|//*) continue ;;
  esac
  dir=$(dirname "$file")
  if [ ! -f "$dir/$target" ]; then
    echo "⚠ WARN: $file:$line → $target (файла нет)"
    WARNS=$((WARNS+1))
  fi
done < <(grep -RIn -oE '\[[^]]+\]\([^)]+\.md(#[^)]*)?\)' architecture/ || true)
if [ "$WARNS" -gt 0 ]; then
  echo "⚠ WARN: $WARNS битых относительных ссылок (не блокирует, но исправить)"
else
  pass "no_broken_links"
fi

echo "── [10/15] canonical_sources_doc_present"
if [ -f architecture/CANONICAL-SOURCES.md ]; then
  pass "canonical_sources_doc_present"
else
  fail "нет файла architecture/CANONICAL-SOURCES.md"
fi

echo "── [11/15] agents_and_context_mention_split_folders"
MISS11=""
[ -f AGENTS.md ]  || MISS11="$MISS11 AGENTS.md(нет файла)"
[ -f CONTEXT.md ] || MISS11="$MISS11 CONTEXT.md(нет файла)"
if [ -z "$MISS11" ]; then
  grep -q 'CANONICAL-SOURCES.md' AGENTS.md  || MISS11="$MISS11 AGENTS.md→CANONICAL-SOURCES.md"
  grep -q 'CANONICAL-SOURCES.md' CONTEXT.md || MISS11="$MISS11 CONTEXT.md→CANONICAL-SOURCES.md"
  grep -q '10/' CONTEXT.md || MISS11="$MISS11 CONTEXT.md→10/"
  grep -q '15/' CONTEXT.md || MISS11="$MISS11 CONTEXT.md→15/"
  grep -q '99/' CONTEXT.md || MISS11="$MISS11 CONTEXT.md→99/"
fi
if [ -z "$MISS11" ]; then
  pass "agents_and_context_mention_split_folders"
else
  echo "   не хватает:$MISS11"
  fail "AGENTS.md/CONTEXT.md должны ссылаться на CANONICAL-SOURCES.md и упоминать 10/, 15/, 99/"
fi

echo "── [12/15] seventeen_split_guard"
if [ -d architecture/17 ]; then
  if [ -f architecture/17-SPLIT-PROTOCOL.md ] \
     && grep -q 'Правило нулевых потерь' architecture/17-SPLIT-PROTOCOL.md; then
    pass "seventeen_split_guard (папка 17/ существует и протокол на месте)"
  else
    fail "создана папка architecture/17/, но 17-SPLIT-PROTOCOL.md отсутствует или неполон"
  fi
else
  pass "seventeen_split_guard (папки 17/ нет, монолит-канон в силе)"
fi

echo "── [13/15] wip_has_historical_header"
if [ ! -f "$WIP_FILE" ]; then
  fail "нет файла $WIP_FILE"
elif grep -q 'HISTORICAL' "$WIP_FILE"; then
  pass "wip_has_historical_header"
else
  fail "_WIP-architecture-split.md должен содержать явную пометку HISTORICAL"
fi

echo "── [14/15] source_defects_count"
if [ ! -f "$DEFECTS_FILE" ]; then
  fail "нет файла $DEFECTS_FILE — реестр дефектов D-01…D-31 не создан"
else
  # строгий вариант: записи вида "- D-01. ..."
  CNT_STRICT=$(grep -cE '^- D-[0-9]{2}\.' "$DEFECTS_FILE" || true)
  : "${CNT_STRICT:=0}"
  # устойчивый вариант: сколько уникальных идентификаторов D-01…D-31 упомянуто
  CNT_UNIQ=$(grep -oE 'D-(0[1-9]|[12][0-9]|3[01])' "$DEFECTS_FILE" \
    | sort -u | wc -l | tr -d '[:space:]' || true)
  : "${CNT_UNIQ:=0}"
  if [ "$CNT_STRICT" -eq 31 ] || [ "$CNT_UNIQ" -eq 31 ]; then
    pass "source_defects_count (найдено 31; строгих строк: $CNT_STRICT, уникальных ID: $CNT_UNIQ)"
  else
    fail "в appendix/D-source-defects.md ожидалось 31 запись D-01…D-31, найдено: строгих строк $CNT_STRICT, уникальных ID $CNT_UNIQ"
  fi
fi

echo "── [15/15] dangling_grant_photos_access"
if [ ! -f "$CMDREG_FILE" ]; then
  fail "нет файла $CMDREG_FILE"
elif grep -q 'dangling_command' "$CMDREG_FILE" \
   && grep -q '/grant_photos_access' "$CMDREG_FILE"; then
  pass "dangling_grant_photos_access (зафиксирована как dangling_command)"
else
  fail "висячая команда /grant_photos_access должна быть в dangling_command блоке"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "🎉 Все 15 проверок прошли."
  exit 0
else
  echo "❗ Есть невыполненные проверки:$FAILED_LIST"
  echo "Смотрите вывод выше."
  exit 1
fi
