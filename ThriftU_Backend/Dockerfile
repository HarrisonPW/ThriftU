
# Base image
FROM python:3.9-slim
LABEL authors="puxuanwang"

# Set working directory
WORKDIR /app

# Copy application code to container
COPY . .

# Upgrade pip and install dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Expose port 5000 for the Flask app
EXPOSE 5000

# Command to run the Flask app
CMD ["python", "app.py"]
