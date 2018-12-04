#!/bin/sh

test -e "/data/graphite/storage/graphite.db" && echo "graphite.db already exists!" || django-admin.py migrate --settings=graphite.settings --run-syncdb

cd /var/lib/graphite/conf

gunicorn -b 0.0.0.0:8000 -w 2 graphite_wsgi:application &
PID=$!
trap 'while kill $PID > /dev/null 2>&1;do sleep 1;done;exit 0' SIGTERM
while true; do sleep 10; done