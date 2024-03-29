#!/bin/bash
set -e
#set -u


# definitions
function definitions(){
    mkdir -p /etc/rabbitmq/definitions
    cat <<-EOF > /etc/rabbitmq/definitions/definitions.json
	{
	    "rabbit_version": "3.6.10",
	    "users": [
	      {
	        "name": "rabbitmq",
	        "password": "Welcome1",
	        "tags": "administrator"
	      },
	    ],
	    "permissions": [
	      { "user": "rabbitmq", "vhost":"/", "configure":".*","write":".*","read":".*"}
	    ],
	    "vhosts": [
	      {
	        "name": "/"
	      }
	    ]
	}
	EOF
}
function rabbitmq_config(){
    cat <<-EOF > /etc/rabbitmq/rabbitmq.config
	[
	  {rabbit, [
	    {cluster_partition_handling, autoheal},
	    {cluster_nodes, {[${RABBITMQ_CLUSTER_NODES}], disc}}
	  ]},
	  {rabbitmq_management, [
	    {load_definitions, "/etc/rabbitmq/definitions/definitions.json"}
	  ]}
	].
	EOF
}
function erlang_cookie(){
    cookie_file=/var/lib/rabbitmq/.erlang.cookie
    if [ ! -z "$1" ]; then
        echo -n "$1" > $cookie_file
        chown rabbitmq:rabbitmq $cookie_file
        chmod 400 $cookie_file
    fi
}


# write logs to stdout
export RABBITMQ_LOGS=- RABBITMQ_SASL_LOGS=- RABBITMQ_USE_LONGNAME=true

# node config
RABBITMQ_NODENAME=${RABBITMQ_NODENAME:-}
if [ ! -z "$RABBITMQ_NODENAME" ]; then
  echo "RABBITMQ_NODENAME=${RABBITMQ_NODENAME}" > /etc/rabbitmq/rabbitmq-env.conf
fi

# rabbitmqctl
 echo "export RABBITMQ_USE_LONGNAME=true" > /etc/profile.d/rabbitmqctl.sh

# cluster config
RABBITMQ_ERLANG_COOKIE=${RABBITMQ_ERLANG_COOKIE:-}
export RABBITMQ_ERLANG_COOKIE

RABBITMQ_CLUSTER_NODES=${RABBITMQ_CLUSTER_NODES:-}
if [ ! -z "$RABBITMQ_CLUSTER_NODES" ]; then
    RABBITMQ_CLUSTER_NODES=$(sed -r "s/([^ ,$]+)/ '\\1'/g" <<<"$RABBITMQ_CLUSTER_NODES")
fi

# autocluster environment
#AUTOCLUSTER_LOG_LEVEL=${AUTOCLUSTER_LOG_LEVEL-}
#AUTOCLUSTER_TYPE=${AUTOCLUSTER_TYPE-aws}
#AUTOCLUSTER_FAILURE=${AUTOCLUSTER_FAILURE-ignore}
#AWS_AUTOSCALING=${AWS_AUTOSCALING-false}
#AWS_USE_PRIVATE_IP=${AWS_USE_PRIVATE_IP-true}
#AUTOCLUSTER_CLEANUP=${AUTOCLUSTER_CLEANUP-false}
#CLEANUP_WARN_ONLY=${CLEANUP_WARN_ONLY-true}

#export $AUTOCLUSTER_LOG_LEVEL $AUTOCLUSTER_TYPE $AUTOCLUSTER_FAILURE $AWS_AUTOSCALING \
#       $AUTOCLUSTER_CLEANUP $CLEANUP_WARN_ONLY

definitions
echo "==> /etc/rabbitmq/definitions/definitions.json"
cat /etc/rabbitmq/definitions/definitions.json
rabbitmq_config
echo "==> rabbitmq.config"
cat /etc/rabbitmq/rabbitmq.config

erlang_cookie $RABBITMQ_ERLANG_COOKIE

exec "$@"
