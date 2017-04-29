#!/bin/bash
#
# Env var name                          not null
# ================================================
# APP_DEBUG=true|false                  (n)
# APP_OPS_HOST=http://domain_name       (y)
# APP_BASE_URL=http://domain_name       (y)
# MYSQL_HOST=172.30.80.20               (y)
# MYSQL_DB_NAME=ops_dev                 (y)
# MYSQL_USER=root                       (y)
# MYSQL_PASSWORD=aaaa                   (y)
# MYSQL_PREFIX=ops_                     (y)
# REDIS_HOST=172.30.80.20               (y)
# REDIS_SERVICE_PORT=6379               (n)

APP_ROOT="/idevops/app/platform_core"

rm /etc/nginx/sites-enabled/default
rm $APP_ROOT/app/config/dev/app.php


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

change_config()
{
    #
    # change app.php
    #
    APP_CONFIG_FILE="$APP_ROOT/app/config/app.php"
    cp -f ${APP_CONFIG_FILE}.template ${APP_CONFIG_FILE}
    replace_var_in_file "\$APP_DEBUG" "${APP_DEBUG}" $APP_CONFIG_FILE
    replace_var_in_file "\$APP_BASE_URL" "${APP_BASE_URL}" $APP_CONFIG_FILE
    replace_var_in_file "\$APP_OPS_HOST" "${APP_OPS_HOST}" $APP_CONFIG_FILE

    #
    # change database.php
    #

    DB_CONFIG_FILE="$APP_ROOT/app/config/database.php"
    cp -f ${DB_CONFIG_FILE}.template ${DB_CONFIG_FILE}
    replace_var_in_file "\$MYSQL_HOST" "${MYSQL_HOST}" $DB_CONFIG_FILE
    replace_var_in_file "\$MYSQL_DB_NAME" "${MYSQL_DB_NAME}" $DB_CONFIG_FILE
    replace_var_in_file "\$MYSQL_USER" "${MYSQL_USER}" $DB_CONFIG_FILE
    replace_var_in_file "\$MYSQL_PASSWORD" "${MYSQL_PASSWORD}" $DB_CONFIG_FILE
    replace_var_in_file "\$MYSQL_PREFIX" "${MYSQL_PREFIX}" $DB_CONFIG_FILE
    replace_var_in_file "\$REDIS_HOST" "${REDIS_HOST}" $DB_CONFIG_FILE
    replace_var_in_file "\$REDIS_PORT" "${REDIS_SERVICE_PORT}" $DB_CONFIG_FILE
}

check_env_vars()
{
    if [ "$APP_DEBUG" == "" ]; then
        export APP_DEBUG="false"
    fi
    if [ "$APP_DEBUG" != "false" -a "$APP_DEBUG" != "true" ]; then
        echo "ERROR: value of 'APP_DEBUG' env var must be 'true' or 'false'"
        return 1
    fi
    echo "APP_OPS_HOST=$APP_OPS_HOST"
    if [ "$APP_OPS_HOST" == "" ]; then
        echo "ERROR: value of 'APP_OPS_HOST' env var must be specified"
        return 1
    fi
    if [ "$APP_BASE_URL" == "" ]; then
        echo "ERROR: value of 'APP_BASE_URL' env var must be specified"
        return 1
    fi
    if [ "$MYSQL_HOST" == "" ]; then
        echo "ERROR: value of 'MYSQL_HOST' env var must be specified"
        return 1
    fi
    if [ "$MYSQL_DB_NAME" == "" ]; then
        echo "ERROR: value of 'MYSQL_DB_NAME' env var must be specified"
        return 1
    fi
    if [ "$MYSQL_USER" == "" ]; then
        echo "ERROR: value of 'MYSQL_USER' env var must be specified"
        return 1
    fi
    if [ "$MYSQL_PASSWORD" == "" ]; then
        echo "ERROR: value of 'MYSQL_PASSWORD' env var must be specified"
        return 1
    fi
    if [ "$MYSQL_PREFIX" == "" ]; then
        echo "ERROR: value of 'MYSQL_PREFIX' env var must be specified"
        return 1
    fi
    if [ "$REDIS_HOST" == "" ]; then
        echo "ERROR: value of 'REDIS_HOST' env var must be specified"
        return 1
    fi
    if [ "$REDIS_SERVICE_PORT" == "" ]; then
        export REDIS_SERVICE_PORT=6379
    fi
}

link_volumns()
{
    storage_path="$APP_ROOT/app/storage"
    mnt_path="/mnt/storage"

    for item in `ls $storage_path`
    do
        if [ ! -e $mnt_path/$item ]; then
            cp -r $storage_path/$item $mnt_path
        fi
    done

    rm -rf $storage_path
    ln -s /mnt/storage $storage_path
    chown www-data:www-data $storage_path
    chown www-data:www-data -R $mnt_path/*
}

check_env_vars
if [ $? != 0 ]; then
    echo "Exiting..."
    exit 1
fi

cd $APP_ROOT
change_config
php artisan migrate --force
php artisan db:seed --force
link_volumns

service php5.6-fpm start
#service ssh start
#nginx -g "daemon off;"
service nginx start
/usr/sbin/sshd -D

