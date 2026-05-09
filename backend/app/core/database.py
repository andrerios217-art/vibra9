import sqlite3
from app.core.config import DB_PATH

def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH, timeout=30, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA busy_timeout=30000")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA cache_size=10000")
    return conn

def init_db() -> None:
    conn = get_connection()
    c = conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        privacy_policy_accepted INTEGER NOT NULL DEFAULT 0,
        privacy_policy_accepted_at TEXT,
        terms_accepted INTEGER NOT NULL DEFAULT 0,
        terms_accepted_at TEXT,
        email_verified INTEGER NOT NULL DEFAULT 0,
        subscription_status TEXT NOT NULL DEFAULT 'trial',
        trial_start TEXT,
        trial_end TEXT,
        created_at TEXT NOT NULL
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS login_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        success INTEGER NOT NULL DEFAULT 0,
        attempted_at TEXT NOT NULL
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS refresh_tokens (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token_hash TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        revoked INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS verification_codes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        code TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'email',
        expires_at TEXT NOT NULL,
        used INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS password_reset_tokens (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token_hash TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        used INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS assessments (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        general_score INTEGER NOT NULL,
        dimensions_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS recommendations (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        assessment_id TEXT NOT NULL,
        summary TEXT NOT NULL,
        main_focus TEXT NOT NULL,
        daily_actions_json TEXT NOT NULL,
        quote TEXT NOT NULL,
        quote_author TEXT NOT NULL,
        safety_note TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(assessment_id) REFERENCES assessments(id)
    )""")
    # Índices para performance
    c.execute("CREATE INDEX IF NOT EXISTS idx_assessments_user_id ON assessments(user_id)")
    c.execute("CREATE INDEX IF NOT EXISTS idx_assessments_created_at ON assessments(created_at)")
    c.execute("CREATE INDEX IF NOT EXISTS idx_recommendations_assessment_id ON recommendations(assessment_id)")
    c.execute("CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON recommendations(user_id)")
    c.execute("CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id)")
    c.execute("CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON login_attempts(email)")
    _run_migrations(conn)
    conn.commit()
    conn.close()

def _run_migrations(conn: sqlite3.Connection) -> None:
    existing = {row[1] for row in conn.execute("PRAGMA table_info(users)")}
    cols = {
        "privacy_policy_accepted_at": "ALTER TABLE users ADD COLUMN privacy_policy_accepted_at TEXT",
        "terms_accepted_at": "ALTER TABLE users ADD COLUMN terms_accepted_at TEXT",
        "email_verified": "ALTER TABLE users ADD COLUMN email_verified INTEGER NOT NULL DEFAULT 0",
        "subscription_status": "ALTER TABLE users ADD COLUMN subscription_status TEXT NOT NULL DEFAULT 'trial'",
        "trial_start": "ALTER TABLE users ADD COLUMN trial_start TEXT",
        "trial_end": "ALTER TABLE users ADD COLUMN trial_end TEXT",
    }
    for col, sql in cols.items():
        if col not in existing:
            conn.execute(sql)
