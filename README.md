# DOCS-course-bot

Репозиторий-документация для проекта **Telegram-курс-бота с Mini App**.

**Здесь не хранится код.** Код реализации — в отдельном репозитории [`romanticstudent07-stack/course-bot`](https://github.com/romanticstudent07-stack/course-bot). Этот репозиторий — **источник истины по архитектуре**.

## С чего начать

**Человеку:** прочитайте [CONTEXT.md](CONTEXT.md) (3 минуты), затем [architecture/README.md](architecture/README.md).

**AI-агенту (Genspark / Claude Code / Cursor / Codex):** прочитайте [AGENTS.md](AGENTS.md), затем [CONTEXT.md](CONTEXT.md), затем [architecture/CANONICAL-SOURCES.md](architecture/CANONICAL-SOURCES.md), затем [architecture/build/DIVISION.md](architecture/build/DIVISION.md).

## Структура

```
DOCS-course-bot/
├── README.md                   ← вы здесь
├── CONTEXT.md                  ← обзор проекта (3 минуты)
├── AGENTS.md                   ← инструкции для AI-агентов
├── .genspark/
│   └── rules.md                ← Genspark-специфичные правила
├── .github/
│   ├── workflows/architecture-checks.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── tools/
│   └── checks.sh               ← runner CI-чеков
└── architecture/               ← источник истины
    ├── README.md               ← рабочий каталог + реестр 1.10
    ├── CANONICAL-SOURCES.md    ← арбитр «верхний файл vs подпапка»
    ├── 17-SPLIT-PROTOCOL.md    ← протокол нарезки Блока 17
    ├── 00…09, 12, 13, 14, 16   ← блоки корпуса плоскими файлами
    ├── 10-lifecycle-return.md, 10/     ← Блок 10 (индекс + части)
    ├── 15-content-antipiracy.md, 15/   ← Блок 15 (сборка + части)
    ├── 17-author-panel.md, 17/         ← Блок 17 (индекс + части)
    ├── 99-legal.md, 99/                ← Юрблок (индекс + части)
    ├── normative/              ← нормативный стек (И1, И2, И3, И4, Б17, SEAM, ERRATA)
    ├── appendix/               ← приложения A/B/C/D
    ├── build/                  ← артефакты сборки (Mini App-first) + DIVISION.md
    ├── debt/                   ← артефакты долга (12 закрытых)
    └── _WIP-architecture-split.md  ← исторический служебный журнал (не источник)
```

## Как читать крупные Блоки без двусмысленности

В каталоге `architecture/` для крупных Блоков используется **двухуровневая схема**:

- верхний файл `NN-...md` — точка входа: вводная, оглавление и/или единая сборка;
- подпапка `NN/` — посекционный носитель содержания.

Это **не две конкурирующие версии**, а один Блок в двух представлениях.

Каноническое правило:

- для Блоков **10**, **15**, **17** и **99** при расхождении побеждают файлы из подпапок
  (`10/*`, `15/*`, `17/*`, `99/*`);
- нарезка Блока 17 выполнена по [architecture/17-SPLIT-PROTOCOL.md](architecture/17-SPLIT-PROTOCOL.md).

Полный арбитр — [architecture/CANONICAL-SOURCES.md](architecture/CANONICAL-SOURCES.md).

## Ключевые артефакты

| Файл | Что | Кому |
|---|---|---|
| [architecture/README.md](architecture/README.md) | Рабочий каталог, реестр 1.10 | всем |
| [architecture/CANONICAL-SOURCES.md](architecture/CANONICAL-SOURCES.md) | Арбитр «верхний файл vs подпапка» | всем |
| [architecture/normative/README.md](architecture/normative/README.md) | Порядок старшинства патчей | всем |
| [architecture/build/DIVISION.md](architecture/build/DIVISION.md) | Разделение реализации Mini App / Bot / Backend | реализаторам |
| [architecture/build/build-order.md](architecture/build/build-order.md) | Порядок первых итераций | реализаторам |
| [architecture/build/miniapp-security-checklist.md](architecture/build/miniapp-security-checklist.md) | Production-checklist безопасности Mini App | реализаторам |
| [architecture/appendix/C-registries.md](architecture/appendix/C-registries.md) | Реестры: риски, команды, инварианты, сроки, boot-gate | всем |
| [architecture/appendix/D-source-defects.md](architecture/appendix/D-source-defects.md) | Дефекты источника (D-01…D-31) | реализаторам |

## Правила старшинства

При расхождении побеждает верхний слой:

```
корпус v3 → И1 → И2 → И3 → И4 → Б17 → SEAM-PATCH-1 → ERRATA-UNIFIED (высшее)
```

Это **ось старшинства**. Не путать с хронологией присоединения
(`… → Б17 → ERRATA-UNIFIED → SEAM-PATCH-1`), которая идёт в другом порядке: SEAM-PATCH-1
подшит последним, но сам объявил себя `below_errata_unified`. Разбор двух осей —
в [architecture/normative/README.md](architecture/normative/README.md).

## Статус

- **Архитектура:** ✅ 13/13 кусков разложены, все врезки проставлены, приложения A/B/C/D собраны.
- **Крупные Блоки:** ✅ 10/15/17/99 разложены по канонической модели «индекс + части».
- **CI-инфраструктура:** ✅ `tools/checks.sh` + GitHub Actions, 15/15 чеков в текущем прогоне.
- **Реализация:** 🔧 не начата, репозиторий `course-bot`.
- **Boot-gate:** 🔧 7 открытых пунктов до прод-запуска — см. [C-registries.md, раздел 8](architecture/appendix/C-registries.md).

## Лицензия и права

TBD (решение Автора).
