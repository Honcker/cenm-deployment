#!/bin/sh
{{ if eq .Values.bashDebug true }}
set -x
{{ end }}

#
# Download odbc jar
#
pwd
mkdir -p '/opt/cenm/drivers'
curl --request GET -sL \
     --url 'https://jdbc.postgresql.org/download/postgresql-42.2.9.jar'\
     --output '/opt/cenm/drivers/postgresql-42.2.9.jar'

#
# main run
#
if [ -f bin/accounts-application.jar ]
then
    echo
    echo "CENM: starting CENM Auth service ..."
    echo
    java -jar bin/accounts-application.jar --config-file authservice.conf --initial-user-name admin --initial-user-password p4ssWord --keep-running --verbose
    EXIT_CODE=${?}
else
    echo "Missing Auth service jar file."
    EXIT_CODE=110
fi

if [ "${EXIT_CODE}" -ne "0" ]
then
    HOW_LONG={{ .Values.sleepTimeAfterError }}
    echo
    echo "Auth service failed - exit code: ${EXIT_CODE} (error)"
    echo
    echo "Going to sleep for the requested {{ .Values.sleepTimeAfterError }} seconds to let you log in and investigate."
    sleep {{ .Values.sleepTimeAfterError }}
    echo
fi

echo