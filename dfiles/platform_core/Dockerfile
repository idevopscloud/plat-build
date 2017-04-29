FROM $DOCKER_HUB/idevops_base/u14-nginx1.4.6-php5.6
MAINTAINER iDevOps

ADD ./platform_core.tar /idevops/app/
ADD ./platform_core_nginx.conf /etc/nginx/sites-enabled/

ADD /start.sh /
CMD bash /start.sh

