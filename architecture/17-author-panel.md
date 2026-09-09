---
file: 17-author-panel.md
block: 17
title: "Панель Автора / командный режим"
status: закрыт (v3.4)
doc_version: "consolidated v3 + патч v3.4"
contains: [единая выжимка, матрица команда×состояние, матрица команда×роль, патч v3.3→v3.4, NR-инварианты, yaml]
---

# БЛОК 17. ПАНЕЛЬ АВТОРА / КОМАНДНЫЙ РЕЖИМ

> **Поверх этого блока действует патч Б17** → [normative/B17-admin-panel-patch.md](normative/B17-admin-panel-patch.md) (`consolidated-v3.9-b17`).
> Это разные документы: здесь — блок 17 корпуса (v3.4, требования NR-17.1…23), там — патч нормативного стека, снимающий STUB блока: единый реестр админ-команд (35 команд со схемой), командные кнопки Карточки участника (6 секций), единый интерфейс аудита (операционный и приватностный виды), дашборд владельца, палитра команд Ctrl+K и broadcast-инспектор.
> При расхождении об интерфейсе и составе команд побеждает патч Б17 как стоящий ниже в цепочке старшинства (`корпус v3 → И1 → И2 → И3 → И4 → Б17 → ERRATA-UNIFIED → SEAM-PATCH-1`). Ограничения FSM (Р477: состояний `banned_*` нет) и сроки из И2/И3 патчем Б17 не отменяются.

> **Уточнено ERRATA-UNIFIED.** Фразовый hard-confirm, на который опираются реестр команд и красная зона этого патча, сохранён нормативно (E3): обратимые операции — только двухшаг, необратимые — двухшаг плюс фраза из `hard_confirm_phrases`. Дашборд владельца и broadcast-инспектор дополнены пятью метриками рассылки (ADD2). Каноническое число рисков — 22 (NOTE1), то есть счётчик `totals.risks_registry: 22` верен по номерам, но дубль `RISK-L-06` при переносе в приложение C снимается. Три несовместимости этого патча (команды `/block` и `/unblock` при удалённом Р477 носителе состояния, видимость Карточки для роли `moderator`, `/erasure_finalize_before_cooling_off` против отсрочки стирания И3) единым ERRATA-слоем **не рассмотрены** и остаются решением Автора; до него действуют более строгие требования И2 и И3. См. [normative/errata-unified.md](normative/errata-unified.md).

> **Переопределено/дополнено ERRATA-UNIFIED.** Реестр фраз hard-confirm, на который И3 опирается в `revert_contract` и refund saga, сохранён нормативно (E3): двухшаг и фраза — слои, а не альтернативы. Уточнение уведомления третьих сторон (`sh21_third_party_notification`) усилено ADD3; формулировка для участника о собственном сроке хранения PSP (до 5 лет по 115-ФЗ) добавлена A3 ERRATA — статус текста `pre-legal-review`, блокирует прод. Boot-gate по `full_backup_rotation_cycle` (ADD5, NOTE2) связан с отсрочками стирания И3: при подстановке брать более строгую границу A4 с учётом WAL. Три несовместимости патча Б17 с И3 (`/erasure_finalize_before_cooling_off` против отсрочки 14 дн., автоэскалация в Red Zone за 60 сек, роли `finance`/`moderator`) единым ERRATA-слоем **не рассмотрены** и остаются решением Автора; до него действуют более строгие требования И3. См. [normative/errata-unified.md](normative/errata-unified.md), [normative/B17-admin-panel-patch.md](normative/B17-admin-panel-patch.md), [normative/seam-patch-1-onboarding.md](normative/seam-patch-1-onboarding.md).

## Назначение и границы

Блок 17 — исполнительный слой «доступа Бога»: он не вводит бизнес-правил, а даёт Автору и его помощникам безопасные, единообразные, аудируемые входы к правилам блоков-владельцев (Б2 — жизни и паузы, Б6 — карточка, Б7 — рефлексии и «График», Б8 — рабочая группа, Б9 — уведомления, Б10 — жизненный цикл, Б13 — доступ к пройденному, Б14 — durability, Б15 — хранение, Б16 — оплата, юридический блок — `/legal`). Б17 владеет: каталогом команд, командными кнопками-ярлыками, мастером параметров, whitelist-гейтом, моделью ролей, аудитом вызовов, идемпотентностью-обёрткой, UX-контрактом «кнопка → диалог → двухшаг». Б17 не делает: не вводит бизнес-правил, не хранит `/place` и не воскрешает миграцию (поправка v3.1 навсегда), не имеет автоприменения решений, не пишет напрямую в состояние доменов в обход владельцев.

## Модель ролей (окончательная)

Существуют четыре роли: два **owner** с полным контролем (все классы действий, полная карточка, `/legal`, банинг, управление whitelist); **moderator** — просмотр карточки в редуцированном виде + модерация (❤️ жизни, ⏸ пауза без grant, ✅ approve / ↩ revert, ✉️ сообщение через Бота, mute), без денег, без юр.данных, без банинга; **finance** — просмотр финансового среза карточки + оплаты и возвраты (`/confirm_payment`, `/reject_payment`, `/refund`), без модерации, без юр.данных, без банинга; роль **partner** из ранней редакции упраздняется как избыточная.

Whitelist — единый список `admin_ids` с ролью на каждого; управление whitelist (`/admin_add` | `/admin_remove` | `/admin_role`) выполняется одним owner без со-подтверждения, но с обязательным неудаляемым broadcast всем owner в отдельную admin-тему рабочей группы (политика «no delete / no edit», зеркалирование в durable-лог Б14, рассинхрон темы и лога рождает алерт обоим owner); еженедельный digest owner’ам сводит все admin-действия за 7 дней. Минимум один owner инвариантен — попытка удалить последнего owner отклоняется.

Whitelist-гейт применяется на КАЖДОМ входе: reply-команда, командная кнопка, callback, info-only просмотр карточки; попытка вне whitelist — молчаливый игнор с записью в аудит (не подтверждаем существование бота-контура постороннему). Callback от чужого TG-ID под легитимным сообщением — игнор с аудитом.

## Каталог команд

Полный реестр команд Б17 (домен-владелец правила указан в скобках): `/revert` (Б7.9), `/life +1` и `/life -1` (Ф-Б2.5), `/pause` и `/unpause` (Б2), `/unpause_user` (Б2, снятие пользовательской паузы Автором), `/pause_grant` (Ф-Б2.П9), `/set_shadow` и `/unshadow` (Ф-Б7.7, тайная пауза), `/approve` (Б7.6, «Зачесть рефлексию»), `/confirm_payment` и `/reject_payment` (Б16), `/refund` (Б16.6, каскадная saga), `/block` и `/unblock` (Б10, только owner), `/mute` и `/unmute` (Б8, группа), `/card` (Б6), `/legal` (юр.), ✉️ написать участнику через Бота (Б8.8), `/graph` (Б7 «График», cohort-scope), `/audit` (Б14, только owner), административные `/admin_add` | `/admin_remove` | `/admin_role` (Б17).

Команда `/place` и кнопка 📍 Place исключены навсегда поправкой v3.1: маршрутизатор жёстко отбивает legacy-callbacks с префиксом `place_*` по `schema_version`, попытки логируются как `place_attempted` + напоминание в рабочей группе; **NR-17.5** — `/place` не восстанавливается ни при каких условиях.

## UX-контракт входа

Ввод — гибрид (Б8.4): кнопки-ярлыки под карточкой/сообщениями для частых простых действий + reply-команды в рабочей группе для параметрических и редких. Оба пути ведут в один диспетчер и один мастер параметров, чтобы UX не расходился. Кнопка не выполняет действие сразу — один тап открывает мастер: (1) подтверждение участника (title карточки + `participant_id`), (2) ввод параметров (если требуются), (3) двухшаговое подтверждение. Кнопка автоматически привязывается к `participant_id` карточки/сообщения.

