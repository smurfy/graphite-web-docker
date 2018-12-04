#!/bin/sh

test -e "/data/graphite/storage/graphite.db" && echo "graphite.db already exists!" || django-admin.py migrate --settings=graphite.settings --run-syncdb

cd /var/lib/graphite/conf

gunicorn -b 0.0.0.0:8000 -w 2 graphite_wsgi:application
