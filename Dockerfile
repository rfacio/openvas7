FROM debian:stretch
MAINTAINER Facio

ENV TERM xterm
ENV LD_LIBRARY_PATH /usr/local/lib
ENV PATH $PATH:/usr/local/sbin:/usr/local/bin

RUN apt update && apt upgrade -y && apt dist-upgrade -y && apt install -y build-essential cmake bison flex libpcap-dev pkg-config libglib2.0-dev libgpgme11-dev uuid-dev sqlfairy xmltoman doxygen libssh-dev libksba-dev libldap2-dev libsqlite3-dev libmicrohttpd-dev libxml2-dev libxslt1-dev xsltproc clang rsync rpm nsis alien sqlite3 libhiredis-dev libgcrypt11-dev libgnutls28-dev redis-server texlive-latex-base texlive-latex-recommended  python python-pip mingw-w64 heimdal-multidev libpopt-dev libglib2.0-dev gnutls-bin certbot nmap ufw

ADD http://wald.intevation.org/frs/download.php/2420/openvas-libraries-9.0.1.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2423/openvas-scanner-5.1.1.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2448/openvas-manager-7.0.2.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2429/greenbone-security-assistant-7.0.2.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2397/openvas-cli-1.4.5.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2377/openvas-smb-1.0.2.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2401/ospd-1.2.0.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2405/ospd-debsecan-1.2b1.tar.gz /usr/local/src/
ADD http://wald.intevation.org/frs/download.php/2218/ospd-nmap-1.0b1.tar.gz /usr/local/src/
    
RUN for SRC in openvas-libraries-9.0.1 openvas-manager-7.0.2 openvas-scanner-5.1.1 openvas-cli-1.4.5 \
               greenbone-security-assistant-7.0.2 ; \
    do \
       tar -C /usr/local/src -zxf /usr/local/src/${SRC}.tar.gz ; \
       cd /usr/local/src/${SRC} ; \
       cmake . && \
       make &&\
       make doc &&\
       make install ; \
    done

#RUN for PIP in requests Pexpect ; do pip install ${PIP} ; done
RUN for SRC in ospd-1.2.0 ospd-debsecan-1.2b1 ospd-nmap-1.0b1 ; \
    do \
        tar -C /usr/local/src -zxf /usr/local/src/${SRC}.tar.gz ; \
	cd /usr/local/src/${SRC} ; \
	python setup.py install ; \
    done

COPY conf/redis.conf /etc/redis/redis.conf
RUN chmod 755 /etc/redis/redis.conf
RUN service redis-server restart
#RUN ln -s /tmp/systemd-private-*-redis-server.service-*/tmp/redis.sock /tmp/redis.sock

RUN ldconfig
RUN openvassd
RUN greenbone-nvt-sync && greenbone-scapdata-sync && greenbone-certdata-sync
RUN openvasmd --progress --rebuild
RUN openvas-manage-certs -a
RUN openvassd
RUN openvasmd
RUN gsad 

EXPOSE 80 443

COPY conf/openvas.run /usr/local/bin/
RUN chmod +x /usr/local/bin/openvas.run
CMD ["/usr/local/bin/openvas.run"]