Reply-команда без reply-таргета — Бот отвечает «уточните участника» и не исполняет ничего; попытка фиксируется в аудите. Мастер имеет тайм-аут 10 минут; по истечении — авто-cancel с аудитом `dialog_timeout`. На один `{actor_id, cmd, participant_id}` — не более одного активного мастера; повторный вызов из другой точки — «уже открыт мастер здесь…» с deeplink. Каждый callback несёт `{cmd, participant_id, dialog_id, step, schema_version, nonce}`; повторные/устаревшие клики — no-op. `participant_id` для исполнения берётся ИСКЛЮЧИТЕЛЬНО из тела callback шага подтверждения, никогда — из «текущего контекста Автора» (**NR-17.2**).

## Двухшаговое подтверждение и идемпотентность

Всё необратимое, финансовое, жизненное, привилегированное — двухшагово. Экран подтверждения содержит: человекочитаемый summary (что, кому, параметры, обратимость), кнопку «Да, выполнить», кнопку «Отмена». Кнопка «Да» рендерится НЕ на месте первой кнопки предыдущего шага (буквальная защита от инерционного тапа). Read-only действия (`/card`, `/legal`, `/graph`) — в 1 тап.

Идемпотентность — через `operation_key`. Для one-shot операций (`/refund`, `/admin_remove`, `/admin_role`, `pause_grant #N`) ключ = `hash(actor_id, cmd, resource_id)`, где `resource_id` = `payment_id` | `admin_id` | `(participant_id, grant_no)`; `params` в ключ НЕ входят — изменение reason при ретрае возвращает исходный результат, а не создаёт вторую транзакцию. Для repeatable операций (`/life±`, `/approve`, `/revert`, `/pause`, `/unpause`) ключ = `hash(actor_id, cmd, participant_id, dialog_id)` — стабилен внутри мастера, новый мастер = новый ключ. TTL ключа — минимум 24 часа для `financial_ops`, 1 час для остальных.

После выполнения кнопки шага подтверждения дезактивируются (edit-message → «Выполнено ✓ / Отменено ✕») — никаких «живых» кнопок под завершённой операцией. Если между шагами параметров и подтверждения состояние участника изменилось (например, жизни уже 3, а команда «+1»), диспетчер отклоняет исполнение с точным диагнозом; аудит фиксирует `stale_state_reject` (**NR-17.3**, `expected_*`-контракт).

## Атомарность и гонки

Все изменения состояния — на стороне владельцев доменов, атомарно. Life-ops — единая транзакция с `SELECT … FOR UPDATE` на строке участника; границы `[0..3]`; попытка выхода — hard-reject Б2 с явным текстом. `/refund` — one-shot по `payment_id`. `/revert` — сериализация параллельных вызовов через `operation_key`. `/pause_grant` — проверка «пауза этапа уже потрачена?» затем запись. `/unblock` — Б10 проверяет «окно ещё открыто?», при закрытом — принудительный downgrade `restore → fresh` с новым экраном подтверждения (без тихого понижения, **NR-17.4**).

Гонки нескольких админов на одном участнике покрыты advisory-lock на `participant_id` с TTL = 10 мин и heartbeat: любая destructive-команда одного admin блокирует открытие destructive-мастера другим admin — второй видит «уже открыт мастер: у <admin_name>». Read-ops lock не берут. Приоритет владельца: owner может «перехватить» кнопкой «⛔ Перехватить» мастер moderator/finance (двухшагово); мастер аннулируется, аудит фиксирует `wizard_preempted_by_owner`. При завершении любого destructive-действия — системное информ-сообщение в admin-тему `<actor> · <cmd> · <participant> · <decision>` (peer-visibility, SOC2-канон).

## Сквозной инвариант блока: бот никогда не банит (NR-17.14)

Ключевой сквозной инвариант блока — «БОТ НИКОГДА НЕ БАНИТ УЧАСТНИКА. Банит и разбанивает ТОЛЬКО owner» (**NR-17.14**). Из этого следует:

1. `/block` и `/unblock` (обе ветви restore/fresh) доступны только owner; moderator и finance не видят этих кнопок, hard-reject на уровне маршрутизатора с `role_denied`.
2. НИКАКОЙ автомат Б2, Б7, Б8, Б9, Б10, Б16 не имеет права переводить участника в `banned_soft` или `banned_hard` ни при каких условиях — включая исчерпание жизней, неоплату, антифлуд, антиспам, инциденты рефлексии, регресс, легаси-код; автомат может ставить только `sleeping`, `erased` (по регламенту хранения Б15), `muted`.
3. Исчерпание жизней (Ф-Б2.5) → `sleeping`, не бан; неоплата в срок (Б16) → `sleeping`, не бан; инцидент рефлексии (Б7) → `sleeping` или reject, не бан; антифлуд/антиспам в рабочей группе (Б8) → `muted`, не бан; истечение хранения (Б15) → `erased`, не бан.
4. Если ситуация требует полного бана — автомат ЭСКАЛИРУЕТ owner’у уведомлением «требуется решение о блокировке участника X, причина Y», решение принимает owner вручную командой `/block`.
5. Любая попытка автомата поставить `banned_*` (легаси-код, ошибка, регресс) отсекается маршрутизатором, попадает в аудит `auto_ban_blocked` и рождает алерт обоим owner.

Состояние `muted` — временное отключение эмиссии участника в рабочей группе; НЕ отменяет доступ к курсу, НЕ тратит жизни, НЕ отменяет оплату; ставится автоматами антифлуда/антиспама или moderator/owner, снимается ими же; эскалация до `/block` — только через owner-решение.

## Пауз-семантика

Три различаемые семантики пауз, все три отображаются в карточке (стык Б6): `user_pause` — инициатор участник, расходует квоту этапа; `author_pause` — инициатор Автор, не расходует квоту участника; `pause_shadow` — системная тайная пауза (Ф-Б7.7), участнику невидима.

Команды: `/pause` и `/unpause` Автора действуют на `author_pause` того же уровня; `/unpause_user` — отдельная команда для принудительного снятия пользовательской паузы, при подтверждении Автор видит «у участника остаётся X дней квоты паузы» — квота сохраняется (участник может уйти в паузу снова), 24-часовой cooldown не вводится, борьба с циклом «Автор снял — участник продлил» — правило квоты Б2, а не панели; `/pause_grant` — доп.пауза 2/3 форс-мажор, только owner, атомарно у Б2; `/set_shadow` — ручная постановка тайной паузы, только owner, двухшагово, причина ОБЯЗАТЕЛЬНА и выбирается из фиксированного списка кодов от Б7 (свободный текст запрещён), с broadcast в admin-тему; `/unshadow` — снятие тайной паузы, только owner; автоматическая постановка `pause_shadow` правилами Б7 сохраняется.

## Разделение вердикта и применения прохода

Кнопка `/approve` называется «✅ Зачесть рефлексию» (не «Одобрить проход») — предотвращение UX-ловушки. Команда пишет `verdict: pending → approved` в домене Б7.6, но НЕ применяет проход: переход на следующий день выполняется расписанием Дня 14 (Б7.7). Экран подтверждения дословно: «Рефлексия участника за день будет отмечена как принятая. Переход на следующий день произойдёт автоматически по расписанию Дня 14. Проход сейчас не активируется».

`/revert` — обратный переход `approved → pending` возможен ТОЛЬКО пока проход не применён (окно до Б7.7); после применения перехода — кнопка не рендерится, плашка «День уже перевыдан»; откат уже применённого дня — отдельная компенсирующая операция (долг Б7, существует ли).

## Возврат оплаты как saga

`/refund` — многошаговая saga, координатор Б16.6: (1) Б16: `payment: confirmed → refund_pending`; (2) Б10: `state → sleeping`; (3) Б13: отзыв доступа к пройденным материалам; (4) Б15: физическое удаление персональных артефактов (durable, отложенная задача); (5) Б16: `payment: refund_pending → refunded`.

Экран второго шага подтверждения ОБЯЗАН показать весь каскад Автору («перевод в sleeping, отзыв доступа к материалам, удаление личных данных до 24ч, отменить нельзя»); без этой строки экран считается некомплектным. Сбой шагов 3/4 — статус `refund_partial → pending_ops_review`, алерт в рабочую группу, автоматических откатов 1–2 нет — ручное разрешение через owner (**NR-17.7**). One-shot-ключ рефанда не сбрасывается частичным сбоем — повторный `/refund` попадает в тот же saga-экземпляр (idempotent resume).

