FROM postgres:13

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential wget git \
    python3-wheel python3-dev \
    python3 python3-watchdog python3-pip python3-setuptools postgresql-13-pgtap && \
    pip3 install --no-cache-dir packaging psycopg2-binary migra && \
    cd /tmp && wget https://github.com/eradman/ephemeralpg/archive/refs/tags/3.1.tar.gz && tar zxf 3.1.tar.gz && cd ephemeralpg-3.1 && make install && \
    pip3 install 'git+https://github.com/lelit/pglast@v3' && \
    apt-get -y remove build-essential python3-dev python3-wheel && \
    apt-get -y autoremove && \
    apt-get clean && rm -rf /tmp/* /var/tmp/* 

COPY dist/schemachain /usr/local/bin/schemachain
WORKDIR /repo
ENTRYPOINT []
