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
RUN curl -L cpanmin.us | perl - Mojolicious@5.51
#RUN cpan Mojolicious

#ENV XIP 8.8.8.8
ENV XLISTEN_PORT 6901
ENV WLISTEN_PORT 6902
ENV ULISTEN_PORT 6903
ENV WSLISTEN_PORT 6904

#ADD . /openkore
COPY openkore/ /root/openkore/
WORKDIR /root/openkore
RUN chmod +x openkore.pl & chmod +x start.sh & chmod -R 777 ./control 

EXPOSE ${XLISTEN_PORT} ${WLISTEN_PORT} ${ULISTEN_PORT} ${WSLISTEN_PORT} 

WORKDIR /root/openkore
CMD ["sh","start.sh"]