`/refund` разрешён при любом состоянии участника, если платёж был получен, включая `banned_soft` и `banned_hard`, с warning «участник забанен; деньги вернутся, доступ не восстановится»; исключение — `erased`, где реквизитов возврата может не быть технически (долг Б15/Б16 — удержать реквизиты дольше ПДн профиля или отсрочить `erased` до финализации расчётов).

## Цикл чек → reject → новый чек

После `/reject_payment` статус платежа `rejected`; кнопки под этим сообщением-чеком дезактивируются. Когда участник шлёт новый чек (Б16.3), Бот рендерит новую карточку с новой парой кнопок ✅/✖ и новым `payment_id`; старая не «оживает». `operation_key` привязан к `payment_id`, два чека — две независимые операции. В новой карточке — ссылка «предыдущая попытка отклонена <ts>, причина: <X>» (Автор видит контекст без открытия карточки участника).

## Приватность карточки и /legal

Три view-профиля карточки: `owner_full` — полный вид; `moderator_reduced` — карточка без полей класса `sensitive_health` и без строки `pause_shadow`, вместо них — плашка «⚖ Данные закрыты. Обратитесь к owner»; `finance_financial` — только платёжные поля (оплаты, статусы, дата начала курса, наличие активного доступа) + флаг «участник неактивен по не-финансовой причине» без деталей, без жизней, рефлексий, паузы-деталей, shadow, `sensitive_health` (**NR-17.17**).

`/legal` (⚖ Юр.данные) — отдельная privilege-точка, доступ только owner; даже owner попадает в приватностный аудит при каждом просмотре.

## ✉️ через Бота: гейт по состояниям

Отправка сообщения от имени Бота участнику проходит через мастер `preview → send`: Автор видит финальный вид сообщения, подтверждает, сообщение уходит участнику единожды (идемпотентно). Гейт доставки: `active` / `user_pause` / `author_pause` / `sleeping` — OK/WARN с указанием состояния; `banned_soft` — OK с warning; `banned_hard` — hard-reject `send_blocked_hard_ban`; `erased` — hard-reject `send_blocked_erased` (chat_id разорван); `pause_shadow` — доставка разрешена, но linter-фильтр текста: если сообщение содержит явные раскрытия («пауза», «мы поставили тебя на паузу», «shadow» и т.п.) — warning «текст может раскрыть тайную паузу», финальное решение за Автором с явным чекбоксом `shadow_disclosure_ack: true`.

Тело сообщения в аудите хранится как хэш, plaintext — в Б14/Б8.8; при `pause_shadow` — с пометкой `shadow_disclosure_ack: true/false`. Отправка невозможна после отправки — сообщение уже у участника, компенсация — извинение вручную; UI предпросмотра дублирует «после отправки сообщение нельзя удалить».

## Whitelist cache-miss и bootstrap

Двухуровневая политика на случай отказа БД. Уровень 1 (cache-miss, БД доступна): force-read из БД, тайм-аут 3с, при успехе кэш восстановлен; при провале — падение в уровень 2. Уровень 2 (cache + DB miss, cold-start/инцидент): чтение из durable bootstrap-файла (Б14/Б15), содержащего только owner-ID (максимум 2) и подпись; все moderator/finance считаются недоступными до восстановления БД.

В bootstrap-режиме доступны ТОЛЬКО read-ops и `/admin_add` (для восстановления состава), все destructive — hard-reject «система в bootstrap-режиме, восстановите БД» (**NR-17.10**). Вход и выход из bootstrap — обязательный алерт owner’ам, аудит пишется в локальный durable-лог, синхронизируется с основным при восстановлении. При промахе кэша без bootstrap-fallback — hard-fail в сторону «запретить», не «разрешить».

## Аудит

Два потока. **Операционный**: `{ts_server, actor_id, actor_role, cmd, participant_id, params, dialog_id, decision (executed | rejected | ignored | stale_state_reject | dialog_timeout | place_attempted | role_denied | auto_ban_blocked), reason, operation_key, schema_version}`, retention forever, транзакционно связан с изменением состояния владельца — если аудит не записался, операция отменяется (Р429). **Приватностный аудит 152-ФЗ**: `{ts, actor_id, participant_id, view: card | card_reduced | card_financial | legal | graph | full_change_map}`, retention forever, best-effort с очередью, при переполнении очереди — блокировка просмотра (защита от «немого чтения»).

Команда `/audit <participant_id>` — доступ только owner, её вызов тоже попадает в аудит (одной строкой, не-рекурсивно). Попытки вне whitelist, устаревшие callbacks, place-легаси, тайм-ауты диалогов, `stale_state_reject`, автоматические попытки бана — попадают в операционный аудит с явным `decision`.

## Компенсирующие операции (undo)

Полный откат необратимой операции не поддерживается — явное правило (NR-17: rollback не бывает). Undo — семантическая обратная операция с полем `compensates: <original_operation_key>` в аудите: ошибочный `/life -1` → `/life +1`, ошибочный `/revert` → повторный `/approve` (в окне до Б7.7), ошибочный `/block` → `/unblock` (с режимом restore, если окно открыто), ошибочный `/admin_remove` → `/admin_add`, ошибочный ✉️ — компенсация невозможна (сообщение уже у участника), только извинение вручную; ошибочный `/refund` после завершения саги — восстановление доступа + новая оплата с ручной пометкой `manual_reissue` (долг Б16). Пары «действие / компенсация» видны в retrospective-разборе аудита.

## 🛡 Блок 17 — Fail-safe (сводка)

Вне whitelist — игнор + аудит; при промахе кэша — hard-fail «запретить», при полном отказе БД — bootstrap-режим. Двухшаг обязателен для всего необратимого; кнопка «Да» не на месте первой кнопки. Идемпотентность через стабильный `operation_key`; повтор возвращает оригинальный результат. Callback несёт `schema_version` + `nonce`; устаревшие/чужие — no-op. Тайм-аут мастера 10 минут; один активный мастер на `{actor, cmd, participant}`. `expected_*`-контракт: несовпадение состояния — отказ с диагнозом, не тихое исполнение. Аудит операционный — в одной транзакции с состоянием. `/place` — hard-reject маршрутизатора, включая legacy-callbacks. Кнопки не доступной роли — не рендерятся вовсе (нельзя тапнуть). Автомат не может забанить — маршрутизатор отсекает попытку. Пустых экранов нет: любой отказ выдаёт человекочитаемый текст с причиной.

## NR-инварианты Б17

- **NR-17.1** — Whitelist всегда содержит ≥1 owner.
- **NR-17.2** — `participant_id` действия = `participant_id` из callback шага подтверждения. Никогда — из «контекста Автора».
- **NR-17.3** — Изменение состояния владельца происходит только при совпадении `expected_*` из шага параметров.
- **NR-17.4** — Ни одна необратимая операция не даунгрейдится молча — при смене режима Автору показывается новый экран подтверждения.
- **NR-17.5** — `/place` не восстанавливается ни при каких условиях; попытка — аудит, а не исполнение.
- **NR-17.6** — Изменение whitelist требует broadcast всем owner в admin-тему (неудаляемый, зеркалированный в Б14).
- **NR-17.7** — Частичный сбой саги `/refund` не откатывает автоматически шаги 1–2; статус `pending_ops_review`, ручное разрешение через owner.
- **NR-17.8** — Квота `user_pause` не сгорает при принудительном `/unpause_user`; предотвращение цикла — правило Б2.
- **NR-17.9** — При `pause_shadow` доставка ✉️ разрешена, но требует явного `shadow_disclosure_ack`.
- **NR-17.10** — В bootstrap-режиме доступны только read-ops и `/admin_add`; все destructive — hard-reject.
- **NR-17.11** — Undo = compensating action, никогда не rollback; пары линкуются через `compensates:`.
- **NR-17.12** — Broadcast whitelist- и `/set_shadow`-действий — часть той же транзакции, что и запись в аудит.
- **NR-17.13** — Партнёр-роль упразднена; финальный состав owner × 2 + moderator + finance.
- **NR-17.14** — БОТ НИКОГДА НЕ БАНИТ УЧАСТНИКА. Банит и разбанивает ТОЛЬКО owner. Автомат может ставить только `sleeping`, `erased`, `muted`.
- **NR-17.15** — Broadcast whitelist- и `/set_shadow`-действий неудаляем инициатором.
- **NR-17.16** — `/unblock` — только owner (симметрия с `/block`).
- **NR-17.17** — finance не видит `pause_shadow` (и любых модерационных деталей).

