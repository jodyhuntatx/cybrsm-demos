# CyberArk Vault Password Change Event Notification

## Directories
 - reference - original sources from which demo was assembled
 - vault_stuff
   - See: https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/DV-Integrating-with-SIEM-Applications.htm?#configure-encrypted-and-non-encrypted-protocols
   - DNS resolution on the vault server is not needed for the demo.
   - The "Cyber-Ark Event Notification Engine" service on the vault server is not needed for the demo.
   - CpmPwdChange.xsl - copy as-is to Vault server syslog directory
     - e.g. C:\Program Files (x86)\PrivateArk\Server\Syslog
   - dbparm.ini.syslog - edit as needed (IP address minimally) and replace or add to SYSLOG section of dbparm.ini file in Vault server Conf directory
     - e.g. C:\Program Files (x86)\PrivateArk\Server\Conf
 - rmq_stuff
   - 0_install_dependencies.sh
     - installs python3 and required packages
     - does NOT install docker (required for RabbitMQ container)
   - 1_start_rmqmgr.sh - starts RabbitMQ container w/ management features
   - 2_rmq_forwarder.py - starts syslog forwarder - runs as a background task if receiver is to run from same shell.
   - 3_rmq_receiver.py - RabbitMQ receiver - echoes received messages to console.
## Notes:
 - Only password changes made through CPM will generate events.
