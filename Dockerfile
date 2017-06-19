FROM centos:7

LABEL name="rabbitmq-cluster"

ENV ERLANG_VERSION 19.3.4-1
ENV RABBITMQ_VERSION 3.6.10-1
ENV RABBITMQ_AUTO_CLUSTER_VERSION 0.7.0

ENV PATH /usr/lib/rabbitmq/bin:$PATH
ENV HOME /var/lib/rabbitmq

RUN groupadd -r rabbitmq && useradd -r -d /var/lib/rabbitmq -m -g rabbitmq rabbitmq && \
    curl -RO -L https://github.com/rabbitmq/erlang-rpm/releases/download/v19.3.4/erlang-$ERLANG_VERSION.el7.centos.x86_64.rpm && \
    curl -RO -L https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.10/rabbitmq-server-$RABBITMQ_VERSION.el7.noarch.rpm && \
    curl -RO -L https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/$RABBITMQ_AUTO_CLUSTER_VERSION/autocluster-0.7.0.ez && \
    curl -RO -L https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/$RABBITMQ_AUTO_CLUSTER_VERSION/autocluster_aws-0.0.1.ez && \
    curl -RO -L https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/$RABBITMQ_AUTO_CLUSTER_VERSION/rabbitmq_aws-0.7.0.ez && \
    yum -y install erlang-$ERLANG_VERSION.el7.centos.x86_64.rpm && \
    yum -y install rabbitmq-server-$RABBITMQ_VERSION.el7.noarch.rpm && \
    cp *.ez /usr/lib/rabbitmq/lib/*/plugins && \
    yum -y install unzip && \
    curl -RO -L https://s3.amazonaws.com/aws-cli/awscli-bundle.zip && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    rm -fr ./*.rpm ./*.ez awscli-bundle.zip awscli-bundle

RUN chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /usr/lib/rabbitmq && \
    rabbitmq-plugins enable --offline \
        autocluster \
        autocluster_aws \
        rabbitmq_management \
        rabbitmq_management_visualiser

VOLUME /var/lib/rabbitmq

EXPOSE 4369 5671 5672 15672 25672 24471

COPY ./certs /certs

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["rabbitmq-server"]