## МАТРИЦА «КОМАНДА × СОСТОЯНИЕ УЧАСТНИКА»

Легенда: OK = разрешено; WARN = разрешено, экран подтверждения содержит warning-строку с причиной; NO = hard-reject с конкретным диагнозом; — = неприменимо / глобальная команда.

```text
Формат: КОМАНДА | onboarding | active | user_pause | author_pause | pause_shadow | sleeping | banned_soft | banned_hard | erased | muted
/card (owner)              | OK   | OK   | OK   | OK   | OK   | OK   | OK   | OK   | WARN | OK
/card (moderator reduced)  | OK   | OK   | OK   | OK   | OK*  | OK   | OK   | OK   | WARN | OK
/card (finance financial)  | OK   | OK   | OK   | OK   | OK*  | OK   | OK   | OK   | WARN | OK
/legal                     | OK   | OK   | OK   | OK   | OK   | OK   | OK   | OK   | NO   | OK
/graph                     | — cohort-scope, participant не требуется
/audit                     | — глобальная, только owner
/life +1                   | NO   | OK   | OK   | OK   | WARN | WARN | NO   | NO   | NO   | OK
/life −1                   | NO   | OK   | OK   | OK   | WARN | NO   | NO   | NO   | NO   | OK
/pause (author)            | NO   | OK   | WARN | NO   | WARN | NO   | NO   | NO   | NO   | OK
/unpause (author)          | —    | —    | —    | OK   | —    | —    | —    | —    | —    | —
/unpause_user              | —    | —    | OK (квота сохраняется) | — | — | — | — | — | — | —
/set_shadow                | NO   | OK   | OK   | OK   | NO   | NO   | NO   | NO   | NO   | OK
/unshadow                  | —    | —    | —    | —    | OK   | —    | —    | —    | —    | —
/pause_grant               | NO   | OK   | OK   | OK   | WARN | NO   | NO   | NO   | NO   | OK
/approve                   | NO   | OK   | WARN | WARN | WARN | NO   | NO   | NO   | NO   | OK
/revert                    | NO   | OK (до Б7.7) | WARN | WARN | WARN | NO | NO | NO | NO | OK
/confirm_payment           | OK   | WARN | —    | —    | —    | OK   | NO   | NO   | NO   | —
/reject_payment            | OK   | WARN | —    | —    | —    | OK   | NO   | NO   | NO   | —
/refund                    | NO   | OK   | OK   | OK   | OK   | OK   | WARN | WARN | NO   | OK
/block   (только owner)    | OK   | OK   | OK   | OK   | OK   | OK   | WARN | NO   | NO   | OK
/unblock restore (owner)   | —    | —    | —    | —    | —    | —    | OK   | NO→force fresh | NO | —
/unblock fresh   (owner)   | —    | —    | —    | —    | —    | —    | OK   | OK   | NO   | —
✉️ через Бота              | OK   | OK   | OK   | OK   | WARN(shadow-lint) | WARN | WARN | NO | NO | OK
/mute                      | —    | OK   | OK   | OK   | OK   | OK   | —    | —    | NO   | WARN
/unmute                    | —    | —    | —    | —    | —    | —    | —    | —    | NO   | OK
/admin_add|remove|role     | — глобальные, только owner
```

Примечания:

- `OK*` в столбце `pause_shadow` для moderator/finance: карточка открывается, строка `pause_shadow` скрыта редукцией профиля (**NR-17.17**).
- `/block` и `/unblock` доступны ТОЛЬКО owner (**NR-17.14**, **NR-17.16**); никакой автомат не имеет права ставить `banned_*`.
- `/refund` при `banned_*` — OK с warning «участник забанен, деньги вернутся, доступ не восстановится».
- Каждая ячейка NO обязана возвращать конкретный диагноз, не generic-fail.

## МАТРИЦА «КОМАНДА × РОЛЬ»

| Команда | owner | moderator | finance |
|---------|-------|-----------|---------|
| `/card` (owner_full) | ✅ | ⛔ | ⛔ |
| `/card` (moderator_reduced) | ✅ | ✅ | — |
| `/card` (finance_financial) | ✅ | — | ✅ |
| `/legal` | ✅ | ⛔ | ⛔ |
| `/graph` | ✅ | ✅ | ⛔ |
| `/audit` | ✅ | ⛔ | ⛔ |
| `/life +1`, `/life −1` | ✅ | ✅ | ⛔ |
| `/pause`, `/unpause`, `/unpause_user` | ✅ | ✅ | ⛔ |
| `/pause_grant` | ✅ | ⛔ | ⛔ |
| `/set_shadow`, `/unshadow` | ✅ | ⛔ | ⛔ |
| `/approve`, `/revert` | ✅ | ✅ | ⛔ |
| ✉️ через Бота | ✅ | ✅ | ⛔ |
| `/confirm_payment`, `/reject_payment` | ✅ | ⛔ | ✅ |
| `/refund` | ✅ | ⛔ | ✅ |
| `/block`, `/unblock` | ✅ | ⛔ | ⛔ |
| `/mute`, `/unmute` | ✅ | ✅ | ⛔ |
| `/admin_add`, `/admin_remove`, `/admin_role` | ✅ | ⛔ | ⛔ |

Кнопки/ярлыки недоступной команды для роли — не рендерятся вовсе; отказ — `role_denied` в аудите.

---

# ПАТЧ к Блоку 17 (v3.3 → v3.4)

## Выжимка-патч

Блок 17 v3.4 закрывает три класса добора: (1) технические ловушки Telegram API, которые в редакции v3.3 могли положить прод — жёсткий лимит `callback_data` в 64 байта и HTML-парсинг; (2) обёртки над командами владельцев Б14/Б15/Б16/инфры, без которых Автор физически не может воспользоваться фичами этих блоков (Mini App, `baseline_override`, `publish_epoch`, DLQ, антипираси-разморозка, финансовый дашборд, panic-режим); (3) точечные исправления матрицы и саги рефанда.

**Callback payload переопределяется (NR-17.19).** В `callback_data` кладётся ТОЛЬКО `{dialog_id_short, step, nonce}` суммарно не более ~22 байт (лимит Telegram 64 байта). Всё остальное — `cmd`, `participant_id`, `params`, `schema_version`, `actor_id`, `expected_*` — хранится в durable-состоянии мастера (Redis/PG, ключ = `dialog_id`, TTL = TTL мастера + запас), читается диспетчером по `dialog_id` в момент клика. Побочный полезный эффект: злоумышленник не может подменить `participant_id`/`cmd` в payload’е — они физически отсутствуют в кнопке. Это дополнительно усиливает **NR-17.2**.

**HTML-санитайзер для ✉️ (NR-17.20).** На шаге ввода текста мастера `write_via_bot` ввод Автора пропускается через санитайзер владельца Б9 ДО предпросмотра: `<`, `>`, `&` экранируются, разрешённые теги (по allow-list Б9) сохраняются. Автор видит на предпросмотре ровно тот текст, что уйдёт участнику. Невалидная неисправимая разметка → warning на предпросмотре + предложение «переключиться в plain-text»; отправка сообщения с невалидным HTML запрещена — мастер не «зависает», а отклоняет отправку с диагностикой.

**Форум-топики — dynamic binding (NR-17.21).** `admin_topic` и другие форум-темы Б8 адресуются через `topic_bindings: {alias → message_thread_id}`. Команда `/bind_topic <alias>` (reply на сообщение в теме, только owner, двухшаг для перепривязки существующего alias) обновляет маппинг. Если `admin_topic` не привязан — все broadcast’ы (whitelist, `/set_shadow`, `/publish_stage`, `/panic`) fallback’ат в личку обоим owner + системный алерт «admin_topic не привязан, привяжите через `/bind_topic admin_topic`». Хардкод `thread_id` в YAML запрещён.

