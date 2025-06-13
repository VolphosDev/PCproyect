FROM aabounegm/python-dlib:latest

WORKDIR /app

COPY . /app

RUN pip install --upgrade pip
RUN pip install face_recognition flask flask-cors mysql-connector-python

ENV DB_HOST=mysql
ENV DB_USER=faceuser
ENV DB_PASSWORD=facepass
ENV DB_NAME=detection_face_db

EXPOSE 5000

CMD ["sh", "-c", "sleep 15 && python app.py"]