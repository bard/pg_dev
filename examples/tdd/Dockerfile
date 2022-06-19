FROM postgres:13

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --no-install-recommends -y postgresql-13-pgtap && \
    apt-get -y autoremove && \
    apt-get clean && rm -rf /tmp/* /var/tmp/*
