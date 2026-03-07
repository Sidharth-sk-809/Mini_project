import os
from contextlib import contextmanager

from dotenv import load_dotenv
from sqlalchemy import MetaData, create_engine, text

load_dotenv()


def normalize_url(url: str) -> str:
    u = url.strip()
    if u.startswith('postgres://'):
        u = u.replace('postgres://', 'postgresql+psycopg2://', 1)
    elif u.startswith('postgresql://'):
        u = u.replace('postgresql://', 'postgresql+psycopg2://', 1)
    if u.startswith('postgresql+psycopg2://') and 'sslmode=' not in u:
        sep = '&' if '?' in u else '?'
        u = f'{u}{sep}sslmode=require'
    return u


SOURCE_DATABASE_URL = os.getenv('SOURCE_DATABASE_URL', 'sqlite:///./neamet.db')
TARGET_DATABASE_URL = normalize_url(os.getenv('DATABASE_URL', ''))

if not TARGET_DATABASE_URL:
    raise RuntimeError('DATABASE_URL is required and should point to Supabase Postgres')

TABLES_IN_ORDER = [
    'users',
    'shops',
    'products',
    'customer_orders',
    'shop_orders',
    'shop_order_items',
]


@contextmanager
def connect(engine):
    conn = engine.connect()
    trans = conn.begin()
    try:
        yield conn
        trans.commit()
    except Exception:
        trans.rollback()
        raise
    finally:
        conn.close()


def main():
    source_engine = create_engine(SOURCE_DATABASE_URL)
    target_engine = create_engine(TARGET_DATABASE_URL, pool_pre_ping=True)

    src_meta = MetaData()
    src_meta.reflect(bind=source_engine)

    tgt_meta = MetaData()
    tgt_meta.reflect(bind=target_engine)

    missing = [t for t in TABLES_IN_ORDER if t not in tgt_meta.tables]
    if missing:
        raise RuntimeError(
            f'Target DB missing tables: {missing}. Run schema migration first.'
        )

    with connect(target_engine) as target_conn:
        target_conn.execute(
            text(
                'TRUNCATE TABLE shop_order_items, shop_orders, customer_orders, products, shops, users RESTART IDENTITY CASCADE'
            )
        )

    with source_engine.connect() as source_conn, connect(target_engine) as target_conn:
        for table_name in TABLES_IN_ORDER:
            if table_name not in src_meta.tables:
                print(f'skip {table_name}: not found in source')
                continue

            src_table = src_meta.tables[table_name]
            tgt_table = tgt_meta.tables[table_name]

            rows = [dict(row._mapping) for row in source_conn.execute(src_table.select()).fetchall()]
            if not rows:
                print(f'{table_name}: 0 rows')
                continue

            target_conn.execute(tgt_table.insert(), rows)
            print(f'{table_name}: {len(rows)} rows exported')

    print('Export completed successfully.')


if __name__ == '__main__':
    main()
