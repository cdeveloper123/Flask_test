#!/bin/bash

APP_DIR="/home/ubuntu/jigsawml-backend"
ENV_DIR="$APP_DIR/environment"
sudo apt-get update
sudo apt-get install -y python3.10-venv

if [ ! -d "$ENV_DIR" ]; then
    python3.10 -m venv "$ENV_DIR"
fi
source "$ENV_DIR/bin/activate"

# sudo chown -R ubuntu:ubuntu "$ENV_DIR"
pip install --upgrade pip setuptools wheel
pip install -r "$APP_DIR/requirements.txt"
