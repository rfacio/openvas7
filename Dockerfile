FROM debian:stretch
MAINTAINER "Debian Openvas Facio"

ENV TERM xterm
ENV LD_LIBRARY_PATH /usr/local/lib
ENV PATH $PATH:/usr/local/sbin:/usr/local/bin

RUN apt update && apt install -y curl gnupg apt-transport-https

RUN curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl --silent --show-error https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN echo "deb https://deb.nodesource.com/node_8.x stretch main" | tee /etc/apt/sources.list.d/nodesource.list

RUN apt update && apt upgrade -y && apt dist-upgrade -y && apt install -y build-essential cmake bison flex libpcap-dev pkg-config \
libglib2.0-dev libgpgme11-dev uuid-dev sqlfairy xmltoman doxygen libssh-dev libksba-dev libldap2-dev libsqlite3-dev \ 
libmicrohttpd-dev libxml2-dev libxslt1-dev xsltproc clang rsync rpm nsis alien sqlite3 libhiredis-dev libgcrypt11-dev \ 
libgnutls28-dev redis-server python python-pip mingw-w64 heimdal-multidev libpopt-dev libglib2.0-dev gnutls-bin certbot nmap ufw wget

RUN wget -O /usr/local/src/gvm-libs-9.0.3.tar.gz https://github.com/greenbone/gvm-libs/archive/v9.0.3.tar.gz && wget -O /usr/local/src/openvas-scanner-5.1.3.tar.gz https://github.com/greenbone/openvas-scanner/archive/v5.1.3.tar.gz && wget -O /usr/local/src/gvmd-7.0.3.tar.gz https://github.com/greenbone/gvmd/archive/v7.0.3.tar.gz && wget -O /usr/local/src/gsa-7.0.3.tar.gz https://github.com/greenbone/gsa/archive/v7.0.3.tar.gz && wget -O /usr/local/src/gvm-tools-1.4.1.tar.gz https://github.com/greenbone/gvm-tools/archive/v1.4.1.tar.gz && wget -O /usr/local/src/ospd-1.2.0.tar.gz https://github.com/greenbone/ospd/archive/v1.2.0.tar.gz && wget -O /usr/local/src/openvas-smb-1.0.4.tar.gz https://github.com/greenbone/openvas-smb/archive/v1.0.4.tar.gz 
    
RUN for SRC in gvm-libs-9.0.3 openvas-scanner-5.1.3 gvmd-7.0.3 gsa-7.0.3 ; \
    do \
       tar -C /usr/local/src -zxf /usr/local/src/${SRC}.tar.gz ; \
       cd /usr/local/src/${SRC} ; \
       cmake . && \
       make &&\
       make doc &&\
       make install ; \
    done

RUN tar -C /usr/local/src -zxf /usr/local/src/openvas-smb-1.0.4.tar.gz && cd /usr/local/src/openvas-smb-1.0.4 && cmake . && make && make install

RUN tar -C /usr/local/src -zxf /usr/local/src/ospd-1.2.0.tar.gz && cd /usr/local/src/ospd-1.2.0 && python setup.py install

RUN service redis-server stop && cp /etc/redis/redis.conf /etc/redis/redis.orig && echo "unixsocket /tmp/redis.sock" >> /etc/redis/redis.conf && echo "unixsocketperm 700" >> /etc/redis/redis.conf && service redis-server start && ldconfig

RUN greenbone-nvt-sync && greenbone-scapdata-sync && greenbone-certdata-sync && openvas-manage-certs -a && openvasmd --create-user=admin --role=Admin && openvasmd --user=admin --new-password=admin

CMD service redis-server start && openvassd -f & openvasmd -f & gsad -f --allow-header-host=192.168.239.137