**Гонка refund vs sweeper-guard (NR-17.22).** Сага `/refund` дополняется атомарным preflight-шагом 0: одной транзакцией устанавливаются флаги `visibility: out_of_scope` и `modifier: freeze_refund` на участнике ДО перевода платежа в `refund_pending`. Sweeper-guard Б15/Б16 обязан читать оба флага и отказывать в выдаче контента / до-начислений, если хотя бы один установлен. Флаги снимаются только при финализации саги (`refunded`) или ручном откате owner’ом из `pending_ops_review`. Гарантия: между решением «возвращаем деньги» и переходом в `sleeping` участник не получит новый контент.

**Panic-режим (NR-17.23).** `/panic_maintenance` (только owner, один тап без двухшага для скорости, требует подтверждения ввода TG-username инициатора для защиты от случайного тапа) переводит систему в `maintenance = true`: глобальная приостановка выдачи, отключение webhook, рассылка T1-MAINT через Б9. Снимается ТОЛЬКО через `/unpanic <passphrase>`, где passphrase хранится в durable bootstrap-файле (там же, где owner-ID, Р459). Каждое `/panic` и `/unpanic` — обязательный broadcast обоим owner в admin-тему + операционный аудит. `/panic` работает даже при промахе whitelist-кэша (аналогично bootstrap-режиму), потому что паника нужна именно когда система сломана.

**Матрица «команда × состояние» — исправление.** `/approve × pause_shadow = OK` (было WARN, ошибка): `pause_shadow(reason: no_verdict)` — штатное ожидание вердикта Автора, `/approve` является единственным штатным выходом из этого состояния; предупреждать не о чем. Аналогично `/revert × pause_shadow = OK`. Все остальные ячейки матрицы v3.3 в силе.

**Новые команды-обёртки.** Каталог Б17 v3.4 расширяется тонкими обёртками над командами владельцев (Б17 не изобретает бизнес-правила — только даёт единый UX-контракт мастера, whitelist-гейт, идемпотентность, аудит): `/miniapp_toggle` (owner, двухшаг, глобально или по когорте), `/miniapp_stats` (read-only, owner), `/force_sync <pid>` (owner, двухшаг) — стык Б14; `/unfreeze_piracy <pid> <reason>` (owner, двухшаг, сбрасывает `is_suspended` и статус `anomaly_log`) — стык Б15; `/override_baseline <pid> <metric> <value> <reason>` (owner, двухшаг, попадает в приватностный аудит как `view: baseline_override`, триггерит инвалидацию кэша Б14) — стык Б14; `/publish_stage <stage_id>` и `/withdraw_stage <stage_id>` (owner, двухшаг, broadcast в admin-тему, генерируют `publish_epoch`) — стык Б14; `/dlq_view [reason]` (read-only, owner) и `/dlq_replay <dlq_id>` (owner, двухшаг, обязательная причина, идемпотентно по `dlq_id`, в аудите линкуется через `compensates:` к исходной операции) — стык Б15; `/finance_summary [period]` (read-only, owner + finance) — стык Б16; `/bind_topic <alias>` (owner, двухшаг для перепривязки существующего) — стык Б8. Все обёртки следуют общему контракту Б17: whitelist-гейт, короткий callback (Р492), мастер с тайм-аутом 10 мин, двухшаг для destructive, кнопки не доступной роли не рендерятся, `role_denied` в аудите.

**Правило «Б17 не изобретает».** Если контракт владельца ещё не финализирован в закрытой редакции своего блока, обёртка помечается `stub_awaiting_<block>` и в аудите её вызов идёт с `decision: stub_not_ready` до финализации. Это позволяет Б17 быть готовым синхронно с v3.4-релизами Б14/Б15/Б16, не опережая их.

## МАТРИЦА «КОМАНДА × СОСТОЯНИЕ» — исправления к v3.3

```text
Изменяются ТОЛЬКО две ячейки, остальные — по v3.3:
/approve × pause_shadow    | было WARN → стало OK  (штатный выход из pause_shadow)
/revert  × pause_shadow    | было WARN → стало OK  (штатный откат вердикта в том же состоянии)
```

Новые команды v3.4 в матрицу состояний добавляются как строки:

```text
/miniapp_toggle         | — глобальная, только owner
/miniapp_stats          | — глобальная/cohort, read-only owner
/force_sync             | onboarding OK | active OK | user_pause OK | author_pause OK | shadow OK | sleeping WARN | banned_soft WARN | banned_hard NO | erased NO | muted OK
/unfreeze_piracy        | onboarding OK | active OK | user_pause OK | author_pause OK | shadow OK | sleeping OK | banned_soft OK | banned_hard OK | erased NO | muted OK
/override_baseline      | onboarding OK | active OK | user_pause OK | author_pause OK | shadow OK | sleeping WARN | banned_soft WARN | banned_hard NO | erased NO | muted OK
/publish_stage          | — глобальная, только owner
/withdraw_stage         | — глобальная, только owner
/dlq_view               | — глобальная, read-only owner
/dlq_replay             | — глобальная, только owner, двухшаг
/finance_summary        | — cohort/global, read-only owner+finance
/bind_topic             | — глобальная, только owner
/panic_maintenance      | — глобальная, только owner, без двухшага
/unpanic                | — глобальная, только owner, требует passphrase
```

## МАТРИЦА «КОМАНДА × РОЛЬ» — дополнения к v3.3

```text
/miniapp_toggle, /miniapp_stats, /force_sync   | owner ✅ | moderator ⛔ | finance ⛔
/unfreeze_piracy                               | owner ✅ | moderator ⛔ | finance ⛔
/override_baseline                             | owner ✅ | moderator ⛔ | finance ⛔
/publish_stage, /withdraw_stage                | owner ✅ | moderator ⛔ | finance ⛔
/dlq_view, /dlq_replay                         | owner ✅ | moderator ⛔ | finance ⛔
/finance_summary                               | owner ✅ | moderator ⛔ | finance ✅
/bind_topic                                    | owner ✅ | moderator ⛔ | finance ⛔
/panic_maintenance, /unpanic                   | owner ✅ | moderator ⛔ | finance ⛔
```

## NR-инварианты, добавленные патчем v3.4

- **NR-17.18** — управление Mini App feature flags — только owner.
- **NR-17.19** — `callback_data` ≤ 64 байта; состояние мастера — в durable-хранилище.
- **NR-17.20** — ввод в `write_via_bot` санируется Б9 перед предпросмотром.
- **NR-17.21** — форум-темы через `alias → thread_id`, хардкод запрещён.
- **NR-17.22** — refund preflight-freeze выдачи ДО перевода платежа.
- **NR-17.23** — panic обходит whitelist-кэш; unpanic требует passphrase из bootstrap.

---

## ЕДИНЫЙ YAML-КОНТРАКТ БЛОКА 17

