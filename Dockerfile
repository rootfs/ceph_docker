FROM centos:7
MAINTAINER Huamin Chen, hchen@redhat.com 

ADD install.sh /
RUN /install.sh
ADD init.sh /
