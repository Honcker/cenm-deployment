#!/bin/sh
{{ if eq .Values.bashDebug true }}
set -x
{{ end }}

#
# Download odbc jar
#
mkdir -p '/opt/corda/drivers'
curl --request GET -sL \
     --url 'https://jdbc.postgresql.org/download/postgresql-42.2.9.jar'\
     --output '/opt/corda/drivers/postgresql-42.2.9.jar'

#
# main run
#
if [ -f {{ .Values.jarPath }}/corda.jar ]
then
{{ if eq .Values.bashDebug true }}
    sha256sum {{ .Values.jarPath }}/corda.jar 
{{ end }}
    echo
    echo "CENM: starting Notary node ..."
    echo
    java -jar {{ .Values.jarPath }}/corda.jar -f {{ .Values.configPath }}/notary.conf
    EXIT_CODE=${?}
else
    echo "Missing notary jar file in {{ .Values.jarPath }} directory:"
    ls -al {{ .Values.jarPath }}
    EXIT_CODE=110
fi

if [ "${EXIT_CODE}" -ne "0" ]
then
    HOW_LONG={{ .Values.sleepTimeAfterError }}
    echo
    echo "Notary failed - exit code: ${EXIT_CODE} (error)"
    echo
    echo "Going to sleep for requested ${HOW_LONG} seconds to let you login and investigate."
    echo
    sleep ${HOW_LONG}
fi

echo