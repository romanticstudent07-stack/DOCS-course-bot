---
file: build/db-tables-index.md
block: "—"
title: "Реестр таблиц БД — имя → владелец-блок → назначение"
status: скелет (собран из блоков 2, 6, 7, 9, 10, 14, 15, 16 + И1–И4 + Б17; DDL наполняется Автором в db-schema.sql)
---

# Реестр таблиц БД

Более 40 имён таблиц и логов, рассыпанных по корпусу и нормативному стеку. У каждой указан владелец-блок (кто пишет), потребители (кто читает), назначение и ссылка на источник истины. DDL — в [db-schema.sql](db-schema.sql).

| Имя | Владелец | Читатели | Назначение | Источник |
|---|---|---|---|---|
| `participant_state` | Б10 (`participant_state_projector`) | Б6, Б7, Б17, все UI | Проекция FSM участника, только одна эксклюзивная ось + флаги (E1 ERRATA) | И2, ERRATA E1 |
| `tg_user_registry` | Б14 | Mini App, Б4 | Реестр `tg_user_id ↔ pid` | Б14, И1 |
| `measurements_log` | Б14 | Б6 (Карта изменений), Б15 | Append-only журнал замеров | Б14 |
| `stage_publish_log` | Б14 | Б10, Б7 | Журнал публикаций этапов, `publish_epoch` (FIX1) | Б14, ERRATA FIX1 |
| `metric_catalog_log` | Б14 | все метрики | Каталог метрик, seed-YAML | Б14 |
| `tz_change_log` | Б2 | Б3, Б9 | Смены ТЗ участников (только со следующего дня) | Б2 |
| `pii_access_log` | Б17 | Б99 (152-ФЗ) | Аудит доступа к карточкам: кто, когда, чью карточку смотрел | Б17 |
| `data_export_event` | Б14 (`export-worker`) | Б17 | События экспорта данных субъекта | И3 |
| `refund_details` | Б16 (Refund Saga) | Б14, Б99 | Реквизиты возврата, retention 3 года (НК РФ) отдельно от PII | И3 |
| `erasure_blacklist` | Б99 | все блоки записи | Список стёртых участников (для исключения из списков и поиска) | Юрблок, ADD5 |
| `outbox` | Б15 | DLQ | Единый исходящий poll + компакция `INV-OUTBOX-SENT-AT-COMPACTION` | И2 + ADD1 ERRATA |
| `consumer_offsets` | Б15 | Б9, Б10 | Оффсеты потребителей `outbox` | И2 |
| `admin_action_log` | Б17 | Б99 | Аудит всех админ-действий (15 команд + `/audit` + `/legal`) | Б17 |
| `state_transition_log` | Б10 | Б7, Б14 | Журнал переходов FSM | И2 |
| `life_op_log` | Б2 | Б6, Б7 | Журнал life-ops (атомарность) | И2 |
| `refund_saga_log` | Б16 | Б14 | Журнал состояний refund saga | И3 |
| `photo_view_log` | Б15 | Б99, Б17 | Журнал просмотров фото (152-ФЗ) | И3 |
| `export_event_log` | Б14 | Б17 | События экспорта (метрики) | И3 |
| `baseline_override_log` | Б5 (Чек-Ап) | Б6 | Журнал ручных override базлайна | И3 |
| `red_zone_show_log` | Б5 | Б99 | Показы красной зоны | И3 |
| `red_flag_event` | Б5 | Б7, Б9 | События Red Flags (60-сек авто-эскалация) | И3 |
| `red_zone_review_tickets` | Б5 | Б7 | Тикеты ревью красной зоны | И3 |
| `owner_dashboard_state` | Б17 | UI | Состояние дашборда владельца | Б17 |
| `change_map_cache` | Б14 | Б6 | Кэш Карты изменений | Б14 |
| `topic_bindings` | Б8 | все темы | Привязки Telegram-тем | И4 |
| `hard_confirm_phrases` | Б17 | все команды | Реестр фраз hard-confirm (хэши) | Б17, E3 ERRATA |
| `text_registry` | Б9 (владелец) / Б14 (durability) | все блоки текстов | Единый носитель всех текстов (три тона, правовой статус) | И4 |
| `role_capability_matrix` | Б17 | UI, все команды | Матрица «команда → роль», CI-инвариант | Б17 |
| `checkup_config` | Б5 | Б5 | Конфиг Чек-Апа (версионирование + гейт Legal) | И3 |
| `metric_catalog` | Б14 | Б6, Б14 | Каталог метрик (seed-YAML) | Б14 |
| `idempotency_keys` | все финансовые | Б16 | Ключи идемпотентности для повторных операций | И2 |
| `dlq` | Б15 | ops | Dead Letter Queue outbox | И2 |
| `participant_state_projector` (роль) | Б10 | — | Роль БД, единственный писатель `participant_state` | И2, E1 |
| `participant_state_reader` (роль) | все читатели | — | Роль БД, чтение `participant_state` | И2 |

## Долги реестра

- **Столбцы, типы, ключи, индексы** — наполняются в [db-schema.sql](db-schema.sql).
- **Владельцы у 5–7 таблиц не однозначны** (например, `text_registry`: Б9 или Б14?) — решается CI-чеком `single_owner_per_table` (добавить в [ci-checks.yaml](ci-checks.yaml)).
- **Ежегодный календарь обязательств** (FIX2 ERRATA) — как отдельная таблица `annual_obligations` или как файл `reg_archive/annual/calendar.md` — решение Автора.
