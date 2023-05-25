# loki-log-extractor
Extract audit logs from Loki 

bash
```
sudo docker run -it -v keys:/secrets/ -e GPG_PUBLIC_KEY_PATH=/secrets/gpg_public_key.asc -e AWS_ACCESS_KEY_ID='<put the key here>' -e AWS_SECRET_ACCESS_KEY='<put the key here>'' -e AWS_DEFAULT_REGION='eu-central-1' -e LOKI_ADDR="http://k8s-loki-gateway-loki.service.fsn1-sb.giosg.local:30101" giosg/logscrapper:0.1 <put the query here e.g. {job="infra/jenkins"}' >'