```yaml
block_17:
  name: "Панель Автора / командный режим"
  version: v3.3
  role: executor
  principle: "Б10 просит — владелец исполняет (расширено на все домены)"

  roles_final:
    owner:
      count_expected: 2
      access: [read_ops, moderation_ops, financial_ops, privacy_ops, admin_ops, ban_ops, mute_ops]
      card_view: owner_full
    moderator:
      access: [read_ops_reduced, moderation_ops_reduced, mute_ops]
      moderation_ops_reduced:
        includes: [life_plus, life_minus, pause, unpause, unpause_user, approve, revert, message_via_bot, mute, unmute]
        excludes: [pause_grant, set_shadow, unshadow, block, unblock, confirm_payment, reject_payment, refund, legal_view, audit_view, admin_ops]
      card_view: moderator_reduced
    finance:
      access: [read_ops_financial, financial_ops]
      financial_ops: [confirm_payment, reject_payment, refund]
      excludes: [moderation_ops, mute_ops, legal_view, audit_view, admin_ops, block, unblock, set_shadow, unshadow, pause_grant]
      card_view: finance_financial
    partner_deprecated: true

  whitelist:
    schema: {tg_user_id, role, added_by, added_at}
    gate_on: [reply_cmd, button_shortcut, callback, info_only_view]
    non_whitelisted: {action: ignore, notify_user: false, audit: true}
    cache:
      miss_policy: force_read_db_then_deny
      db_timeout_s: 3
      bootstrap_fallback: enabled
    min_owner_invariant: 1                     # NR-17.1
    mgmt:
      executor: single_owner
      co_confirmation: false
      peer_broadcast: mandatory
      broadcast_channel: admin_topic
      broadcast_policy: {delete: forbidden, edit: forbidden, mirror_to: b14_durable}
      weekly_digest_to: [owner_all]
      on_broadcast_delivery_fail: rollback_via_compensation

  bootstrap_mode:
    trigger: cache_and_db_miss
    source: durable_signed_bootstrap_file       # Б14/Б15
    contains: [owner_ids_max_2, signature, version]
    allowed_ops: [read_ops, admin_add]
    denied_ops: all_destructive                # NR-17.10
    alert_on_enter_exit: [owner_all]
    local_audit: durable_sync_on_recovery

  banning_invariant:
    NR_17_14: "БОТ НИКОГДА НЕ БАНИТ УЧАСТНИКА. Банит и разбанивает ТОЛЬКО owner."
    who_can_block: [owner]
    who_can_unblock: [owner]
    forbidden_auto_transitions_to: [banned_soft, banned_hard]
    allowed_auto_states: [sleeping, erased_by_b15, muted]
    auto_ban_attempt_policy:
      execute: false
      audit_event: auto_ban_blocked
      alert_owners: mandatory
      router_hard_reject: true
    escalation_when_ban_needed:
      auto_action: notify_owners
      message: "требуется решение о блокировке участника X, причина Y"
      decision_by: owner
      decision_via: /block
    domain_translations:
      lives_exhausted_b2: sleeping
      payment_missed_b16: sleeping
      reflection_incident_b7: sleeping_or_reject
      group_flood_b8: muted
      group_spam_b8: muted
      storage_expired_b15: erased

  muted_state:
    kind: temporary_group_emission_off
    is_ban: false
    setter: [auto_antiflood, auto_antispam, moderator, owner]
    unsetter: [moderator, owner]
    does_not_affect: [course_access, lives, payment, reflections]
    escalation_path: "moderator/owner может эскалировать до /block (решает owner)"

  pauses:
    types:
      user_pause:   {setter: participant, consumes_quota: true}
      author_pause: {setter: owner_moderator, consumes_quota: false}
      pause_shadow: {setter: auto_b7_or_owner_manual, visible_to_participant: false}
    unpause_user:
      quota_policy: preserve_remainder
      cooldown_after_force_unpause: none
      ux_confirm_note: "у участника остаётся X дней квоты паузы"
      cycle_prevention_owner: b2
    set_shadow:
      role_required: owner
      two_step: true
      reason: {required: true, source: fixed_code_list_from_b7, free_text: forbidden}
      peer_broadcast: mandatory
      disclaimer_on_confirm: "тайная пауза скрыта от участника; исключительная мера"
      auto_setter_still_allowed_by_b7: true
    unshadow:
      role_required: owner
      two_step: true

  commands:
    revert:          {domain: b7,  button: "↩ Revert",          params: [day?],           irreversible: true,  two_step: true,  scope: participant}
    life_plus:       {domain: b2,  button: "❤️ +Жизнь",          params: [reason?],        irreversible: true,  two_step: true,  scope: participant, expected: [lives]}
    life_minus:      {domain: b2,  button: "💔 −Жизнь",          params: [reason?],        irreversible: true,  two_step: true,  scope: participant, expected: [lives]}
    pause:           {domain: b2,  button: "⏸ Пауза",            params: [],               irreversible: true,  two_step: true,  scope: participant}
    unpause:         {domain: b2,  button: "▶️ Снять паузу",     params: [],               irreversible: true,  two_step: true,  scope: participant, targets: author_pause}
    unpause_user:    {domain: b2,  button: "▶️ Снять user_pause",params: [],               irreversible: true,  two_step: true,  scope: participant, targets: user_pause, quota: preserve}
    pause_grant:     {domain: b2,  button: "➕ Доп.пауза",       params: [grant_no, reason], irreversible: true, two_step: true, scope: participant, role: owner_only, expected: [pause_state]}
    set_shadow:      {domain: b7,  button: "🕶 Тайная пауза",    params: [reason_code!],   irreversible: true,  two_step: true,  scope: participant, role: owner_only, peer_broadcast: true}
    unshadow:        {domain: b7,  button: "☀ Снять shadow",     params: [],               irreversible: true,  two_step: true,  scope: participant, role: owner_only}
    approve:         {domain: b7,  button: "✅ Зачесть рефлексию", params: [],             irreversible: true,  two_step: true,  scope: participant, expected: [reflection_id, verdict_version=pending]}
    confirm_payment: {domain: b16, button: "✅ Подтвердить",       params: [],             irreversible: true,  two_step: true,  scope: participant, expected: [payment_id, status]}
    reject_payment:  {domain: b16, button: "✖ Отклонить",          params: [reason],       irreversible: true,  two_step: true,  scope: participant, expected: [payment_id, status]}
    refund:          {domain: b16, button: "↩️ Refund",            params: [reason!],      irreversible: true,  two_step: true,  scope: participant, saga: true, idempotency: one_shot, expected: [payment_id=confirmed]}
    block:           {domain: b10, button: "🔒",                   params: [reason?],      irreversible: true,  two_step: true,  scope: participant, role: owner_only}
    unblock:         {domain: b10, button: "🔓",                   params: [mode: restore|fresh], irreversible: true, two_step: true, scope: participant, role: owner_only, expected: [ban_mod, window_open]}
    mute:            {domain: b8,  button: "🔇",                   params: [duration?],    irreversible: false, two_step: false, scope: participant}
    unmute:          {domain: b8,  button: "🔊",                   params: [],             irreversible: false, two_step: false, scope: participant}
    card:            {domain: b6,  button: "📇 Карточка",           read_only: true,       two_step: false, scope: participant, view_profile_by_role: true}
    legal:           {domain: legal, button: "⚖️ Юр.данные",        read_only: true,       two_step: false, scope: participant, role: owner_only}
    message_via_bot: {domain: b8,  button: "✉️",                   params: [text!],        irreversible: after_send, two_step: preview_confirm, scope: participant, shadow_lint: true}
    graph:           {domain: b7,  button: null,                   params: [window: 7|14], read_only: true,   two_step: false, scope: cohort}
    audit:           {domain: b14, params: [participant_id?],      read_only: true,        two_step: false, scope: participant_or_global, role: owner_only, self_log: true}
    admin_add:       {domain: b17, params: [tg_id, role],          irreversible: true,     two_step: true,  scope: global, role: owner_only, peer_broadcast: true}
    admin_remove:    {domain: b17, params: [tg_id],                irreversible: true,     two_step: true,  scope: global, role: owner_only, peer_broadcast: true, guard: min_owner_1}
    admin_role:      {domain: b17, params: [tg_id, role],          irreversible: true,     two_step: true,  scope: global, role: owner_only, peer_broadcast: true, guard: min_owner_1}

  removed_forever:
    place:
      status: removed_v3_1
      router_policy: hard_reject
      legacy_callback_prefix: "place_*"
      on_attempt: {execute: false, audit: place_attempted, notify_group: v3_1_reminder}

  input_hybrid:
    buttons_for: [frequent_simple]
    reply_cmd_for: [parametric, rare]
    button_binds_participant_from: message_context
    reply_without_target: {execute: false, hint: "укажите участника (reply)"}

  wizard:
    stages: [confirm_participant_if_scope_participant, params, two_step_confirm]
    timeout_min: 10
    on_timeout: {execute: false, audit: dialog_timeout}
    concurrency: one_active_per {actor_id, cmd, participant_id}
    per_participant_advisory_lock: {ttl_min: 10, heartbeat: true, applies_to: destructive_ops}
    owner_preempt: {command: "⛔ Перехватить", two_step: true, audit: wizard_preempted_by_owner}
    callback_payload: {cmd, participant_id, dialog_id, step, schema_version, nonce}

  two_step_confirm:
    required_when: [irreversible, money, lives, privilege_change, ban_ops]
    yes_button_position: "not_at_first_button_slot"
    on_state_change_between_steps:
      restore_fresh_downgrade: new_confirm_screen        # NR-17.4
      stale_expected: {execute: false, audit: stale_state_reject}   # NR-17.3
    read_only_actions: one_tap
    post_execute_ui: disable_buttons_edit_message

  idempotency:
    one_shot_ops: [refund, admin_remove, admin_role, pause_grant]
    one_shot_key: "hash(actor_id, cmd, resource_id)"        # params EXCLUDED
    repeatable_key: "hash(actor_id, cmd, participant_id, dialog_id)"
    ttl_financial_h: 24
    ttl_other_h: 1
    repeat_within_ttl: returns_previous_result
    storage: b14_durable

  refund_saga:
    coordinator: b16
    steps:
      - {block: b16, action: "payment: confirmed -> refund_pending"}
      - {block: b10, action: "state -> sleeping"}
      - {block: b13, action: "revoke_access_to_completed_materials"}
      - {block: b15, action: "physical_delete_personal_artifacts", timeout_h: 24}
      - {block: b16, action: "payment: refund_pending -> refunded"}
    ui_cascade_disclosure_required: true
    partial_failure_status: pending_ops_review              # NR-17.7
    auto_rollback_of_steps_1_2: false
    manual_resolution_by: owner
    idempotent_resume: true

  refund_when_banned:
    banned_soft: allowed_with_warning
    banned_hard: allowed_with_warning
    erased: hard_reject
    warning_text: "участник забанен; деньги вернутся, доступ к курсу не восстановится"
    retention_debt: [b15, b16]

  approve_revert_semantics:
    approve_button_label: "✅ Зачесть рефлексию"
    approve_writes: "verdict: pending -> approved (b7.6)"
    approve_does_not_apply_pass: true
    pass_applies_at: b7.7
    revert_window: "до применения перехода Дня 14 (b7.7)"
    after_pass_applied:
      revert_ui: hidden_with_plate "День уже перевыдан"
      day_rollback: debt_b7

  message_via_bot_gate:
    active:        OK
    user_pause:    OK
    author_pause:  OK
    sleeping:      WARN
    banned_soft:   WARN
    banned_hard:   {block: true, audit: send_blocked_hard_ban}
    erased:        {block: true, audit: send_blocked_erased}
    pause_shadow:  {allow: true, lint_disclosure: true, ack_required: shadow_disclosure_ack}
    idempotency: single_send
    audit_body: hash_only

  reject_new_receipt_flow:
    on_reject: {status: rejected, ui: disable_buttons}
    on_new_receipt: {new_card: true, new_payment_id: true, link_to_previous: "предыдущая попытка отклонена <ts>, причина X"}
    two_receipts_independent: true

  card_view_profiles:
    owner_full: {shows: all}
    moderator_reduced:
      hides: [sensitive_health, pause_shadow]
      replaces_with: "⚖ Данные закрыты. Обратитесь к owner"
    finance_financial:
      shows: [payments, payment_status, access_active, course_start_date]
      hides: [lives, reflections, pauses_details, pause_shadow, sensitive_health]
      shows_flag: "участник неактивен по не-финансовой причине (без деталей)"

  command_role_matrix:
    read:
      card_owner:      [owner]
      card_reduced:    [owner, moderator]
      card_financial:  [owner, finance]
      legal:           [owner]
      graph:           [owner, moderator]
      audit:           [owner]
    moderation:
      life_plus:       [owner, moderator]
      life_minus:      [owner, moderator]
      pause:           [owner, moderator]
      unpause:         [owner, moderator]
      unpause_user:    [owner, moderator]
      approve:         [owner, moderator]
      revert:          [owner, moderator]
      message_via_bot: [owner, moderator]
    privileged_moderation:
      pause_grant:     [owner]
      set_shadow:      [owner]
      unshadow:        [owner]
    finance:
      confirm_payment: [owner, finance]
      reject_payment:  [owner, finance]
      refund:          [owner, finance]
    lifecycle_ban:
      block:           [owner]
      unblock:         [owner]
    group_moderation:
      mute:            [owner, moderator, auto]
      unmute:          [owner, moderator]
    admin:
      admin_add:       [owner]
      admin_remove:    [owner]
      admin_role:      [owner]
    on_role_denied:
      execute: false
      ui_render: hidden_button
      audit_event: role_denied

  audit:
    operational:
      schema: {ts_server, actor_id, actor_role, cmd, participant_id, params, dialog_id, decision, reason, operation_key, schema_version, compensates?}
      decisions: [executed, rejected, ignored, stale_state_reject, dialog_timeout, place_attempted, role_denied, auto_ban_blocked, wizard_preempted_by_owner, send_blocked_hard_ban, send_blocked_erased]
      retention: forever
      transaction: same_as_state_change              # Р429
    privacy_152fz:
      schema: {ts, actor_id, participant_id, view}
      views: [card_owner, card_reduced, card_financial, legal, graph, full_change_map]
      retention: forever
      backpressure: block_view_on_queue_overflow
    audit_read_cmd:
      name: /audit
      access: owner
      self_log: true
    peer_visibility:
      destructive_ops_broadcast: admin_topic
      format: "<actor> · <cmd> · <participant> · <decision>"
    weekly_digest:
      to: owner_all
      contents: [admin_actions_7d_summary_by_class]

  compensation_model:
    rollback_supported: false
    undo_via: semantic_inverse_operation
    audit_link_field: "compensates: <original_operation_key>"
    pairs:
      life_minus: life_plus
      revert: approve_within_b7_7
      block: unblock_restore_if_window_open
      admin_remove: admin_add
      refund_finalized: manual_reissue    # долг Б16
      message_sent: none_apology_only

  atomicity_delegation:
    lives: {block: b2, method: SELECT_FOR_UPDATE, bounds: [0, 3]}
    payment: {block: b16, method: one_shot_refund}
    revert: {block: b7, method: serialized_by_operation_key}
    pause_grant: {block: b2, method: check_then_grant}
    unban: {block: b10, method: window_check_then_mode, no_silent_downgrade: true}

  interfaces_out:
    to_b2:  [life_ops, pause_ops, unpause_user, pause_grant]
    to_b6:  [card_render_by_view_profile, action_buttons_bind]
    to_b7:  [revert, approve, set_shadow, unshadow, graph_render_cohort]
    to_b8:  [message_via_bot, mute, unmute, admin_topic_publish]
    to_b9:  [wizard_timeout_notice, peer_alerts, escalation_ban_request, weekly_digest]
    to_b10: [block_owner_only, unblock_restore_or_fresh_owner_only]
    to_b13: [saga_revoke_access]
    to_b14: [operational_audit, privacy_audit, idempotency_keys, advisory_locks, admin_topic_mirror, bootstrap_file]
    to_b15: [erased_flag_contract, refund_recipient_retention]
    to_b16: [confirm_payment, reject_payment, refund_saga_coordinator]
    to_legal: [legal_view]

  boundaries:
    owns: [command_catalog, button_shortcuts, wizard_ux, whitelist_gate, roles_model, roles_matrix, audit_of_calls, idempotency_wrapper, bootstrap_mode]
    executes_only: [b2_rules, b7_rules, b10_rules, b16_rules, b6_render_rules, b8_group_rules, legal_storage_rules]
    does_not: [introduce_business_rules, restore_place, direct_write_to_participant_domain_state, allow_auto_ban]

  nr_invariants:
    NR_17_1:  "whitelist has >=1 owner"
    NR_17_2:  "participant_id from confirm-step callback only"
    NR_17_3:  "state change requires expected_* match"
    NR_17_4:  "no silent downgrade of irreversible ops"
    NR_17_5:  "/place never restored"
    NR_17_6:  "whitelist mgmt requires peer_broadcast to admin_topic"
    NR_17_7:  "refund saga partial failure => pending_ops_review, no auto rollback of steps 1-2"
    NR_17_8:  "unpause_user preserves user_pause quota; cycle rule owned by b2"
    NR_17_9:  "message_via_bot on pause_shadow requires shadow_disclosure_ack"
    NR_17_10: "bootstrap mode allows only read_ops and admin_add"
    NR_17_11: "undo = compensating action; rollback never"
    NR_17_12: "broadcast in same transaction as audit write"
    NR_17_13: "partner role deprecated; final composition = owner x2 + moderator + finance"
    NR_17_14: "БОТ НИКОГДА НЕ БАНИТ. Банит только owner. Автомат допускает только sleeping/erased/muted"
    NR_17_15: "whitelist and set_shadow broadcasts are not deletable by initiator"
    NR_17_16: "unblock owner-only (symmetry with block)"
    NR_17_17: "finance never sees pause_shadow"

block_17_patch:
  version: v3.4
  supersedes_fragments: [callback_payload_v3_3, refund_saga_steps_v3_3, matrix_approve_shadow_v3_3]

  callback_payload_redesign:
    NR_17_19: "callback_data ≤ 64 байта; состояние мастера в durable-хранилище"
    payload_in_button: {dialog_id_short: "12-16 base62", step: "1 byte", nonce: "4 bytes"}
    payload_max_bytes: 22
    stored_in_durable_state: [cmd, participant_id, actor_id, params, schema_version, expected_state]
    state_storage: {backend: redis_or_pg, key: dialog_id, ttl: wizard_ttl + margin}
    on_dialog_id_not_found: {execute: false, ui: "Мастер устарел или отменён", audit: dialog_expired}
    security_side_effect: "participant_id и cmd физически не в payload — исключает подмену"

  html_sanitizer_message_via_bot:
    NR_17_20: "ввод в write_via_bot проходит через санитайзер Б9 перед предпросмотром"
    stage: before_preview
    owner_of_sanitizer: b9
    escape: ["<", ">", "&"]
    preserve_allowed_tags: by_b9_allowlist
    on_unparseable_html:
      preview_warning: true
      offer_switch_to_plaintext: true
      block_send_until_resolved: true
    guarantee: "мастер не зависает; либо санированный текст, либо явный отказ с диагностикой"

  forum_topic_binding:
    NR_17_21: "форум-темы Б8 адресуются через alias→thread_id маппинг"
    topic_bindings_source: durable_config
    known_aliases: [admin_topic, ...]
    bind_topic_cmd:
      role: owner
      trigger: reply_on_message_in_topic
      two_step_when: rebinding_existing_alias
    fallback_when_admin_topic_unbound:
      broadcasts_go_to: [owner_pm_all]
      system_alert: "admin_topic не привязан, привяжите через /bind_topic admin_topic"
    hardcoded_thread_id_in_yaml: forbidden

  refund_saga_v3_4:
    NR_17_22: "preflight-заморозка выдачи ДО перевода платежа"
    steps:
      - {step: 0, block: b17_coordinator, action: "atomically set visibility=out_of_scope AND modifier=freeze_refund on participant"}
      - {step: 1, block: b16, action: "payment: confirmed -> refund_pending"}
      - {step: 2, block: b10, action: "state -> sleeping"}
      - {step: 3, block: b13, action: "revoke_access_to_completed_materials"}
      - {step: 4, block: b15, action: "physical_delete_personal_artifacts", timeout_h: 24}
      - {step: 5, block: b16, action: "payment: refund_pending -> refunded"}
    sweeper_guard_contract:
      readers: [b15, b16, b10_dispatchers]
      must_check: [visibility, modifier]
      on_flag_set: {emit_content: false, accrue: false, audit: sweeper_blocked_by_refund_freeze}
    flags_cleared_when: [refunded, manual_rollback_from_pending_ops_review]
    partial_failure_status: pending_ops_review

  panic_mode:
    NR_17_23: "panic обходит whitelist-кэш; unpanic требует passphrase"
    panic_maintenance:
      role: owner
      two_step: false
      confirmation_field: tg_username_of_initiator
      bypasses_cache: true
      effects: [maintenance_flag_on, webhook_off, broadcast_T1_MAINT_via_b9]
      broadcast_to_admin_topic: mandatory
      audit_event: panic_activated
    unpanic:
      role: owner
      requires_passphrase: true
      passphrase_source: durable_bootstrap_file
      broadcast_to_admin_topic: mandatory
      audit_event: panic_lifted_by

  new_commands_v3_4:
    miniapp_toggle:      {domain: b14, scope: global_or_cohort, role: owner_only, params: [target, on|off, reason], two_step: true, stub_awaiting_b14: true}
    miniapp_stats:       {domain: b14, scope: global_or_cohort, role: owner_only, read_only: true, stub_awaiting_b14: true}
    force_sync:          {domain: b14, scope: participant,      role: owner_only, params: [pid], two_step: true, stub_awaiting_b14: true}
    unfreeze_piracy:     {domain: b15, scope: participant,      role: owner_only, params: [pid, reason!], two_step: true, effects: [reset_is_suspended, reset_anomaly_log_status], stub_awaiting_b15: true}
    override_baseline:   {domain: b14, scope: participant,      role: owner_only, params: [pid, metric, value, reason!], two_step: true, privacy_audit_view: baseline_override, side_effect: invalidate_b14_cache, stub_awaiting_b14: true}
    publish_stage:       {domain: b14, scope: global,           role: owner_only, params: [stage_id], two_step: true, effects: [emit_publish_epoch], peer_broadcast: mandatory, stub_awaiting_b14: true}
    withdraw_stage:      {domain: b14, scope: global,           role: owner_only, params: [stage_id, reason], two_step: true, effects: [emit_publish_epoch_withdraw], peer_broadcast: mandatory, stub_awaiting_b14: true}
    dlq_view:            {domain: b15, scope: global,           role: owner_only, read_only: true, params: [reason?], stub_awaiting_b15: true}
    dlq_replay:          {domain: b15, scope: dlq_item,         role: owner_only, params: [dlq_id, reason!], two_step: true, idempotency: one_shot_by_dlq_id, audit_link: "compensates: original_op_key", stub_awaiting_b15: true}
    finance_summary:     {domain: b16, scope: global_or_cohort, role: [owner, finance], read_only: true, params: [period?]}
    bind_topic:          {domain: b8,  scope: config,           role: owner_only, params: [alias], trigger: reply_on_topic, two_step_when: rebinding_existing, stub_awaiting_b8: false}
    panic_maintenance:   {domain: b17, scope: global,           role: owner_only, two_step: false, confirmation_field: tg_username_of_initiator, bypasses_cache: true}
    unpanic:             {domain: b17, scope: global,           role: owner_only, params: [passphrase!], peer_broadcast: mandatory}

  matrix_command_state_delta:
    approve_x_pause_shadow: {from: WARN, to: OK, reason: "штатный выход из pause_shadow(no_verdict)"}
    revert_x_pause_shadow:  {from: WARN, to: OK, reason: "штатный откат вердикта в том же состоянии"}

  role_matrix_delta:
    miniapp_toggle: [owner]
    miniapp_stats: [owner]
    force_sync: [owner]
    unfreeze_piracy: [owner]
    override_baseline: [owner]
    publish_stage: [owner]
    withdraw_stage: [owner]
    dlq_view: [owner]
    dlq_replay: [owner]
    finance_summary: [owner, finance]
    bind_topic: [owner]
    panic_maintenance: [owner]
    unpanic: [owner]

  b17_does_not_invent_rule:
    principle: "если владелец не финализировал контракт — обёртка помечена stub_awaiting_<block>"
    stub_audit_decision: stub_not_ready

  new_nr_invariants:
    NR_17_18: "управление Mini App feature flags — только owner"
    NR_17_19: "callback_data ≤ 64 байта; состояние мастера — в durable-хранилище"
    NR_17_20: "ввод в write_via_bot санируется Б9 перед предпросмотром"
    NR_17_21: "форум-темы через alias→thread_id, хардкод запрещён"
    NR_17_22: "refund preflight-freeze выдачи ДО перевода платежа"
    NR_17_23: "panic обходит whitelist-кэш; unpanic требует passphrase из bootstrap"
```
