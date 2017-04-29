#!/bin/bash
#

rm /etc/nginx/sites-enabled/default

app_root="/idevops/app/platform_registry"

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


replace_api_url()
{
    if [ ! "$API_HOST" == "" ]; then
        replace_var_in_file "192.168.99.101:8080" "$API_HOST" "${app_root}/config/api.php"
    fi
}

write_config()
{
    rm -f .env
    echo "APP_ENV=local" >> .env
    echo "APP_DEBUG=$APP_DEBUG" >> .env
    echo "API_HOST=$API_HOST" >> .env
    echo "APP_KEY=base64:2GaJtNQq43fS4dvnhuHv3HvgNAzn4PxsBiGOnKaS1kU=" >> .env
    echo "APP_LOCALE=zh_cn" >> .env

    echo "DB_CONNECTION=mysql" >> .env
    echo "DB_HOST=$DB_HOST" >> .env
    echo "DB_PORT=$DB_PORT" >> .env
    echo "DB_DATABASE=$DB_DATABASE" >> .env
    echo "DB_USERNAME=$DB_USERNAME" >> .env
    echo "DB_PASSWORD=$DB_PASSWORD" >> .env

    echo "CACHE_DRIVER=file" >> .env
    echo "SESSION_DRIVER=file" >> .env
    echo "QUEUE_DRIVER=redis" >> .env

    echo "REDIS_HOST=$REDIS_HOST" >> .env
    echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .env
    echo "REDIS_PORT=$REDIS_PORT" >> .env

    echo "CD_HOST=$CD_HOST" >> .env
    echo "CD_USER=$CD_USER" >> .env
    echo "CD_PWD=$CD_PWD" >> .env

    echo "REGISTRY_HOST=$REGISTRY_HOST" >> .env
    echo "REGISTRY_AUTH_USER=$REGISTRY_AUTH_USER" >> .env
    echo "REGISTRY_AUTH_PWD=$REGISTRY_AUTH_PWD" >> .env
    echo "REGISTRY_PAAS_API_URL=$REGISTRY_PAAS_API_URL" >> .env
}

check_env_vars()
{
    if [ "$APP_DEBUG" == "" ]; then
        export APP_DEBUG="false"
    fi
    if [ "$DB_HOST" == "" ]; then
        export DB_HOST="127.0.0.1"
    fi
    if [ "$DB_PORT" == "" ]; then
        export DB_PORT=3306
    fi
    if [ "$DB_USERNAME" == "" ]; then
        export DB_USERNAME="root"
    fi
    if [ "$DB_PASSWORD" == "" ]; then
        export DB_PASSWORD="root"
    fi
    if [ "$DB_DATABASE" == "" ]; then
        export DB_DATABASE="idevops_registry"
    fi
    if [ "$REDIS_HOST" == "" ]; then
        echo "ERROR: REDIS_HOST is not specified"
        return 1
    fi
    if [ "$REDIS_SERVICE_PORT" == "" ]; then
        export REDIS_PORT=6379
    else
        export REDIS_PORT=$REDIS_SERVICE_PORT
    fi
    if [ "$REDIS_PASSWORD" == "" ]; then
        export REDIS_PASSWORD=null
    fi

    return 0
}

link_volumns()
{
    storage_path="/idevops/app/platform_registry/storage"
    mnt_path="/mnt/platform_registry"
    if [ ! -e $mnt_path/storage ]; then
        cp -r $storage_path $mnt_path
        chown -R www-data:www-data $mnt_path/storage
    fi
    rm -rf $storage_path
    ln -s $mnt_path/storage `dirname $storage_path`
    chown www-data:www-data $storage_path
}

check_env_vars
if [ $? != 0 ]; then
    exit 1
fi

cd $app_root
replace_api_url
write_config
php artisan migrate
php artisan db:seed
link_volumns

service php5.6-fpm start

#service ssh start
service nginx start
#nginx -g "daemon off;"
/usr/sbin/sshd -D

