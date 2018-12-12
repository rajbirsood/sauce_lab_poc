#Designate base OS
FROM ubuntu:16.04
#Get vim, allowing for file edits in the running image
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]
#Get Sauce Labs test automation dependencies
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "curl"]
RUN ["curl", "https://bootstrap.pypa.io/get-pip.py", "-o", "get-pip.py"]
RUN ["apt-get", "install", "-y", "python3-pip"]
RUN ["/usr/bin/python3", "get-pip.py"]
RUN ["pip", "install", "-U", "selenium"]
#Get supervisord for container process management
RUN ["apt-get", "install", "-yq", "supervisor"]

#Get CA certs required for the SauceLabs client service to auth with
#saucelabs.com
RUN ["apt-get", "install", "-y", "ca-certificates"]
#Push supervisord config file
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#Expose required SauceClient connect ports
EXPOSE 8000 8001
#SauceClient prerequisites...
#Push and extract latest Sauce connect client from local system to docker image
#Modify sc@service with valid SauceLabs account credentials prior to pushing
COPY sc-4.5.2-linux /sc-4.5.2-linux

#Configure Sauce connect binary
RUN ["cp", "-p", "sc-4.5.2-linux/bin/sc", "/usr/local/bin/sc"]
#Set Sauce connect binary permissions
RUN ["chown", "nobody:", "/usr/local/bin/sc"]

#Copy SauceClient service files to the appropriate directories and configure
RUN ["cp", "-p", "sc-4.5.2-linux/config_examples/systemd/sc.service","/etc/systemd/system/sc.service"]
RUN ["cp", "-p", "sc-4.5.2-linux/config_examples/systemd/sc@.service","/etc/systemd/system/sc@.service"]
RUN ["bash", "-c", "cd", "/etc/systemd/system/"]


#Configure SauceConnect listening ports
RUN ["mkdir", "-p", "./sc.service.wants"]
RUN ["ln", "-s", "/etc/systemd/system/sc@.service","./sc.service.wants/sc@8000.service"]
RUN ["ln", "-s", "/etc/systemd/system/sc@.service","./sc.service.wants/sc@8001.service"]
#Start background supervisord process and start SauceClient service
RUN ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

