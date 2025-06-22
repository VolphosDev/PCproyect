#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
echo 'export DEBIAN_FRONTEND=noninteractive' | sudo tee -a /etc/environment

set -e

echo "[INFO] Actualizando e instalando dependencias del sistema..."
sudo apt-get update -yq
sudo apt-get install -yq python3-pip build-essential libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev mysql-server

echo "[INFO] Verificando Python..."
python3 --version
pip3 --version

echo "[INFO] Instalando dependencias de Python..."
cd /home/ubuntu/app
pip3 install --upgrade pip
pip3 install flask flask-cors mysql-connector-python mtcnn tensorflow-cpu scikit-learn opencv-python

echo "[INFO] Configurando MySQL..."
sudo systemctl start mysql
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'admin'; FLUSH PRIVILEGES;"
sudo mysql -uroot -padmin -e "CREATE DATABASE IF NOT EXISTS detection_face_db"

echo "[INFO] Configurando Gunicorn como servicio..."

cat <<EOF | sudo tee /etc/systemd/system/face_app.service
[Unit]
Description=Gunicorn instance to serve face recognition Flask app
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/app
Environment="PATH=/usr/bin"
ExecStart=/usr/local/bin/gunicorn -b 0.0.0.0:5000 app:app

[Install]
WantedBy=multi-user.target
EOF

echo "[INFO] Habilitando y arrancando el servicio face_app..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable face_app
sudo systemctl start face_app
