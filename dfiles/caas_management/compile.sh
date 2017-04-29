#!/bin/bash

if [ $# != 1 ]; then
    echo "Usage: compile.sh SRC_DIR"
    exit 1
fi

src_dir=$1
docker run -ti -v $src_dir:/src u14-maven:3.0.5-jdk-8 bash -c 'cd /src; mvn -Dmaven.test.skip=true install'
cp $src_dir/target/idevops.api.war ./
