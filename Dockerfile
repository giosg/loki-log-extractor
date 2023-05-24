FROM alpine:latest

ENV LOKI_SERVER="http://loki"  
ENV LOKI_CLI_VERSION="2.8.2" 
# Define the query and time range

ENV START_TIME="$(date -d 'yesterday' -u +%Y-%m-%dT%H:%M:%SZ)"
ENV END_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

ENV QUERY='{job="infra/jenkins"}' 
ENV GPG_RECEPIENT="dummy_email"
ENV S3_BUCKET="dummy_bucket" 
 
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

COPY log_extractor.sh  /usr/local/bin/log_extractor.sh 
RUN chmod +x /usr/local/bin/log_extractor.sh  

ENTRYPOINT ["log_extractor.sh"]

