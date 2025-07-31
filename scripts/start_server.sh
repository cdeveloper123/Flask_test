#!/bin/bash

set -e

APP_DIR="/home/ubuntu/jigsawml-backend"
VENV_DIR="$APP_DIR/environment"
APP_NAME="jigsawml-backend"
ECOSYSTEM_FILE="$APP_DIR/ecosystem.config.js"

# Launch command wrapped for PM2
APP_LAUNCH_CMD="cd $APP_DIR && source $VENV_DIR/bin/activate && uvicorn src.asgi:ASGIapp --host 0.0.0.0 --port 8000 --workers 1 --timeout-keep-alive 300 --log-level debug"

# Determine which secrets file to use
if [ -f "$APP_DIR/.env.prod" ]; then
  SECRETS_FILE="$APP_DIR/.env.prod"
  echo "Using .env.prod"
elif [ -f "$APP_DIR/.env.staging" ]; then
  SECRETS_FILE="$APP_DIR/.env.staging"
  echo "Using .env.staging"
else
  echo " No .env.prod or .env.staging found in $APP_DIR"
  exit 1
fi

# Sanity checks
[ -f "$SECRETS_FILE" ] || { echo "ERROR: Secrets file not found: $SECRETS_FILE"; exit 1; }
[ -d "$VENV_DIR" ] || { echo " ERROR: Python virtualenv not found: $VENV_DIR"; exit 1; }

# Activate virtualenv
source "$VENV_DIR/bin/activate"

# Generate ecosystem.config.js
echo " Generating PM2 ecosystem file..."

{
  echo "module.exports = {"
  echo "  apps: [{"
  echo "    name: \"$APP_NAME\","
  echo "    script: \"bash\","
  echo "    args: \"-c \\\"$APP_LAUNCH_CMD\\\"\","
  echo "    env: {"

  # Parse secrets and inject into env
  grep -v '^#' "$SECRETS_FILE" | grep -E '=' | while IFS='=' read -r key value; do
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | sed -e 's/^ *//' -e 's/ *$//' -e 's/"/\\"/g')
    echo "      \"$key\": \"$value\","
  done

  echo "    }"
  echo "  }]"
  echo "};"
} > "$ECOSYSTEM_FILE"

echo "PM2 config generated: $ECOSYSTEM_FILE"

# Restart or start app using new ecosystem
if pm2 list | grep -Fq "$APP_NAME"; then
  echo "Restarting PM2 process: $APP_NAME"
  pm2 delete "$APP_NAME"
fi

echo "Starting PM2 process: $APP_NAME"
pm2 start "$ECOSYSTEM_FILE"

# Save current process list
pm2 save

# Ensure PM2 startup is enabled on reboot
if ! systemctl status pm2-$USER &>/dev/null; then
  echo "Setting up PM2 to auto-start on system boot"
  sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u "$USER" --hp "$HOME"
  pm2 save
else
  echo "M2 is already set to auto-start on reboot"
fi
