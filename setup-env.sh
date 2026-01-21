#!/bin/bash

# Define the .env file path
ENV_FILE="api/.env"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo ".env file already exists. Do you want to overwrite it? (y/n)"
    read -r choice
    if [[ "$choice" != "y" ]]; then
        echo "Aborting."
        exit 1
    fi
fi

# Prompt user for OpenAI API Key
echo "Enter your OpenAI API Key:"
read -r OPENAI_KEY

# Write variables to .env file
cat > "$ENV_FILE" <<EOL
OPENAI_KEY=$OPENAI_KEY
FLASK_ENV=development
FLASK_DEBUG=1
FLASK_RUN_PORT=5009
EOL

echo ".env file created successfully!"
