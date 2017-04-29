FROM $DOCKER_HUB/idevops_base/u14-tomcat:8.0.36-jdk-8
MAINTAINER iDevOps

ADD idevops.api.war /opt/tomcat/webapps/idevops.api/
ADD /start.sh /
CMD bash /start.sh

