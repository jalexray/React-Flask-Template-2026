#!/bin/bash

# Ensure we run from the repo root (so relative paths like api/.env work).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# This script is used to create a new MySQL database and user.
# It will prompt the user for the MySQL root username and password,
# and then create a new user with all privileges to the database.

# To give permission to execute the script, run the command:
# chmod +x db-setup.sh

# To run the script, run the command:
# ./db-setup.sh

# Function to prompt user for input
get_user_input() {
    read -p "Enter MySQL root username: " MYSQL_ROOT_USER
    echo "" # New line for better formatting

    read -s -p "Enter MySQL root password (leave blank if none): " MYSQL_ROOT_PASSWORD
    echo "" # New line for better formatting

    read -p "Enter new database name: " DB_NAME
    echo "" # New line for better formatting

     read -p "Enter new database user: " USER_NAME
    echo "" # New line for better formatting

    read -s -p "Enter new MySQL user password (optional): " DB_PASS
    echo "" # New line for better formatting
}

# Function to create the database and user
create_mysql_db() {
    SQL_COMMANDS="
    CREATE DATABASE IF NOT EXISTS $DB_NAME;
    CREATE USER IF NOT EXISTS '$USER_NAME'@'localhost' IDENTIFIED BY '$DB_PASS';
    GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$USER_NAME'@'localhost';
    FLUSH PRIVILEGES;
    "

    echo "🚀 Executing MySQL commands..."
    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        mysql -u"$MYSQL_ROOT_USER" -p"$MYSQL_ROOT_PASSWORD" -e "$SQL_COMMANDS"
    else
        mysql -u"$MYSQL_ROOT_USER" -e "$SQL_COMMANDS"
    fi

    if [ $? -eq 0 ]; then
        echo "✅ Database and user created successfully!"
    else
        echo "❌ Failed to execute MySQL commands. Please check your credentials and try again."
    fi
}

setup_flask_db() {
    echo ""
    echo "🔧 Running Flask DB migrations (Flask-Migrate / Alembic)..."

    if [ ! -x "api/venv/bin/flask" ]; then
        echo "❌ Could not find backend venv at api/venv/bin/flask"
        echo ""
        echo "Create it with:"
        echo "  python3 -m venv api/venv"
        echo "  api/venv/bin/pip install -r api/requirements.txt"
        echo ""
        echo "Then re-run this script."
        return 1
    fi

    # If the migrations folder doesn't exist yet (fresh repo), initialize it.
    if [ ! -d "migrations" ]; then
        echo "📦 Initializing migrations folder..."
        api/venv/bin/flask --app api:create_app db init
    fi

    echo "🧱 Generating migration (if needed)..."
    api/venv/bin/flask --app api:create_app db migrate -m "Auto migration"

    echo "⬆️ Applying migrations..."
    api/venv/bin/flask --app api:create_app db upgrade

    if [ $? -eq 0 ]; then
        echo "✅ Flask migrations applied successfully!"
    else
        echo "❌ Failed to apply Flask migrations."
        return 1
    fi
}

update_env_file() {
	ENV_FILE="api/.env"

	# Check if .env file exists, if not, create it
	if [ ! -f "$ENV_FILE" ]; then
		touch "$ENV_FILE"
	fi

	echo "DATABASE_NAME=\"$DB_NAME\"" >> "$ENV_FILE"
	echo "DATABASE_USER=\"$USER_NAME\"" >> "$ENV_FILE"
	echo "DATABASE_PASSWORD=\"$DB_PASS\"" >> "$ENV_FILE"

	echo "✅ .env file updated successfully!"
}

# Main script execution
echo "🔍 Checking MySQL status..."
get_user_input
create_mysql_db
update_env_file

echo ""
read -r -p "Run Flask migrations now (creates/updates tables)? (y/n): " RUN_MIGRATIONS
if [[ "$RUN_MIGRATIONS" == "y" || "$RUN_MIGRATIONS" == "Y" ]]; then
    setup_flask_db
else
    echo "Skipping Flask migrations."
fi
