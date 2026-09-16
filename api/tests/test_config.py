from app.config import is_local_database, normalize_database_url


def test_normalize_render_postgres_url():
    raw = "postgres://afrios:secret@dpg-abc123-a.oregon-postgres.render.com/afrios?sslmode=require"
    out = normalize_database_url(raw)
    assert out.startswith("postgresql+asyncpg://")
    assert "sslmode" not in out
    assert "oregon-postgres.render.com" in out
    assert not is_local_database(out)


def test_normalize_keeps_sqlite():
    url = "sqlite+aiosqlite:///./afrios_dev.db"
    assert normalize_database_url(url) == url
    assert is_local_database(url)
