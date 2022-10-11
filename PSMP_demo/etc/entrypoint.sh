#!/bin/bash

if [ -z "$VAULT_USER" ]; then
	exit
fi

if [ -z "$VAULT_PASS" ]; then
	exit
fi

if [ -z "$VAULT_IP" ]; then
	exit
fi

if [ -z "$PSMP_APP_USER" ]; then
        PSMP_APP_USER="PSMP_APP_`hostname`"
fi

if [ -z "$PSMP_GW_USER" ]; then
        PSMP_GW_USER="PSMP_GW_`hostname`"
fi

if [ -z "$PSMPADB_APP_USER" ]; then
        PSMPADB_APP_USER="PSMP_ADB_`hostname`"
fi

if [ -z "$PSMP_CONFIG_SAFE" ]; then
        PSMP_CONFIG_SAFE="PVWAConfig"
fi

if [ -z "$PSMP_CONFIG_FOLDER" ]; then
        PSMP_CONFIG_FOLDER="Root"
fi

if [ -z "$PSMP_CONFIG_FILE" ]; then
        PSMP_CONFIG_FILE="PVConfiguration.xml"
fi

if [ -z "$PSMP_POLICIES_FILE" ]; then
        PSMP_POLICIES_FILE="Policies.xml"
fi

if [ -z "$PSMPADB_CONFIG_SAFE" ]; then
        PSMPADB_CONFIG_SAFE="PSMPADBridgeConf"
fi

if [ -z "$PSMPADB_CONFIG_FOLDER" ]; then
        PSMPADB_CONFIG_FOLDER="Root"
fi

if [ -z "$PSMPADB_CONFIG_FILE" ]; then
        PSMPADB_CONFIG_FILE="main_psmpadbridge.conf.linux.11.01"
fi

if [ -z "$PSMPADB_CONFIG_FILE_PATH" ]; then
        PSMPADB_CONFIG_FILE_PATH="/var/opt/CARKpsmpadb/$PSMPADB_CONFIG_FILE"
fi


