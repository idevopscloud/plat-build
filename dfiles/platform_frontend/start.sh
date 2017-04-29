#!/bin/bash

rm /etc/nginx/conf.d/default.conf

app_root="/idevops/platform_frontend"

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

if [ ! "$API_HOST" == "" ]; then
    replace_var_in_file "192.168.99.101:8080" "$API_HOST:$API_PORT" "${app_root}/app/script/main.js"
    replace_var_in_file "192.168.99.101:8080" "$API_HOST:$API_PORT" "${app_root}/app.html"
    replace_var_in_file "192.168.99.101:8080" "$API_HOST:$API_PORT" "${app_root}/index.html"
    replace_var_in_file "192.168.99.101:8080" "$API_HOST:$API_PORT" "${app_root}/login.html"
fi

if [ ! "$APP_HOST" == "" ]; then
    replace_var_in_file "192.168.99.101:8082" "$APP_HOST" "${app_root}/app/script/main.js"
fi

if [ ! "$REGISTRY_HOST" == "" ]; then
    replace_var_in_file "192.168.99.101:8084" "$REGISTRY_HOST" "${app_root}/app/script/main.js"
fi

if [ "$SERVICE_PORT_MIN" != "" ]; then
    sed -i "s/40000/$SERVICE_PORT_MIN/g" $app_root/app/widget/app/manage/component/tpl.html
fi
if [ "$SERVICE_PORT_MAX" != "" ]; then
    sed -i "s/42000/$SERVICE_PORT_MAX/g" $app_root/app/widget/app/manage/component/tpl.html
fi

nginx -g "daemon off;"

