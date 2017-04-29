#!/bin/bash
#
# Build docker image of one component of iDevOps platform
#
# Usage: build.sh web|core|appmgr VERSION
#

usage()
{
    echo "Usage: build.sh web|core|appmgr|account|caas|registry VERSION"
}

replace_var_in_file()
{
    key=$1
    value=$2
    file=$3

    value=$(echo $value | sed 's/\\/\\\\/g')
    value=$(echo $value | sed 's/\//\\\//g')
    value=$(echo $value | sed 's/\&/\\\&/g')

    sed -i "s/${key}/${value}/g" $file
}

is_component_name_valid()
{
    COMPONENT_LIST=(web core appmgr account caas)
    for name in $COMPONENT_LIST
    do
        if [[ $name == $1 ]]; then
            return 0
        fi
    done

    return 1
}

get_repo_name()
{
    if [ "$1" == "web" ]; then
        repo_name="platform_frontend"
    elif [ "$1" == "core" ]; then
        repo_name="platform_core"
    elif [ "$1" == "appmgr" ]; then
        repo_name="application_management"
    elif [ "$1" == "account" ]; then
        repo_name="account_management"
    elif [ "$1" == "caas" ]; then
        repo_name="caas_management"
    elif [ "$1" == "registry" ]; then
        repo_name="platform_registry"
    else
        repo_name=""
    fi
}

if [[ $# != 2 ]]; then
    usage
    exit 1
fi

if [ "$DOCKER_HUB" == "" ]; then
    echo "Please set DOCKER_HUB environment variable"
    exit 1
fi

component_name=$1
version=$2

repo_name=""
get_repo_name $component_name
if [[ $repo_name == "" ]]; then
    usage
    exit 1
fi

if (python is_image_exist.py $DOCKER_HUB idevops/$repo_name $version >/dev/null); then
    echo "The following image already exists. Exiting..."
    echo "$DOCKER_HUB/idevops/$repo_name:$version"
    exit 1
fi

repo_tmp_dir=/tmp/idevops/workdir/$repo_name
sudo rm -rf $repo_tmp_dir 2>&1>/dev/null
mkdir -p $repo_tmp_dir
mkdir -p $repo_tmp_dir/dfiles

cp -r ./dfiles/$repo_name/* $repo_tmp_dir/dfiles

cd $repo_tmp_dir

#
# pull source code
#
git clone --branch $version https://zaric_zhang:d1b47af4601d8799989f9efa86ebb536@bitbucket.org/idevops/${repo_name}.git
if [ $? != 0 ]; then
    echo "Failed to get source code. Exiting..."
    exit 1
fi

if [ -e "$repo_tmp_dir/dfiles/compile.sh" ]; then
    cd $repo_tmp_dir/dfiles
    bash compile.sh $repo_tmp_dir/$repo_name
else
    sudo chown www-data:www-data -R ${repo_name}
    tar cvf $repo_tmp_dir/dfiles/${repo_name}.tar $repo_name
fi

cd $repo_tmp_dir/dfiles
image=${DOCKER_HUB}/idevops/${repo_name}:${version}
echo $image
replace_var_in_file "\$DOCKER_HUB" $DOCKER_HUB ./Dockerfile
docker build -t $image ./
if [ $? != 0 ]; then
    echo "docker build error. Please see the error message above"
    exit 1
fi
docker push $image

echo "DONE"

