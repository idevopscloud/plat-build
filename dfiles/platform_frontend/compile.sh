#!/bin/bash

if [ $# != 1 ]; then
    echo "Usage: compile.sh SRC_DIR"
    exit 1
fi

src_dir=$1
repo_name="platform_frontend"
dfile_dir=$(pwd)
cur_time=$(date +%Y%m%d%H%M)

sed -i "4s/201604152011/${cur_time}/g" $src_dir/app/script/main.js
sed -i "s/20160726/${cur_time}/g" $src_dir/index.html
sed -i "s/20160726/${cur_time}/g" $src_dir/app.html

sudo chown www-data:www-data -R $src_dir
cd $src_dir/../
tar cvf ${dfile_dir}/${repo_name}.tar $repo_name