if [ ! -f "/etc/opt/CARKpsmp/vault/psmpappuser.cred" ]
        echo "[Main]"                                                     >  $PSMPADB_CONFIG_FILE_PATH
        echo "MaxConcurrentRequests=40"                                   >> $PSMPADB_CONFIG_FILE_PATH
        echo "AutomaticParmsRefreshInterval=3600"                         >> $PSMPADB_CONFIG_FILE_PATH
        echo "ProviderCacheFolder=/var/opt/CARKpsmpadb/cache"                  >> $PSMPADB_CONFIG_FILE_PATH
        echo ""                                                           >> $PSMPADB_CONFIG_FILE_PATH
        echo "[Debug]"                                                    >> $PSMPADB_CONFIG_FILE_PATH
        echo "#CacheDebugLevels=1,2"                                      >> $PSMPADB_CONFIG_FILE_PATH
        echo "#AppProviderDebugLevels=1,2,3,4,5"                          >> $PSMPADB_CONFIG_FILE_PATH
        echo "#ADBridgeDebugLevels=1,2,3,4,5"                             >> $PSMPADB_CONFIG_FILE_PATH
        echo "#ProtocolDebugLevels=1,2"                                   >> $PSMPADB_CONFIG_FILE_PATH
        echo ""                                                           >> $PSMPADB_CONFIG_FILE_PATH
        echo "[Cache]"                                                    >> $PSMPADB_CONFIG_FILE_PATH
        echo "CacheLevel=Memory"                                          >> $PSMPADB_CONFIG_FILE_PATH
        echo ""                                                           >> $PSMPADB_CONFIG_FILE_PATH
        echo "[TCP]"                                                      >> $PSMPADB_CONFIG_FILE_PATH
        echo "Port=19923"                                                 >> $PSMPADB_CONFIG_FILE_PATH

        sed -i "s/ADDRESS=1.1.1.1/ADDRESS=$VAULT_IP/g" /psmp/vault.ini
        mv /psmp/vault.ini /etc/opt/CARKpsmp/vault/
        /opt/CARKpsmp/bin/createcredfile /home/user.cred Password -username "$VAULT_USER" -password "$VAULT_PASS"
        /opt/CARKpsmp/bin/envmanager "CreateEnv" -AcceptEULA "Y" -CredFile "/home/user.cred" -VaultEnvPath "/etc/opt/CARKpsmp/vault" -ICUFolder "/opt/CARKpsmp/bin" -LogsWSFolder "/var/opt/CARKpsmp" -PSMPAppUser "$PSMP_APP_USER" -PSMPGWUser "$PSMP_GW_USER" -PIMConfigSafe "$PSMP_CONFIG_SAFE" -PIMConfigPath "$PSMP_CONFIG_FOLDER" -PIMConfigFile "$PSMP_CONFIG_FILE" -PIMPoliciesFile "$PSMP_POLICIES_FILE" -InstallationType "C" >/dev/null 2>&1
        /opt/CARKpsmpadb/bin/createpsmpadbenv -CredFilePath "/home/user.cred" -VaultFilePath "/etc/opt/CARKpsmp/vault/vault.ini" -PSMPADBridgeConfSafe "$PSMPADB_CONFIG_SAFE" -MainPSMPADBridgeConfFilePath "$PSMPADB_CONFIG_FILE_PATH" -PSMPADBridgeUser "$PSMPADB_APP_USER" -PIMConfigurationSafe "$PSMP_CONFIG_SAFE" >/dev/null 2>&1

        sed -i "s/PSMPConfigurationSafe=\"PVWAConfig\"/PSMPConfigurationSafe=\"$PSMP_CONFIG_SAFE\"/g" /etc/opt/CARKpsmp/conf/basic_psmpserver.conf
        sed -i "s/PSMPConfigurationFolder=\"Root\"/PSMPConfigurationFolder=\"$PSMP_CONFIG_FOLDER\"/g" /etc/opt/CARKpsmp/conf/basic_psmpserver.conf
        sed -i "s/PSMPPVConfigurationFileName=\"PVConfiguration.xml\"/PSMPPVConfigurationFileName=\"$PSMP_CONFIG_FILE\"/g" /etc/opt/CARKpsmp/conf/basic_psmpserver.conf
        sed -i "s/PSMPPoliciesConfigurationFileName=\"Policies.xml\"/PSMPPoliciesConfigurationFileName=\"$PSMP_POLICIES_FILE\"/g" /etc/opt/CARKpsmp/conf/basic_psmpserver.conf

        #sed -i "s/AppProviderParmsSafe=\"\"/AppProviderParmsSafe=\"$PSMPADB_CONFIG_SAFE\"/g" /home/basic_psmpadbridge.conf
        #sed -i "s/AppProviderVaultParmsFolder=\"\"/AppProviderVaultParmsFolder=\"$PSMPADB_CONFIG_FOLDER\"/g" /home/basic_psmpadbridge.conf
        #sed -i "s/AppProviderVaultParmsFile=\"\"/AppProviderVaultParmsFile=\"$PSMPADB_CONFIG_FILE\"/g" /home/basic_psmpadbridge.conf
        #sed -i "s/PIMConfigurationSafe=\"\"/PIMConfigurationSafe=\"$PSMP_CONFIG_SAFE\"/g" /home/basic_psmpadbridge.conf
        #sed -i "s/PIMConfigurationFolder=\"\"/PIMConfigurationFolder=\"$PSMP_CONFIG_FOLDER\"/g" /home/basic_psmpadbridge.conf
        #sed -i "s/PIMPVConfigurationFileName=\"\"/PIMPVConfigurationFileName=\"$PSMP_CONFIG_FILE\"/g" /home/basic_psmpadbridge.conf
        #sed -i "s/PIMPoliciesConfigurationFileName=\"\"/PIMPoliciesConfigurationFileName=\"$PSMP_POLICIES_FILE\"/g" /home/basic_psmpadbridge.conf

        #mv /home/basic_psmpserver.conf /etc/opt/CARKpsmp/conf/
        #mv /home/basic_psmpadbridge.conf /etc/opt/CARKpsmpadb/conf/
fi

/etc/init.d/sshd start
/etc/init.d/psmpsrv start

rm /home/user.cred
unset VAULT_USER
unset VAULT_PASS

while true
do:
        sleep 5
done
