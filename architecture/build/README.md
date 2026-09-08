---
file: build/README.md
block: "—"
title: "Артефакты сборки — оглавление и порядок работ"
status: скелет (наполняется Автором и техническим партнёром)
doc_version: "скелет v0"
policy: "Файлы этого каталога — исполняемые артефакты для агента бота: DDL, контракт API, схемы конфигов, CI-реестр, порядок сборки. При расхождении с корпусом побеждает корпус (это не источник истины, а его отражение в исполняемой форме)."
---

# BUILD — артефакты сборки

Каталог `build/` не входит в источник истины (`architecture/` + `normative/` + `appendix/`). Это **отражение** истины в исполняемой форме: DDL для БД, JSON-Schema для API Mini App, seed-файлы конфигов, сводный список CI-чеков и порядок сборки. При расхождении между `build/` и корпусом побеждает корпус.

## Файлы каталога

| Файл | Что | Источник истины |
|---|---|---|
| [db-schema.sql](db-schema.sql) | DDL всех таблиц и логов | 40+ имён из блоков 2, 6, 7, 9, 10, 14, 15, 16 + И1–И4 + Б17 |
| [db-tables-index.md](db-tables-index.md) | Реестр таблиц: имя → владелец-блок → назначение → ссылка на DDL | тот же |
| [miniapp-api-contract.yaml](miniapp-api-contract.yaml) | OpenAPI 3.1 для Mini App: эндпоинты, схемы, коды ошибок, аутентификация | Б14 (Mini App v3.3 + дельта v3.4), И4, ERRATA E2 |
| [config-schemas/](config-schemas/) | JSON-Schema для всех YAML-конфигов и seed-файлов | Б1 (принцип), Б14 (`metric_catalog`), Б17 (`config/commands`), И4 (`text_registry`) |
| [ci-checks.yaml](ci-checks.yaml) | Плоский список 50+ CI-чеков с id/владельцем/командой | И1–И4 (40+) + Б17 (10) |
| [build-order.md](build-order.md) | Порядок сборки: зависимости, миграции, минимальный синтетический запуск | этот отчёт + `deferred_from_*` из И1–И4 |

## Порядок работ (для Автора)

1. Наполнить [db-schema.sql](db-schema.sql) — по каждому блоку добавить DDL с указанием владельца и обратной ссылки на раздел архитектуры.
2. Наполнить [miniapp-api-contract.yaml](miniapp-api-contract.yaml) — восемь известных эндпоинтов Mini App + модель `initData`.
3. Наполнить [config-schemas/](config-schemas/) — начать с `text_registry.schema.json`, `commands.schema.json`, `metric_catalog.schema.json`.
4. Собрать [ci-checks.yaml](ci-checks.yaml) — извлечь все `ci_checks_*` из И1–И4 и Б17.
5. Написать [build-order.md](build-order.md) — минимальный синтетический запуск: `pg → outbox → participant_state_projector → block10 → block14 → block17 → block4/mini-app`.

## Открытые решения (без них сборка не идёт)

- **S3-провайдер.** Yandex Cloud / Timeweb Cloud «Облако 152-ФЗ» / `{s3-domain-ru}` — Д-29 против `D_20_cloud_provider`. Плейсхолдер `{s3-domain-ru}` в CSP блокирует прод (ERRATA раздел 6). Решение — в [appendix/C-registries.md](../appendix/C-registries.md), раздел 8 «Boot-gate».
- **`full_backup_rotation_cycle`.** Не определено; блокирует прод (ADD5). Задел — в [appendix/D-source-defects.md](../appendix/D-source-defects.md), D-12.
- **Три несовместимости Б17.** См. [normative/README.md](../normative/README.md), «Открытые несовместимости».
- **Роли `finance` и `moderator`.** Задел — в [appendix/C-registries.md](../appendix/C-registries.md), раздел 9.
- **Каноническое число команд.** 35 (см. [appendix/C-registries.md](../appendix/C-registries.md), раздел 5) + висячая 36-я `/grant_photos_access`.
