from time import time

from flask import current_app, url_for
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin

from api import db
from datetime import datetime

# User Classes 
class User(UserMixin, db.Model):
	id = db.Column(db.Integer, primary_key=True)
	username = db.Column(db.String(64), index=True, unique=True)
	password_hash = db.Column(db.String(256))
	created_at = db.Column(db.DateTime, default=datetime.utcnow)

	def set_password(self, password):
		self.password_hash = generate_password_hash(password)

	def check_password(self, password):
		return check_password_hash(self.password_hash, password)

	def __repr__(self):
		return f'<User {self.username}>'
