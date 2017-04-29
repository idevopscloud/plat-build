#!/bin/bash
#

# Env var name                          not null
# ================================================
# MYSQL_HOST=172.30.80.20               (y)
# MYSQL_PORT=3306                       (y)
# MYSQL_DB_NAME=ops_dev                 (y)
# MYSQL_USER=root                       (y)
# MYSQL_PASSWORD=aaaa                   (y)

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

function check_env_vars()
{
    if [ "$MYSQL_HOST" == "" ]; then
        echo "ERROR: value of 'MYSQL_HOST' env var must be specified"
        return 1
    fi
    if [ "$MYSQL_PORT" == "" ]; then
        echo "ERROR: value of 'MYSQL_PORT' env var must be specified"
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
    if [ "$MYSQL_DB_NAME" == "" ]; then
        echo "ERROR: value of 'MYSQL_DB_NAME' env var must be specified"
        return 1
    fi
}

check_env_vars
if [ $? != 0 ]; then
    echo "Exiting..."
    exit 1
fi

cd /opt/tomcat/webapps/idevops.api
jar -xvf idevops.api.war
rm idevops.api.war

CONFIG_FILE="/opt/tomcat/webapps/idevops.api/WEB-INF/classes/META-INF/persistence.xml"
replace_var_in_file "\$MYSQL_HOST" "${MYSQL_HOST}" $CONFIG_FILE
replace_var_in_file "\$MYSQL_PORT" "${MYSQL_PORT}" $CONFIG_FILE
replace_var_in_file "\$MYSQL_USER" "${MYSQL_USER}" $CONFIG_FILE
replace_var_in_file "\$MYSQL_PASSWORD" "${MYSQL_PASSWORD}" $CONFIG_FILE
replace_var_in_file "\$MYSQL_DB_NAME" "${MYSQL_DB_NAME}" $CONFIG_FILE

/usr/bin/java -Djava.util.logging.config.file=/opt/tomcat/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djdk.tls.ephemeralDHKeySize=2048 -Djava.endorsed.dirs=/opt/tomcat/endorsed -classpath /opt/tomcat/bin/bootstrap.jar:/opt/tomcat/bin/tomcat-juli.jar -Dcatalina.base=/opt/tomcat -Dcatalina.home=/opt/tomcat -Djava.io.tmpdir=/opt/tomcat/temp org.apache.catalina.startup.Bootstrap start

