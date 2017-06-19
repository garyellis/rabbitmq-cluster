#!/bin/bash

git_commit=$(git rev-parse --short HEAD)
image_name=$1:$git_commit
container_name=rabbitmq-server-$git_commit

tests=0
failures=0

tests_summary(){
    [ "$1" -gt 0 ] && \
      let failures++
    let tests++
}
setup_(){
    echo "==> setup"
    echo "    docker run -d --rm --name rabbitmq-server $image_name"
    docker run -d --rm --name $container_name $image_name && \
      # sleep 5 seconds for initialization to finish up
      sleep 5

    if [ "$?" -gt 0 ]; then
        echo "    setup failed. attempting teardown"
        teardown_ 2>1&>/dev/null
        exit 1
    fi
}
teardown_(){
    echo "==> teardown"
    echo "    docker kill $container_name"
    docker kill $container_name
}
test_rabbitmqctl_status(){
    # assert that rabbitmqctl status returns non zero exit code
    echo "==> test rabbitmqctl status"
    echo "    docker exec $container_name rabbitmqctl status"
    docker exec $container_name rabbitmqctl status
    tests_summary $?
}
test_root_user(){
    # assert that rabbitmq-server is not running as root
    echo "==> test rabbitmq-server running as non-root account"
    echo "    docker exec $container_name ps -ef"
    root_process_count=$(
        docker exec $container_name ps -ef |
        grep -v ps|awk '$1=="root" { print $0}' | wc -l
    )
    tests_summary $root_process_count
}

setup_
test_rabbitmqctl_status
test_root_user
teardown_

echo -e "\ntests: $tests failures: $failures\n"
if [ "$failures" -gt 0 ]; then
    exit 1
fi
