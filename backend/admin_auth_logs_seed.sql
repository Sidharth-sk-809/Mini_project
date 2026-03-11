-- ──────────────────────────────────────────────────────────────
--  admin_auth_logs — Schema + Dummy data
--  Run sql_schema.sql (and admin_auth_logs_schema part below)
--  before running the INSERT block.
-- ──────────────────────────────────────────────────────────────

-- ── 1. Table definition ───────────────────────────────────────

create table if not exists admin_auth_logs (
  id            bigserial primary key,

  -- Who triggered the event (NULL for failed logins with unknown email)
  user_id       bigint null references users(id) on delete set null,

  -- Denormalised so the row stays meaningful even if the user is deleted
  email         varchar(255) not null,
  role          varchar(40)  not null default 'shop_admin'
                  check (role in ('admin', 'shop_admin')),

  -- Shop context — populated for shop_admin events
  shop_id       bigint null references shops(id) on delete set null,
  shop_code     varchar(64) null,

  -- Event classification
  event_type    varchar(60)  not null
                  check (event_type in (
                    'login_success',
                    'login_failure',
                    'logout',
                    'token_refresh',
                    'unauthorized_access',
                    'account_created',
                    'password_change'
                  )),

  -- HTTP / network context
  ip_address    varchar(45)  null,
  user_agent    text         null,

  -- Response status code returned to the client
  http_status   smallint     not null default 200,

  -- Optional human-readable detail
  detail        text         null,

  created_at    timestamptz  not null default now()
);

create index if not exists idx_aal_user_id    on admin_auth_logs (user_id);
create index if not exists idx_aal_shop_id    on admin_auth_logs (shop_id);
create index if not exists idx_aal_created_at on admin_auth_logs (created_at desc);
create index if not exists idx_aal_event_type on admin_auth_logs (event_type);


-- ── 2. Dummy data ─────────────────────────────────────────────
--  Cast v.created_at::timestamptz fixes:
--  "column created_at is of type timestamptz but expression is of type text"

insert into admin_auth_logs
  (user_id, email, role, shop_id, shop_code, event_type, ip_address, user_agent, http_status, detail, created_at)
select
  v.user_id,
  v.email,
  v.role,
  s.id                      as shop_id,
  s.code                    as shop_code,
  v.event_type,
  v.ip_address,
  v.user_agent,
  v.http_status::smallint,
  v.detail,
  v.created_at::timestamptz          -- ← explicit cast fixes the type error
