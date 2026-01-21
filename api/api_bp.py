from flask import Blueprint

# Parent blueprint mounted under `/api`.
# Register all API feature blueprints under this to share the prefix.
api_bp = Blueprint("api", __name__, url_prefix="/api")

# Mount feature blueprints.
from .main import bp as main_bp  # noqa: E402

api_bp.register_blueprint(main_bp)

