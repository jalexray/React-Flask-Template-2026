from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()


def create_app() -> Flask:
    app = Flask(__name__, static_folder='../build', static_url_path='/')

    from .config import Config
    app.config.from_object(Config)

    # Extensions
    db.init_app(app)
    migrate.init_app(app, db)

    # Import models so Alembic can discover them.
    from . import models  # noqa: F401

    # Parent API blueprint mounted at `/api`, with feature blueprints nested under it.
    from .api_bp import api_bp

    app.register_blueprint(api_bp)

    # Serve the React SPA entrypoint at the site root.
    # Static assets (e.g. /assets/...) are handled by Flask's built-in static route
    # because static_url_path is set to "/".
    @app.get("/")
    def index():
        return app.send_static_file("index.html")

    return app
