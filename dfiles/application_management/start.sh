#!/bin/bash
#

rm /etc/nginx/sites-enabled/default

app_root="/idevops/app/application_management"

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
#replace_var_in_file "api.idevops.net" "$API_HOST"  "${app_root}/app/Providers/Api/ApiProvider.php"
        replace_var_in_file "192.168.99.101:8080" "$API_HOST" "${app_root}/config/api.php"
    fi
}

write_config()
{
    rm -f .env
    echo "APP_ENV=local" >> .env
    echo "APP_DEBUG=$APP_DEBUG" >> .env
    echo "APP_KEY=base64:2GaJtNQq43fS4dvnhuHv3HvgNAzn4PxsBiGOnKaS1kU=" >> .env
    echo "APP_URL=http://localhost" >> .env
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

    echo "MAIL_DRIVER=smtp" >> .env
    echo "MAIL_HOST=mailtrap.io" >> .env
    echo "MAIL_PORT=2525" >> .env
    echo "MAIL_USERNAME=null" >> .env
    echo "MAIL_PASSWORD=null" >> .env
    echo "MAIL_ENCRYPTION=null" >> .env

    echo "PAAS_API_URL=$PAAS_API_URL" >> .env
    echo "K8S_END_POINT=$K8S_END_POINT" >> .env
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
        export DB_DATABASE="idevops_application"
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
    storage_path="/idevops/app/application_management/storage"
    mnt_path="/mnt/application_management"
    if [ ! -e $mnt_path/storage ]; then
        cp -r $storage_path $mnt_path
        chown -R www-data:www-data $mnt_path/storage
    fi
    rm -rf $storage_path
    ln -s $mnt_path/storage `dirname $storage_path`
    chown www-data:www-data $storage_path

    icon_path="/idevops/app/application_management/public/icons"
    mkdir -p /mnt/application_management/icons
    chown www-data:www-data /mnt/application_management/icons
    rm -rf $icon_path
    ln -s $mnt_path/icons `dirname $icon_path`
    chown www-data:www-data $icon_path
}

check_env_vars
if [ $? != 0 ]; then
    exit 1
fi

cd $app_root
replace_api_url
write_config
php artisan key:generate
php artisan migrate
php artisan db:seed
link_volumns

service php5.6-fpm start
nohup php artisan queue:work --daemon &

# status deploy status monitor
nohup su - www-data -s /bin/bash -c $app_root/app/Console/Scripts/DeployStatusMonitor.sh &

# start cron deamon and install crontab
cron
crontab -u www-data $app_root/app/Console/Scripts/Crontab

#service ssh start
service nginx start
#nginx -g "daemon off;"
/usr/sbin/sshd -D

