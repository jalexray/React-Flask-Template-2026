"""
WSGI entry point.

Many deployment targets expect an importable module that exposes `app`.
"""

from api import create_app

app = create_app()

