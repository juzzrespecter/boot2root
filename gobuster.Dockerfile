FROM golang:1.27rc2-bookworm

WORKDIR /opt
RUN git clone https://github.com/Oj/gobuster \
	&& cd gobuster \
	&& go mod tidy \
	&& go build
RUN git clone https://github.com/drtychai/wordlists -c /usr/share/wordlists/

WORKDIR /opt/gobuster
ENTRYPOINT ./gobuster

