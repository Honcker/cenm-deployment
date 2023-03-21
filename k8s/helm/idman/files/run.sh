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
# Use jq to update the database.jdbcDriver field from the init.conf file
#

ls -alR {{ .Values.idmanJar.configPath }}
cat {{ .Values.idmanJar.configPath }}/identitymanager.conf

# back up the current conf file
cp {{ .Values.idmanJar.configPath }}/identitymanager.conf {{ .Values.idmanJar.configPath }}/identitymanager.conf.bak

# read the value of database.jdbcDriver that was originally configured in helm
jdbcDriverPath=$(jq -r .database.jdbcDriver {{ .Values.idmanJar.configPath }}/identitymanager-init.conf)

# write a temp.conf file from the updated identitymanager.conf
# replacing .database.jdbcDriver with the value intended by helm
jq --arg jdbcDriver "jdbcDriverPath" '.database.jdbcDriver |= jdbcDriver' \
{{ .Values.idmanJar.configPath }}/identitymanager.conf > {{ .Values.idmanJar.configPath }}/temp.conf

# replace identitymanager.conf with the new file
cp -f {{ .Values.idmanJar.configPath }}/temp.conf {{ .Values.idmanJar.configPath }}/identitymanager.conf

#
# main run
#
if [ -f {{ .Values.idmanJar.path }}/identitymanager.jar ]
then
{{ if eq .Values.bashDebug true }}
    sha256sum {{ .Values.idmanJar.path }}/identitymanager.jar
    cat {{ .Values.idmanJar.configPath }}/identitymanager.conf
{{ end }}
    echo
    echo "CENM: starting Identity Manager process ..."
    echo
    TOKEN=$(cat {{ .Values.idmanJar.configPath }}/token)
    ls -alR
    java -jar {{ .Values.idmanJar.path }}/angel.jar \
    --jar-name={{ .Values.idmanJar.path }}/identitymanager.jar \
    --zone-host={{ .Values.prefix }}-zone \
    --zone-port=25000 \
    --token=${TOKEN} \
    --service=IDENTITY_MANAGER \
    --working-dir=etc/ \
    --polling-interval=10 \
    --tls=true \
    --tls-keystore=/opt/cenm/DATA/key-stores/corda-ssl-identity-manager-keys.jks \
    --tls-keystore-password=password \
    --tls-truststore=/opt/cenm/DATA/trust-stores/corda-ssl-trust-store.jks \
    --tls-truststore-password=trust-store-password \
    --verbose
    EXIT_CODE=${?}
else
    echo "Missing Identity Manager jar file in {{ .Values.idmanJar.path }} directory:"
    ls -al {{ .Values.idmanJar.path }}
    EXIT_CODE=110
fi

if [ "${EXIT_CODE}" -ne "0" ]
then
    echo
    echo "Identity manager failed - exit code: ${EXIT_CODE} (error)"
    echo
    echo "Going to sleep for the requested {{ .Values.sleepTimeAfterError }} seconds to let you log in and investigate."
    echo
    sleep {{ .Values.sleepTimeAfterError }}
fi

echo