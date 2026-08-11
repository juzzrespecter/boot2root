FROM golang:1.27rc2-bookworm

WORKDIR /opt

# gobuster
RUN git clone https://github.com/Oj/gobuster \
	&& cd gobuster \
	&& go mod tidy \
	&& go build \
	&& ln -s /opt/gobuster/gobuster /usr/bin

# katana
RUN CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest
RUN git clone https://github.com/drtychai/wordlists /usr/share/wordlists/

#john jumbo
RUN git clone https://github.com/openwall/john /opt/john \
	&& cd /opt/john/src \
	&& ./configure && make \
	&& ln -s /opt/john/run/john /usr/bin \
	&& ln -s /opt/john/run/ssh2john /usr/bin

ENTRYPOINT ["/bin/bash"]