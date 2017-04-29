FROM $DOCKER_HUB/idevops_base/u14-nginx1.4.6-php5.6
MAINTAINER iDevOps

ADD ./account_management.tar /idevops/app/
ADD ./nginx.conf /etc/nginx/sites-enabled/

ADD /start.sh /
CMD bash /start.sh

