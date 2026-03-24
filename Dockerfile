# FROM python:3.13
FROM python:3.11-slim

WORKDIR /app
COPY . .

RUN pip install gunicorn
# RUN pip install -r requirements.txt
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# ENV PORT=80  ## ChatGPT: Overriding PORT to 80 breaks GCP routing
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 main:app
