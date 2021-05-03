FROM postgres:13

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential wget git ruby ruby-dev ruby-google-protobuf python3 python3-pip python3-setuptools && \
    gem install pg_query && \
    pip3 install --no-cache-dir packaging psycopg2-binary migra && \
    cd /tmp && wget https://github.com/eradman/ephemeralpg/archive/refs/tags/3.1.tar.gz && tar zxf 3.1.tar.gz && cd ephemeralpg-3.1 && make install && \
    apt-get -y remove build-essential ruby-dev && apt-get -y autoremove && apt-get clean && rm -rf /tmp/* /var/tmp/* 

COPY src/ /usr/local/lib/schemachain
COPY schemachain /tmp/schemachain.tmp
RUN sed -e 's|^SCHEMACHAIN_HOME=.*$|SCHEMACHAIN_HOME=/usr/local/lib/schemachain|' \
    </tmp/schemachain.tmp >/usr/local/bin/schemachain && \
    chmod +x /usr/local/bin/schemachain

WORKDIR /repo
ENTRYPOINT []
