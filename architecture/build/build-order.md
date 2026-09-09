---
file: build/build-order.md
block: "—"
title: "Порядок сборки: зависимости, миграции, синтетический запуск"
status: скелет
---

# Порядок сборки

Скелет для агента бота: с чего начинать реализацию, чтобы система собралась без круговых зависимостей.

## Уровень 0 — инфраструктура

1. PostgreSQL (основная БД) + PITR-настройка.
2. S3-совместимое хранилище (`{s3-domain-ru}` — до решения Автора: Yandex Cloud / Timeweb Cloud).
3. Redis (только буфер аналитики, критичные события — синхронно в PG, см. `critical_writes: synchronous_postgres`).
4. Object Lock отключён на бакетах фото; `COMPLIANCE`/WORM на бакетах аудита.

## Уровень 1 — ядро данных

1. DDL из [db-schema.sql](db-schema.sql) — все ~34 таблицы + роли (`participant_state_projector`, `participant_state_reader`).
2. `outbox` + `dlq` + `consumer_offsets` (Б15/И2).
3. `text_registry` — пустой + seed из блоков 2, 3, 5, 9, 10, 15, 16 после юридической вычитки (И4).

## Уровень 2 — проекторы и саги

1. `participant_state_projector` (владелец Б10) — читает `state_transition_log`, пишет `participant_state`.
2. Refund Saga (Б16 + И3).
3. Photo Ingest Saga (Б15 + И3).
4. Red Flags Protocol (Б5 + И3, авто-эскалация за 60 сек).
5. Export Worker (Б14 + И3, `data_export_event`).

## Уровень 3 — API и клиенты

1. Telegram Bot API — команды из [C-registries.md#реестр-команд-бота](../appendix/C-registries.md), 35 команд.
2. Mini App API — [miniapp-api-contract.yaml](miniapp-api-contract.yaml), 8+ эндпоинтов, CSP `default-src 'self'` (E2).
3. Панель Автора (Б17) — 6 поверхностей администрирования.

## Уровень 4 — гейт прод-запуска (boot-gate)

Не запускать в прод, пока не закрыт каждый из семи пунктов [C-registries.md#8-boot-gate](../appendix/C-registries.md):

1. Все 15+ текстов `legal_status: pre-legal-review` подписаны юристом.
2. Д-40 закрыт (РКН реальным событием).
3. Д-30 закрыт (DPA с провайдером).
4. Д-31 закрыт (модель угроз, УЗ-3).
5. `{s3-domain-ru}` заменён на реальный домен.
6. `full_backup_rotation_cycle` заменён на число (более строгая граница A4 с учётом WAL).
7. Все `pre-legal-review` сняты.

## Порядок первых итераций (Mini App-first)

Приоритет тестового запуска — Mini App-первый экран участника. Бот и backend поднимаются в объёме, необходимом для этого пути.

### Итерация 0 — инфра (1 неделя)

1. Yandex Cloud аккаунт + Managed PostgreSQL + Object Storage.
2. Telegram Bot регистрация в BotFather: `/newbot`, `/newapp`, `/setmenubutton https://<s3-domain-ru>/`, `/setdomain`.
3. Vite + React + TypeScript скелет через `npx @telegram-apps/create-mini-app`.
4. FastAPI скелет + alembic + docker-compose.

### Итерация 1 — онбординг (SEAM-1) (2 недели)

**Mini App:**
- Экраны `onb.welcome` → `onb.age-gate` → `onb.consent-152fz` → `onb.offer` → `onb.payment` → `onb.form` → `onb.checkup` → `onb.rules`.
- Валидация `initData` на сервере (эндпоинт `/miniapp/v1/onboarding/first-launch`).
- IndexedDB для черновиков анкеты.

**Bot:**
- `/start` в приватном чате → приветствие + Menu Button.
- Fallback: «Установите последнюю версию Telegram и откройте кнопку меню».

**Backend:**
- Таблицы `tg_user_registry`, `participant_state`, `role_capability_matrix`.
- Проектор `participant_state_projector`.
- Стек `text_registry` минимальный (только тексты онбординга).

### Итерация 2 — дневной модуль (2 недели)

**Mini App:** `day.current` + отправка отчёта + счётчик жизней.
**Bot:** утренний старт-пуш, напоминания-лестница.
**Backend:** П-31, life-ops атомарность, `state_transition_log`.

### Итерация 3 — Чек-Ап и Карточка (2 недели)

**Mini App:** `me.card`, `me.consents`, `me.change-map`, `me.settings-notifications`.
**Bot:** `/card <@user>` для владельца в Рабочей группе.
**Backend:** генерация Карточки на лету, аудит `pii_access_log`.

### Итерация 4 — оплата и refund (2 недели)

**Mini App:** `payment.pay`, `payment.refund`, `payment.act`.
**Bot:** reply-команда `/refund` с hard-confirm.
**Backend:** Refund Saga (И3), интеграция с PSP (YooKassa/CloudPayments), retention `refund_details`.

### Итерация 5 — фото и хранение (2 недели)

**Mini App:** `content.photo-submit` + деконструкция pre-signed URL.
**Bot:** deep-link «Открыть материал».
**Backend:** Photo Ingest Saga, S3 bucket без Object Lock (для стирания), WORM на аудите.

### Итерация 6 — Панель Автора (2 недели)

**Bot целиком:** реестр 35 команд из [bot-commands-registry.yaml](bot-commands-registry.yaml), hard-confirm (E3), whitelist admin-ID, дашборд владельца, palette.
**Backend:** `admin_action_log`, `role_capability_matrix`, `hard_confirm_phrases`.

## Минимальный синтетический запуск (для приёмки)

```
1) pg + s3-mock + redis
2) DDL + seed text_registry (черновые тексты, БЕЗ прод-текстов)
3) participant_state_projector
4) один stub-эндпоинт Mini App + ручной онбординг из бот-диалога (для тестов)
5) refund saga в dry-run режиме
6) панель Автора (только whitelist из feature flags)
```

`ready_for_synthetic_launch: yes` — при выполнении всех шести пунктов выше.

## Переменные окружения (минимум)

- `BOT_TOKEN` — Telegram Bot API.
- `PG_DSN` — DSN основной БД.
- `PG_DSN_READER` — DSN read-replica для аналитики.
- `S3_ENDPOINT` — `{s3-domain-ru}` (после решения Автора).
- `S3_ACCESS_KEY`, `S3_SECRET_KEY` — секреты S3.
- `REDIS_URL` — Redis (только буфер).
- `MINIAPP_URL` — URL Mini App (в РФ).
- `WHITELIST_ADMIN_IDS` — список tg_user_id Автора и партнёров.
- `FEATURE_FLAGS` — `miniapp_enabled`, `broadcast_enabled` и т.д.
- `LEGAL_GATE_MODE` — `blocking` (прод) или `advisory` (синтетика).

## Состав `docker-compose.yaml` (минимум)

- `postgres:16` с WAL-репликацией.
- `redis:7`.
- `minio` (S3-mock для синтетики).
- `bot` — Python 3.12 + Telegram Bot API + FastAPI (Mini App back-end).
- `miniapp` — статика (nginx + CSP-заголовок из E2).
- `worker` — export-worker + saga executors.

## Долг

- Config-schemas для всех YAML — [config-schemas/](config-schemas/) (создать при первом реальном конфиге).
- CI-pipeline — [ci-checks.yaml](ci-checks.yaml).
- Плейлист миграций (Alembic) — при первой правке DDL после первого прода.
