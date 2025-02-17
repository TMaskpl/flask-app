# Użyj oficjalnego obrazu Pythona jako obrazu bazowego
FROM python:3.9

# Ustaw katalog roboczy
WORKDIR /app

# Skopiuj pliki requirements.txt i app.py do katalogu roboczego
COPY requirements.txt requirements.txt
COPY app.py app.py

# Zainstaluj zależności
RUN pip install -r requirements.txt

# Uruchom aplikację
CMD ["python", "app.py"]