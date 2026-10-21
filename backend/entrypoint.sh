#!/bin/sh
set -e

echo "==> Running database migrations..."
python manage.py migrate --noinput

if [ -f "initial_data.json" ]; then
    DATA_COUNT=$(python -c "import django, os; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings'); django.setup(); from apps.scans.models import GradingLog; print(GradingLog.objects.count())" 2>/dev/null || echo "0")
    if [ "$DATA_COUNT" = "0" ]; then
        echo "==> Fresh database detected. Loading initial fixture data..."
        python manage.py loaddata initial_data.json || true
    else
        echo "==> Existing database has $DATA_COUNT logs. Skipping fixture loaddata to preserve live counts."
    fi
fi

echo "==> Collecting static assets..."
python manage.py collectstatic --noinput

echo "==> Starting Gunicorn server on 0.0.0.0:${PORT:-8000}..."
exec gunicorn core.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 2 --timeout 120
