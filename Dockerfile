FROM alpine:latest

ENV LOKI_CLI_VERSION="2.8.2" 
 
RUN apk update && apk add --no-cache \ 
coreutils \
aws-cli \ 
gpg \
gpg-agent \ 
bash \
xz \
unzip \
curl

RUN curl -LO "https://github.com/grafana/loki/releases/download/v{$LOKI_CLI_VERSION}/logcli-linux-amd64.zip" && \
    unzip logcli-linux-amd64.zip && \
    mv logcli-linux-amd64 /usr/local/bin/logcli && \
    rm logcli-linux-amd64.zip && \
    chmod +x /usr/local/bin/logcli

COPY logscrapper.sh  /usr/local/bin/logscrapper.sh
RUN chmod +x /usr/local/bin/logscrapper.sh

ENTRYPOINT ["logscrapper.sh"]

