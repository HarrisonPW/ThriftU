FROM python:3.9-slim
LABEL authors="puxuanwang"

WORKDIR /app
COPY ../../../Library/Containers/com.tencent.xinWeChat/Data/Library/Application%20Support/com.tencent.xinWeChat/2.0b4.0.9/945a3c4af2a07604a7edc1a15aaede62/Message/MessageTemp/0a4694fd5f6cf16760e5e2d834a076e7/File .

# Update pip to the latest version
RUN pip install --upgrade pip

RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["python", "app.py"]
