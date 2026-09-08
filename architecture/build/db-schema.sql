-- ============================================================
-- build/db-schema.sql — DDL всех таблиц БД
-- Скелет. Наполняется Автором и техническим партнёром.
-- Источник имён: architecture/build/db-tables-index.md
-- Правило: побеждает корпус, а не этот файл.
-- ============================================================

-- ==================== БЛОК 10 ====================
-- Владелец: participant_state_projector
-- Читатели: participant_state_reader
-- E1 ERRATA: обычная таблица, наполняемая проектором (НЕ materialized_view)

CREATE TABLE participant_state (
    -- TODO: определить колонки (см. И2 participant_state_contract)
    -- Обязательные: pid, lifecycle_phase (эксклюзивная ось), status_flags (bitmap),
    --               updated_at, projector_version
    PLACEHOLDER SERIAL PRIMARY KEY
);

-- CREATE ROLE participant_state_projector; -- единственный писатель
-- CREATE ROLE participant_state_reader;    -- все читатели
-- GRANT INSERT, UPDATE ON participant_state TO participant_state_projector;
-- GRANT SELECT ON participant_state TO participant_state_reader;

-- ==================== БЛОК 14 ====================
-- ... остальные ~33 таблицы по [db-tables-index.md]

-- ============================================================
-- Инварианты БД (переносятся в CI-чеки из [build/ci-checks.yaml])
-- ============================================================
-- INV-1: единственный писатель participant_state — participant_state_projector
-- INV-2: append_only_logs (measurements_log, reflections_log, money_ops_log) — только INSERT
-- INV-3: outbox компакция с sent_at (INV-OUTBOX-SENT-AT-COMPACTION, ADD1)
-- INV-4: erasure_blacklist retention = full_backup_rotation_cycle (Boot-gate)
-- INV-5: refund_details retention = 3 года (НК РФ), отдельно от PII

-- END OF SKELETON
