from flask import Flask, request, jsonify
import os
import json
import base64
import face_recognition
import mysql.connector
from mysql.connector import Error
import numpy as np
from flask_cors import CORS
import time
import uuid

app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    "host": os.environ["DB_HOST"],
    "user": os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
    "database": os.environ["DB_NAME"]
}

def conectar_db():
    for intento in range(10):
        try:
            db = mysql.connector.connect(
                host=DB_CONFIG["host"],
                user=DB_CONFIG["user"],
                password=DB_CONFIG["password"]
            )
            cursor = db.cursor()
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_CONFIG['database']}")
            cursor.execute(f"USE {DB_CONFIG['database']}")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS personas (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    nombre VARCHAR(100),
                    apellido_paterno VARCHAR(100),
                    apellido_materno VARCHAR(100),
                    correo VARCHAR(100),
                    requisitoriado BOOLEAN,
                    foto LONGBLOB,
                    KP LONGTEXT
                )
            """)
            db.commit()
            return db, cursor
        except Error as e:
            print(f"[ERROR] Intento {intento + 1}: {e}")
            time.sleep(5)
    raise Exception("No se pudo conectar con la base de datos después de múltiples intentos.")

def calcular_distancia(emb1, emb2):
    return np.linalg.norm(np.array(emb1) - np.array(emb2))

def registrar_persona(nombre, apellido_paterno, apellido_materno, correo, requisitoriado, imagen_b64):
    try:
        img_data = base64.b64decode(imagen_b64)
        temp_file = f"/tmp/temp_img_{uuid.uuid4().hex}.jpg"
        with open(temp_file, "wb") as f:
            f.write(img_data)
        img = face_recognition.load_image_file(temp_file)
        encodings = face_recognition.face_encodings(img)

        if not encodings:
            return {"error": "No se detectó rostro en la imagen."}, 400

        embedding = encodings[0].tolist()
        kp_json = json.dumps(embedding)

        db, cursor = conectar_db()
        sql = """
            INSERT INTO personas (nombre, apellido_paterno, apellido_materno, correo, requisitoriado, KP, foto)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        values = (nombre, apellido_paterno, apellido_materno, correo, requisitoriado, kp_json, imagen_b64)
        cursor.execute(sql, values)
        db.commit()
        cursor.close()
        db.close()

        os.remove(temp_file)

        return {"message": "Persona registrada exitosamente."}, 200

    except Exception as e:
        return {"error": str(e)}, 500

def reconocer_persona(imagen_b64, umbral):
    try:
        img_data = base64.b64decode(imagen_b64)
        temp_file = f"/tmp/temp_img_{uuid.uuid4().hex}.jpg"
        with open(temp_file, "wb") as f:
            f.write(img_data)
        img = face_recognition.load_image_file(temp_file)
        encodings = face_recognition.face_encodings(img)
        os.remove(temp_file)

        if not encodings:
            return {"message": "No se detectó rostro."}, 200

        encoding_input = encodings[0]

        db, cursor = conectar_db()
        cursor.execute("SELECT id, nombre, apellido_paterno, requisitoriado, KP FROM personas")
        registros = cursor.fetchall()

        mejor_match = None
        mejor_distancia = float('inf')

        for reg in registros:
            id_p, nombre, apellido_paterno, requisitoriado, kp_json = reg
            try:
                emb_db = json.loads(kp_json)
                if not isinstance(emb_db, list) or len(emb_db) != 128:
                    continue
            except:
                continue

            dist = calcular_distancia(encoding_input, emb_db)
            if dist < mejor_distancia:
                mejor_distancia = dist
                mejor_match = {
                    "id": id_p,
                    "nombre": nombre,
                    "apellido_paterno": apellido_paterno,
                    "requisitoriado": "Sí" if requisitoriado else "No",
                    "distancia": dist
                }

        cursor.close()
        db.close()

        if mejor_match and mejor_distancia < umbral:
            return {
                "message": "Persona reconocida",
                **mejor_match
            }, 200
        else:
            return {"message": "Persona no reconocida"}, 200

    except Exception as e:
        return {"error": str(e)}, 500

@app.route("/registrar", methods=["POST"])
def api_registrar():
    if 'imagen' not in request.files:
        return jsonify({"error": "Falta la imagen."}), 400

    campos = ["nombre", "apellido_paterno", "apellido_materno", "correo", "requisitoriado"]
    if not all(c in request.form for c in campos):
        return jsonify({"error": "Faltan campos obligatorios"}), 400

    try:
        imagen_file = request.files['imagen']
        imagen_bytes = imagen_file.read()
        imagen_b64 = base64.b64encode(imagen_bytes).decode('utf-8')

        return registrar_persona(
            request.form['nombre'],
            request.form['apellido_paterno'],
            request.form['apellido_materno'],
            request.form['correo'],
            bool(int(request.form['requisitoriado'])),
            imagen_b64
        )
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/reconocer", methods=["POST"])
def api_reconocer():
    if 'imagen' not in request.files:
        return jsonify({"error": "Falta la imagen."}), 400

    file = request.files['imagen']
    imagen_b64 = base64.b64encode(file.read()).decode('utf-8')

    umbral = float(request.form.get("umbral", 0.42))
    return reconocer_persona(imagen_b64, umbral)

if __name__ == "__main__":
    conectar_db()
    app.run(host="0.0.0.0", port=5000, debug=False)