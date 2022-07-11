#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"


HOST_NAME="modsec_owasp"

docker container inspect "${HOST_NAME}" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  docker kill "${HOST_NAME}"
  docker rm "${HOST_NAME}"
fi

mkdir -p "${DIR}/logs/nginx" "${DIR}/logs/modsec"
sudo chmod 777  "${DIR}/logs/nginx" "${DIR}/logs/modsec"

# https://github.com/coreruleset/modsecurity-docker
# https://github.com/coreruleset/modsecurity-crs-docker

docker run -d --restart=unless-stopped --name "${HOST_NAME}" --hostname "${HOST_NAME}" \
 -p 80:80 \
 -p 443:443 \
 -e 'ALLOWED_METHODS=GET POST OPTIONS PUT PATCH DELETE' \
 -e PARANOIA=1 \
 -e BLOCKING_PARANOIA=1 \
 -e ANOMALY_INBOUND=6 \
 -e ANOMALY_OUTBOUND=4 \
 -e REPORTING_LEVEL=2 \
 -e MODSEC_AUDIT_ENGINE=RelevantOnly \
 -e MODSEC_REQ_BODY_ACCESS=On \
 -e MODSEC_REQ_BODY_ACCESS=On \
 -e MODSEC_REQ_BODY_LIMIT=1073741824 \
 -e ACCESSLOG=/var/log/nginx-logs/access.log \
 -e ERRORLOG=/var/log/nginx-logs/error.log \
 -e MODSEC_AUDIT_LOG=/var/log/modsecurity/audit/modsec-audit.log \
 -e MODSEC_AUDIT_STORAGE=/var/log/modsecurity/audit/ \
 -e CRS_ENABLE_TEST_MARKER=1 \
 -v "${DIR}/logs/modsec:/var/log/modsecurity/audit:rw" \
 -v "${DIR}/logs/nginx:/var/log/nginx-logs:rw" \
 -v "${DIR}/default.conf.template:/etc/nginx/templates/conf.d/default.conf.template:ro" \
 -v "${DIR}/request-body-limit.conf:/etc/modsecurity.d/owasp-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf:ro" \
 \
 owasp/modsecurity-crs:nginx-alpine