from (values

  -- ── Platform admin ──────────────────────────────────────────

  (1,'admin@neamet.app','admin',null,
   'login_success','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   200,null,
   '2026-03-01 09:00:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: ravi@greenbasket.com for green_basket',
   '2026-03-01 09:05:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: priya@paperpoint.com for paper_point',
   '2026-03-01 09:06:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: suresh@freshfarm.com for fresh_farm_market',
   '2026-03-01 09:07:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: anitha@studyworld.com for study_world',
   '2026-03-01 09:08:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: binu@medicohub.com for medico_hub',
   '2026-03-01 09:09:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: lijo@cityveggies.com for city_veggies',
   '2026-03-01 09:10:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: manu@smartstat.com for smart_stationers',
   '2026-03-01 09:11:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: thomas@pipemaster.com for pipemaster_tools',
   '2026-03-01 09:12:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'account_created','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   201,'Created shop_admin: sheena@bakehouse.com for bake_house_delight',
   '2026-03-01 09:13:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'token_refresh','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   200,null,
   '2026-03-01 13:00:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'logout','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/123 Safari/537.36',
   200,null,
   '2026-03-01 18:30:00+05:30'),

  -- ── Shop admins — first logins ───────────────────────────────

  (2,'ravi@greenbasket.com','shop_admin','green_basket',
   'login_success','106.193.44.21',
   'Mozilla/5.0 (Linux; Android 13; Pixel 7) Mobile Safari/537.36',
   200,'First login after account creation',
   '2026-03-01 10:00:00+05:30'),

  (3,'priya@paperpoint.com','shop_admin','paper_point',
   'login_success','117.200.88.60',
   'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0) Safari/604.1',
   200,'First login after account creation',
   '2026-03-01 10:15:00+05:30'),

  (4,'suresh@freshfarm.com','shop_admin','fresh_farm_market',
   'login_success','103.47.12.99',
   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/123',
   200,'First login after account creation',
   '2026-03-01 10:30:00+05:30'),

  (5,'anitha@studyworld.com','shop_admin','study_world',
   'login_success','49.204.11.33',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X) Safari/17',
   200,'First login after account creation',
   '2026-03-01 11:00:00+05:30'),

  (6,'binu@medicohub.com','shop_admin','medico_hub',
   'login_success','122.161.55.77',
   'Mozilla/5.0 (Linux; Android 12; Samsung SM-A52) Mobile Safari/537.36',
   200,'First login after account creation',
   '2026-03-01 11:15:00+05:30'),

  -- city_veggies — wrong password then success
  (null,'lijo@cityveggies.com','shop_admin','city_veggies',
   'login_failure','14.139.200.42',
   'Mozilla/5.0 (Linux; Android 11; Redmi Note 9) Mobile Safari/537.36',
   401,'Invalid credentials — wrong password',
   '2026-03-01 11:29:00+05:30'),

  (7,'lijo@cityveggies.com','shop_admin','city_veggies',
   'login_success','14.139.200.42',
   'Mozilla/5.0 (Linux; Android 11; Redmi Note 9) Mobile Safari/537.36',
   200,null,
   '2026-03-01 11:31:00+05:30'),

  (8,'manu@smartstat.com','shop_admin','smart_stationers',
   'login_success','27.56.98.110',
   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Edge/120',
   200,'First login after account creation',
   '2026-03-01 12:00:00+05:30'),

  (9,'thomas@pipemaster.com','shop_admin','pipemaster_tools',
   'login_success','59.90.33.145',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit Safari',
   200,'First login after account creation',
   '2026-03-01 12:10:00+05:30'),

  (10,'sheena@bakehouse.com','shop_admin','bake_house_delight',
   'login_success','103.211.55.66',
   'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6) Safari/604.1',
   200,'First login after account creation',
   '2026-03-01 12:20:00+05:30'),

  -- ── Day 2 ────────────────────────────────────────────────────

  (1,'admin@neamet.app','admin',null,
   'login_success','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/123',
   200,null,
   '2026-03-02 08:45:00+05:30'),

  (null,'unknown@hacker.com','admin',null,
   'login_failure','185.220.101.4',
   'python-requests/2.31.0',
   401,'Login attempt with unregistered email',
   '2026-03-02 02:33:00+05:30'),

  (2,'ravi@greenbasket.com','shop_admin','green_basket',
   'login_success','106.193.44.21',
   'Mozilla/5.0 (Linux; Android 13; Pixel 7) Mobile Safari/537.36',
   200,null,
   '2026-03-02 09:00:00+05:30'),

  (2,'ravi@greenbasket.com','shop_admin','green_basket',
   'token_refresh','106.193.44.21',
   'Mozilla/5.0 (Linux; Android 13; Pixel 7) Mobile Safari/537.36',
   200,null,
   '2026-03-02 13:00:00+05:30'),

  (6,'binu@medicohub.com','shop_admin','medico_hub',
   'unauthorized_access','122.161.55.77',
   'Mozilla/5.0 (Linux; Android 12; Samsung SM-A52) Mobile Safari/537.36',
   403,'shop_admin attempted GET /api/admin/stats — platform admin endpoint',
   '2026-03-02 10:05:00+05:30'),

  (5,'anitha@studyworld.com','shop_admin','study_world',
   'logout','49.204.11.33',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X) Safari/17',
   200,null,
   '2026-03-02 17:00:00+05:30'),

  -- ── Day 3 ────────────────────────────────────────────────────

  (10,'sheena@bakehouse.com','shop_admin','bake_house_delight',
   'login_success','103.211.55.66',
   'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6) Safari/604.1',
   200,null,
   '2026-03-03 07:30:00+05:30'),

  (null,'thomas@pipemaster.com','shop_admin','pipemaster_tools',
   'login_failure','59.90.33.145',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit Safari',
   401,'Invalid credentials',
   '2026-03-03 09:01:00+05:30'),

  (9,'thomas@pipemaster.com','shop_admin','pipemaster_tools',
   'login_success','59.90.33.145',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit Safari',
   200,null,
   '2026-03-03 09:03:00+05:30'),

  (3,'priya@paperpoint.com','shop_admin','paper_point',
   'password_change','117.200.88.60',
   'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0) Safari/604.1',
   200,'Password updated by user',
   '2026-03-03 11:00:00+05:30'),

  (8,'manu@smartstat.com','shop_admin','smart_stationers',
   'unauthorized_access','27.56.98.110',
   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Edge/120',
   404,'Product not found in own shop — possible cross-shop access attempt',
   '2026-03-03 14:22:00+05:30'),

  (4,'suresh@freshfarm.com','shop_admin','fresh_farm_market',
   'token_refresh','103.47.12.99',
   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/123',
   200,null,
   '2026-03-03 15:00:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'login_success','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/123',
   200,null,
   '2026-03-03 10:00:00+05:30'),

  (1,'admin@neamet.app','admin',null,
   'logout','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/123',
   200,null,
   '2026-03-03 10:45:00+05:30'),

  -- ── Day 4–5 ──────────────────────────────────────────────────

  (2,'ravi@greenbasket.com','shop_admin','green_basket',
   'login_success','106.193.44.21',
   'Mozilla/5.0 (Linux; Android 13; Pixel 7) Mobile Safari/537.36',
   200,null,
   '2026-03-04 08:55:00+05:30'),

  (6,'binu@medicohub.com','shop_admin','medico_hub',
   'login_success','122.161.55.77',
   'Mozilla/5.0 (Linux; Android 12; Samsung SM-A52) Mobile Safari/537.36',
   200,null,
   '2026-03-04 09:00:00+05:30'),

  (7,'lijo@cityveggies.com','shop_admin','city_veggies',
   'login_success','14.139.200.42',
   'Mozilla/5.0 (Linux; Android 11; Redmi Note 9) Mobile Safari/537.36',
   200,null,
   '2026-03-04 09:30:00+05:30'),

  (5,'anitha@studyworld.com','shop_admin','study_world',
   'login_success','49.204.11.33',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X) Safari/17',
   200,null,
   '2026-03-05 09:00:00+05:30'),

  (9,'thomas@pipemaster.com','shop_admin','pipemaster_tools',
   'login_success','59.90.33.145',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit Safari',
   200,null,
   '2026-03-05 09:15:00+05:30'),

  (3,'priya@paperpoint.com','shop_admin','paper_point',
   'login_success','117.200.88.60',
   'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0) Safari/604.1',
   200,'Login after password change',
   '2026-03-05 10:00:00+05:30'),

  (null,'admin@neamet.app','admin',null,
   'login_failure','45.155.205.11',
   'curl/7.88.1',
   401,'Failed login — possible credential stuffing from suspicious IP',
   '2026-03-05 03:17:00+05:30'),

  (null,'admin@neamet.app','admin',null,
   'login_failure','45.155.205.11',
   'curl/7.88.1',
   401,'Repeated failed login attempt',
   '2026-03-05 03:19:00+05:30'),

  -- ── Current day (2026-03-11) ─────────────────────────────────

  (1,'admin@neamet.app','admin',null,
   'login_success','49.37.201.12',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/124',
   200,'Admin logged in for daily review',
   '2026-03-11 09:00:00+05:30'),

  (2,'ravi@greenbasket.com','shop_admin','green_basket',
   'login_success','106.193.44.21',
   'Mozilla/5.0 (Linux; Android 13; Pixel 7) Mobile Safari/537.36',
   200,null,
   '2026-03-11 09:05:00+05:30'),

  (10,'sheena@bakehouse.com','shop_admin','bake_house_delight',
   'login_success','103.211.55.66',
   'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6) Safari/604.1',
   200,null,
   '2026-03-11 09:10:00+05:30'),

  (8,'manu@smartstat.com','shop_admin','smart_stationers',
   'login_success','27.56.98.110',
   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Edge/120',
   200,null,
   '2026-03-11 09:20:00+05:30'),

  (4,'suresh@freshfarm.com','shop_admin','fresh_farm_market',
   'token_refresh','103.47.12.99',
   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/123',
   200,null,
   '2026-03-11 11:00:00+05:30'),

  (6,'binu@medicohub.com','shop_admin','medico_hub',
   'login_success','122.161.55.77',
   'Mozilla/5.0 (Linux; Android 12; Samsung SM-A52) Mobile Safari/537.36',
   200,null,
   '2026-03-11 11:30:00+05:30')

) as v(user_id, email, role, shop_code, event_type, ip_address, user_agent, http_status, detail, created_at)
left join shops s on s.code = v.shop_code;
