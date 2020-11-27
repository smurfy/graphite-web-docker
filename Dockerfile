FROM alpine:3.11.6 as base

RUN true \
 && apk add --no-cache \
      cairo \
      findutils \
      librrd \
      memcached \
      py3-pyldap \
      redis \
      runit \
      sqlite \
      expect \
      py3-mysqlclient \
      mysql-dev \
      mysql-client \
      postgresql-dev \
      postgresql-client

FROM base as build

RUN true \
 && apk add --update \
      alpine-sdk \
      git \
      libffi-dev \
      pkgconfig \
      py3-cairo \
      py3-pip \
      py3-virtualenv==16.7.8-r0 \
      openldap-dev \
      python3-dev \
      rrdtool-dev \
      wget \
 && virtualenv /opt/graphite \
 && . /opt/graphite/bin/activate \
 && pip3 install \
      django==2.2.12 \
      django-statsd-mozilla \
      fadvise \
      gunicorn==20.0.4 \
      eventlet>=0.24.1 \
      gevent>=1.4 \
      msgpack-python \
      redis \
      rrdtool \
      python-ldap \
      mysqlclient \
      psycopg2 \
      django-cockroachdb==2.2.*

ARG version=1.1.7

# install whisper
ARG whisper_version=${version}
ARG whisper_repo=https://github.com/graphite-project/whisper.git
RUN git clone -b ${whisper_version} --depth 1 ${whisper_repo} /usr/local/src/whisper \
 && cd /usr/local/src/whisper \
 && . /opt/graphite/bin/activate \
 && python3 ./setup.py install

# install graphite
ARG graphite_version=${version}
ARG graphite_repo=https://github.com/graphite-project/graphite-web.git
RUN . /opt/graphite/bin/activate \
&& git clone -b ${graphite_version} --depth 1 ${graphite_repo} /usr/local/src/graphite-web \
&& cd /usr/local/src/graphite-web \
&& pip3 install -r requirements.txt \
&& python3 ./setup.py install

# config graphite
WORKDIR /opt/graphite/webapp
RUN mkdir -p /var/log/graphite/ \
  && PYTHONPATH=/opt/graphite/webapp /opt/graphite/bin/django-admin.py collectstatic --noinput --settings=graphite.settings

FROM base as production

COPY --from=build /opt /opt

ADD run.sh /run.sh
ADD local_settings.py /opt/graphite/webapp/graphite
ADD graphite_wsgi.py /opt/graphite/conf

RUN mkdir -p /data/graphite/conf && \
    mkdir -p /data/graphite/storage/whisper && \
    mkdir -p /data/graphite/storage/log/webapp && \
    mkdir -p /var/log/graphite && \
    touch /data/graphite/storage/index && \
    chmod 0775 /data/graphite/storage /data/graphite/storage/whisper && \
    chmod +x /run.sh

# Expose Port
EXPOSE 8000

VOLUME ["/data/graphite"]

ENV PYTHONPATH=/opt/graphite/webapp
ENV GRAPHITE_STORAGE_DIR /data/graphite/storage
ENV GRAPHITE_CONF_DIR /data/graphite/conf

STOPSIGNAL SIGTERM

CMD  ["/run.sh"]
