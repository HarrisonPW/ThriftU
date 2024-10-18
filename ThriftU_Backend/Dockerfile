FROM python:3.9-slim
LABEL authors="puxuanwang"

WORKDIR /app
COPY . .

# Update pip to the latest version
RUN pip install --upgrade pip

RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["python", "app.py"]
