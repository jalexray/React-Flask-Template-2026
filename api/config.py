import os
from pathlib import Path

from dotenv import load_dotenv

# Load environment variables from `api/.env` (created by `setup-env.sh`).
basedir = Path(__file__).resolve().parent
load_dotenv(basedir / ".env")


class Config:
    """
    App configuration.

    Keep Flask's own settings (e.g. FLASK_DEBUG) in the environment; keep
    application settings here so they're available via `current_app.config[...]`.
    """

    # Example app settings (used by future endpoints/services)
    OPENAI_KEY = os.getenv("OPENAI_KEY")

    # Database configuration
    #
    # Preferred: set DATABASE_URL (works well on hosted environments)
    # Example: mysql+mysqlconnector://user:pass@host:3306/dbname?auth_plugin=mysql_native_password
    #
    # Fallback: set DATABASE_NAME / DATABASE_USER / DATABASE_PASSWORD (and optionally host/port)
    # Final fallback: local SQLite file for quickstarts.
    DATABASE_URL = os.getenv("DATABASE_URL")

    # Optional DB env vars (used by `db-setup.sh`, not wired yet)
    DATABASE_NAME = os.getenv("DATABASE_NAME")
    DATABASE_USER = os.getenv("DATABASE_USER")
    DATABASE_PASSWORD = os.getenv("DATABASE_PASSWORD")
    DATABASE_HOST = os.getenv("DATABASE_HOST", "localhost")
    DATABASE_PORT = int(os.getenv("DATABASE_PORT", "3306"))

    if DATABASE_URL:
        SQLALCHEMY_DATABASE_URI = DATABASE_URL
    elif DATABASE_NAME and DATABASE_USER is not None and DATABASE_PASSWORD is not None:
        SQLALCHEMY_DATABASE_URI = (
            f"mysql+mysqlconnector://{DATABASE_USER}:{DATABASE_PASSWORD}"
            f"@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"
            "?auth_plugin=mysql_native_password"
        )
    else:
        # Default to an on-disk SQLite DB so the app can start without any DB setup.
        SQLALCHEMY_DATABASE_URI = f"sqlite:///{(basedir / 'app.db').as_posix()}"

    # Flask JSON preferences
    JSON_SORT_KEYS = False
