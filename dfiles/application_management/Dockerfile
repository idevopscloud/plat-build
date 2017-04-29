FROM $DOCKER_HUB/idevops_base/u14-nginx1.4.6-php5.6
MAINTAINER iDevOps

ADD ./application_management.tar /idevops/app/
ADD ./application-management-nginx.conf /etc/nginx/sites-enabled/

ADD /start.sh /
CMD bash /start.sh

