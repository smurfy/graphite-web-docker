#!/bin/sh

test -e "/data/graphite/storage/graphite.db" && echo "graphite.db already exists!" || /opt/graphite/bin/django-admin.py migrate --settings=graphite.settings --run-syncdb

cd /opt/graphite/conf

export GRAPHITE_WSGI_PROCESSES=${GRAPHITE_WSGI_PROCESSES:-4}
export GRAPHITE_WSGI_THREADS=${GRAPHITE_WSGI_THREADS:-1}
export GRAPHITE_WSGI_REQUEST_TIMEOUT=${GRAPHITE_WSGI_REQUEST_TIMEOUT:-65}
export GRAPHITE_WSGI_REQUEST_LINE=${GRAPHITE_WSGI_REQUEST_LINE:-0}
export GRAPHITE_WSGI_MAX_REQUESTS=${GRAPHITE_WSGI_MAX_REQUESTS:-1000}
export GRAPHITE_WSGI_WORKER_CLASS=${GRAPHITE_WSGI_WORKER_CLASS:-"sync"}
export GRAPHITE_WSGI_WORKER_CONNECTIONS=${GRAPHITE_WSGI_WORKER_CONNECTIONS:-1000}

if [ "${GRAPHITE_WSGI_WORKER_CLASS}" == "gevent" ]; then
    export GUNICORN_EXTRA_PARAMS="--worker-connections=${GRAPHITE_WSGI_WORKER_CONNECTIONS} "
else
    export GUNICORN_EXTRA_PARAMS="--preload --threads=${GRAPHITE_WSGI_THREADS} "
fi

/opt/graphite/bin/gunicorn wsgi --pythonpath=/opt/graphite/webapp/graphite \
    ${GUNICORN_EXTRA_PARAMS} \
    --worker-class=${GRAPHITE_WSGI_WORKER_CLASS} \
    --workers=${GRAPHITE_WSGI_PROCESSES} \
    --limit-request-line=${GRAPHITE_WSGI_REQUEST_LINE} \
    --max-requests=${GRAPHITE_WSGI_MAX_REQUESTS} \
    --timeout=${GRAPHITE_WSGI_REQUEST_TIMEOUT} \
    --bind=0.0.0.0:8000 &

PID=$!
trap 'while kill $PID > /dev/null 2>&1;do sleep 1;done;exit 0' SIGTERM
while true; do sleep 10; done
