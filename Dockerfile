FROM python:2.7-alpine3.8

ENV WHISPER_VERSION 1.1.4
ENV GRAPHITE_WEB_VERSION 1.1.4

RUN apk add --no-cache curl && \
    curl https://raw.githubusercontent.com/alpinelinux/aports/3.8-stable/main/python2/musl-find_library.patch -o /python.patch && \
    patch /usr/local/lib/python2.7/ctypes/util.py /python.patch && \
    rm /python.patch && \
    apk add --no-cache libffi cairo && \
    apk add --no-cache --virtual .build-deps libffi-dev musl-dev cairo-dev build-base && \
    pip install gunicorn django && \
    pip install whisper==$WHISPER_VERSION && \
    pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web==$GRAPHITE_WEB_VERSION && \
    apk del .build-deps curl && \
    rm -rf /root/.cache/pip

ADD run.sh /run.sh
ADD local_settings.py /var/lib/graphite/webapp/graphite/
ADD graphite_wsgi.py /var/lib/graphite/conf

RUN mkdir -p /data/graphite/conf && \
    mkdir -p /data/graphite/storage/whisper && \
    mkdir -p /data/graphite/storage/log/webapp && \
    touch /data/graphite/storage/index && \
    chmod 0775 /data/graphite/storage /data/graphite/storage/whisper && \
    chmod +x /run.sh

# Expose Port
EXPOSE 8000

VOLUME ["/data/graphite"]

ENV PYTHONPATH /var/lib/graphite/webapp
ENV GRAPHITE_STORAGE_DIR /data/graphite/storage
ENV GRAPHITE_CONF_DIR /data/graphite/conf

CMD  ["/run.sh"]