# kubectl version should be customizable, hard-coded now to 1.25

FROM nginx:alpine
COPY report-gen-hourly.sh /etc/periodic/hourly/report-gen
RUN apk update && apk upgrade && apk add --no-cache bash jq \
    && chmod +x /etc/periodic/hourly/* \
    && sed -i '/^exec/i crond -l 0 -L /dev/stdout'  /docker-entrypoint.sh \
    && sed -i '/^exec/i /etc/periodic/hourly/report-gen &'  /docker-entrypoint.sh \
    && sed -i 's/6/4/' /etc/crontabs/root \
    && sed -i 's/3/6/' /etc/crontabs/root \
    && curl -LO https://dl.k8s.io/release/v1.25.5/bin/linux/amd64/kubectl \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin
COPY util.js /var/util.js
