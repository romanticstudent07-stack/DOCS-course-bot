# DOCS-course-bot

Репозиторий-документация для проекта **Telegram-курс-бота с Mini App**.

**Здесь не хранится код.** Код реализации — в отдельном репозитории [`romanticstudent07-stack/course-bot`](https://github.com/romanticstudent07-stack/course-bot). Этот репозиторий — **источник истины по архитектуре**.

## С чего начать

**Человеку:** прочитайте [CONTEXT.md](CONTEXT.md) (3 минуты), затем [architecture/README.md](architecture/README.md).

**AI-агенту (Genspark / Claude Code / Cursor / Codex):** прочитайте [AGENTS.md](AGENTS.md), затем [CONTEXT.md](CONTEXT.md), затем [architecture/build/DIVISION.md](architecture/build/DIVISION.md).

## Структура

```
DOCS-course-bot/
├── README.md                   ← вы здесь
├── CONTEXT.md                  ← обзор проекта (3 минуты)
├── AGENTS.md                   ← инструкции для AI-агентов
├── .genspark/
│   └── rules.md                ← Genspark-специфичные правила
└── architecture/               ← источник истины
    ├── README.md               ← рабочий каталог + реестр 1.10
    ├── 00…17, 99*.md           ← блоки корпуса (consolidated v3)
    ├── 10/, 15/, 99/           ← крупные блоки, развёрнутые в подпапки
    ├── normative/              ← нормативный стек (И1, И2, И3, И4, Б17, SEAM, ERRATA)
    ├── appendix/               ← приложения A/B/C/D
    ├── build/                  ← артефакты сборки (Mini App-first) + DIVISION.md
    ├── debt/                   ← артефакты долга (12 закрытых)
    └── _WIP-architecture-split.md
```

## Ключевые артефакты

| Файл | Что | Кому |
|---|---|---|
| [architecture/README.md](architecture/README.md) | Рабочий каталог, реестр 1.10 | всем |
| [architecture/normative/README.md](architecture/normative/README.md) | Порядок старшинства патчей | всем |
| [architecture/build/DIVISION.md](architecture/build/DIVISION.md) | Разделение реализации Mini App / Bot / Backend | реализаторам |
| [architecture/build/build-order.md](architecture/build/build-order.md) | Порядок первых итераций | реализаторам |
| [architecture/appendix/C-registries.md](architecture/appendix/C-registries.md) | Реестры: риски, команды, инварианты, сроки, boot-gate | всем |
| [architecture/appendix/D-source-defects.md](architecture/appendix/D-source-defects.md) | Дефекты источника (D-01…D-31) | реализаторам |

## Правила старшинства

При расхождении побеждает верхний слой:

```
корпус v3 → И1 → И2 → И3 → И4 → Б17 → SEAM-PATCH-1 → ERRATA-UNIFIED (высшее)
```

Подробнее — [architecture/normative/README.md](architecture/normative/README.md).

## Статус

- **Архитектура:** ✅ 13/13 кусков разложены, все врезки проставлены, приложения A/B/C/D собраны.
- **Реализация:** 🔧 не начата, репозиторий `course-bot`.
- **Boot-gate:** 🔧 7 открытых пунктов до прод-запуска — см. [C-registries.md, раздел 8](architecture/appendix/C-registries.md).

## Лицензия и права

TBD (решение Автора).
