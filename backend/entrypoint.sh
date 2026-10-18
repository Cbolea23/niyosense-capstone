#!/bin/sh
set -e

echo "==> Running database migrations..."
python manage.py migrate --noinput

echo "==> Collecting static assets..."
python manage.py collectstatic --noinput

echo "==> Starting Gunicorn server on 0.0.0.0:${PORT:-8000}..."
exec gunicorn core.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 2 --timeout 120
