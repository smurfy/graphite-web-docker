FROM alpine:3.13.5 as base

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

ARG python_binary=python3

RUN true \
 && apk add --update \
      alpine-sdk \
      git \
      libffi-dev \
      pkgconfig \
      openldap-dev \
      python3-dev \
      rrdtool-dev \
      wget \
 && curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
 && $python_binary /tmp/get-pip.py pip==20.1.1 setuptools==50.3.2 wheel==0.35.1 && rm /tmp/get-pip.py \
 && pip install virtualenv==16.7.10 \
 && virtualenv -p $python_binary /opt/graphite \
 && . /opt/graphite/bin/activate \
 && pip install \
      django==2.2.20 \
      django-statsd-mozilla \
      fadvise \
      gunicorn==20.0.4 \
      eventlet>=0.24.1 \
      gevent>=1.4 \
      msgpack==0.6.2 \
      redis \
      rrdtool \
      python-ldap \
      mysqlclient \
      psycopg2 \
      django-cockroachdb==2.2.*

ARG version=1.1.8

# install whisper
ARG whisper_version=${version}
ARG whisper_repo=https://github.com/graphite-project/whisper.git
RUN git clone -b ${whisper_version} --depth 1 ${whisper_repo} /usr/local/src/whisper \
 && cd /usr/local/src/whisper \
 && . /opt/graphite/bin/activate \
 && $python_binary ./setup.py install

# install graphite
ARG graphite_version=${version}
ARG graphite_repo=https://github.com/graphite-project/graphite-web.git
RUN . /opt/graphite/bin/activate \
 && git clone -b ${graphite_version} --depth 1 ${graphite_repo} /usr/local/src/graphite-web \
 && cd /usr/local/src/graphite-web \
 && pip install -r requirements.txt \
 && $python_binary ./setup.py install

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
