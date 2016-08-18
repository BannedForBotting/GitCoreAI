FROM centos:6

MAINTAINER Cazzy

ENV HOME /root
WORKDIR /root

RUN yum -y update && \
    yum -y install \
        perl \
		perl-ExtUtils-MakeMaker.x86_64 \
		perl-Time-HiRes.x86_64 \
		perl-Compress-Zlib.x86_64 \
		perl-Archive-Tar.x86_64 \
		perl-CPAN.x86_64 \
		perl-Digest-SHA \
		readline.x86_64 \
		perl-libwww-perl
		
RUN yum clean all

#RUN cpan 'ExtUtils'
#RUN cpan 'Socket'
#RUN curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious
#RUN curl -L cpanmin.us | perl - Mojolicious@5.51
#RUN cpan Mojolicious

ENV XKore_listenPort 6901
ENV XKore_listenPort_char 6902
ENV XKore_listenPort_map 6903
ENV webPort 6904
ENV webSocketPort 6905
#new WIN32 and Docker support
ENV DOCKER 1

#ADD . /openkore
COPY openkore/ /root/openkore/
WORKDIR /root/openkore
RUN chmod +x openkore.pl & chmod +x start.sh & chmod -R 777 ./control 

EXPOSE ${XKore_listenPort} ${XKore_listenPort_char} ${XKore_listenPort_map} ${webPort} ${webSocketPort} 

WORKDIR /root/openkore
CMD ["sh","start.sh"]