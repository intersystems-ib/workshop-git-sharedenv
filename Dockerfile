FROM intersystemsdc/irishealth-community:2022.1.0.209.0-zpm

USER root

# install tools
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
RUN apt-get update && apt-get install -y \
  software-properties-common \
  openssh-client \
  vim

# install latest git
RUN add-apt-repository -y ppa:git-core/ppa
RUN apt-get update && apt-get install -y \
  git \
  && rm -rf /var/lib/apt/lists/*

COPY --chown=$ISC_PACKAGE_IRISMGR:$ISC_PACKAGE_IRISGROUP irissession.sh /
RUN chmod +x /irissession.sh

USER ${ISC_PACKAGE_MGRUSER}

# copy files to container
COPY install /opt/irisapp/install
COPY src /opt/irisapp/src

SHELL ["/irissession.sh"]
RUN \
  zn "%SYS" \
  do $SYSTEM.OBJ.Load("/opt/irisapp/src/Workshop/Installer.cls", "ck") \
  # setup environment (namespaces, users, etc.)
  set sc = ##class(Workshop.Installer).Run(.vars) \
  # install git-source-control package (zpm)
  zn "DEV" \
  zpm "install git-source-control" \  
  zn "PROD" \
  zpm "install git-source-control" \ 
  set sc = 1
  
# bringing the standard shell back
SHELL ["/bin/bash", "-c"]
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]