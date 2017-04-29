#!/bin/bash

apt-get update
apt-get install -y software-properties-common
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
apt-get update
apt-get install -y php5.6
apt-get install -y php5.6-fpm php5.6-mysql php5.6-readline php5.6-mcrypt php5.6-ldap php5.6-json php5.6-gd php5.6-curl php5.6-xml php5.6-mbstring

