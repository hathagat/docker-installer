from docker.elastic.co/elasticsearch/elasticsearch:7.0.0
# Version need to match https://readonlyrest.com/download/

COPY --chown=elasticsearch:elasticsearch readonlyrest-1.17.6_es7.0.0.zip /readonlyrest-1.17.6_es7.0.0.zip
COPY --chown=elasticsearch:elasticsearch readonlyrest.yml /etc/elasticsearch/readonlyrest.yml

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch ingest-attachment \
    && /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch file:///readonlyrest-1.17.6_es7.0.0.zip \
    && rm /readonlyrest-1.17.6_es7.0.0.zip