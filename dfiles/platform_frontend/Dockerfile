FROM nginx:1.10.1
MAINTAINER iDevOps

ADD ./platform_frontend.tar /idevops/
ADD ./platform-frontend-nginx.conf /etc/nginx/conf.d/

ADD /start.sh /
CMD bash /start.sh

