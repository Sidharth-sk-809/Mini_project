-- Neamet schema for Supabase Postgres

create table if not exists users (
  id bigserial primary key,
  name varchar(120) not null,
  email varchar(255) not null unique,
  password_hash varchar(255) not null,
  role varchar(40) not null default 'customer' check (role in ('customer','delivery_person','admin')),
  location varchar(255) not null default 'Edappally, Kochi',
  created_at timestamptz not null default now()
);

create table if not exists shops (
  id bigserial primary key,
  code varchar(64) not null unique,
  name varchar(120) not null,
  shop_type varchar(80) not null,
  distance_km integer not null check (distance_km in (2,5,10)),
  delivery_available boolean not null default true
);

create table if not exists products (
  id bigserial primary key,
  code varchar(64) not null unique,
  name varchar(120) not null,
  subtitle varchar(80) not null,
  image varchar(255) not null,
  price numeric(10,2) not null,
  rating numeric(3,2) not null default 4.5,
  review_count integer not null default 20,
  description text not null,
  stock integer not null default 10,
  shop_id bigint not null references shops(id) on delete cascade
);

create index if not exists idx_products_name on products (name);
create index if not exists idx_products_shop_id on products (shop_id);

create table if not exists customer_orders (
  id bigserial primary key,
  order_code varchar(100) not null unique,
  customer_user_id bigint not null references users(id),
  delivery_address varchar(255) not null,
  status varchar(40) not null default 'placed',
  created_at timestamptz not null default now()
);

create table if not exists shop_orders (
  id bigserial primary key,
  shop_order_code varchar(100) not null unique,
  customer_order_id bigint not null references customer_orders(id) on delete cascade,
  shop_id bigint not null references shops(id),
  status varchar(40) not null default 'placed',
  delivery_job_status varchar(40) not null default 'available',
  selected_delivery_type varchar(30) not null default 'home_delivery',
  delivery_fee numeric(10,2) not null default 0,
  eta_minutes integer not null default 30,
  assigned_delivery_user_id bigint null references users(id),
  assigned_delivery_name varchar(120) null
);

create index if not exists idx_shop_orders_customer_order_id on shop_orders (customer_order_id);
create index if not exists idx_shop_orders_shop_id on shop_orders (shop_id);

create table if not exists shop_order_items (
  id bigserial primary key,
  shop_order_id bigint not null references shop_orders(id) on delete cascade,
  product_id bigint not null references products(id),
  quantity integer not null default 1,
  price numeric(10,2) not null
);

create index if not exists idx_shop_order_items_shop_order_id on shop_order_items (shop_order_id);
create index if not exists idx_shop_order_items_product_id on shop_order_items (product_id);
