from flask import Blueprint

# Blueprint for "main" API routes.
# NOTE: The `/api` prefix is applied by the parent `api_bp` blueprint.
bp = Blueprint("main", __name__)

# Import routes so view functions are registered on `bp`.
from . import routes  # noqa: E402,F401