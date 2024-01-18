# WebSphere Application Server (WAS) ASCP demo in Docker

## Overview
The demo consists of three containers:
 - WebSphere
 - MSSQLserver database
 - MSSQLserver client

The demo configuration is driven by values in wasascpdemo.config.
Edit that before running any scripts.

## IBM account
You will need an account with IBM to access the WAS repository. Set that up here:
  https://www.ibm.com/account/reg/us-en/subscribe?formid=urx-30292
Accounts are free, but required for repo access.

## Demo startup steps
 0) Download zipfiles (see Helpful Links below)
    - IBM installer
    - MSSQLserver JDBC driver
    - CyberArk CP for Ubuntu
    - CyberArk ASCP
    - You do NOT need to unzip these, just edit wasascpdemo.config w/ location/filenames.
 1) Edit wasascpdemo.config
    - Set paths to zipfiles
    - Provide CyberArk vault and localhost DNS names/IP addresses 
    - Set DB_USERNAME and DB_PASSWORD to values in MSSQLserver account in the CyberArk vault.
 2) run: 0-build-base-image.sh
    - Builds a base image with WAS installed.
    - Runs IBM Installation Manager to install WAS using response file.
    - CyberArk Credential Provider package is staged but not installed.
    - If the script does not work, consult installation doc at:
      https://www.ibm.com/support/knowledgecenter/SSEQTP_9.0.5/com.ibm.websphere.installation.base.doc/ae/tins_installation_cl.html
 3) run: was-start-container
    - Starts the wasascp container and installs CP.
    - Lists JDBC driver jarfiles in WAS container.
    - Opens browser windows for WAS admin console & CyberArk ASCP docs for install/config.
 4) run: db-start
    - Builds the MSSQLserver images if they don't exist.
    - Starts the DB & CLI containers.
    - Once available, initializes DB with the petclinic database and user.
 5) Configure the test application:
    - In WAS admin console, left menu:
      - Applications...New Application...New Enterprise Application
    - local file system, select TestDataSource.war, fast path
    - Step 2: next
    - Step 3: select app, browse for target JNDI, select your target, apply
    - Step 4: next
    - Step 5: Context root, /testapp
    - Step 6: next
    - Step 7: finish, save
    - In WAS admin console, left menu:
      - Applications...Application Types...WebSphere Enterprise Applications
    - select TestDataSource.war, start, confirm green arrow
    - App is at:
       http://localhost:9080/testapp
    - WebSphere system out logs are at:
       /opt/IBM/WebSphere/AppServer/profiles/default/logs/server1/SystemOut.log

## Repo artifact descriptions:
 - 0-build-base-image.sh - builds image with WAS appserver installed.
 - Dockerfile.was - creates initial WAS base image.
 - Dockerfile.mssql-cli - creates initial MSSQLserver CLI image.
 - Dockerfile.mssql-db - creates initial MSSQLserver DB image.
 - TestDataSource.war - CyberArk-provided test app.
 - db-adduseracct.sql - SQL command template to add a user to MSSQLserver.
 - db-cli - execs into CLI container where you can execute interactive SQL statements.
 - db-petclinic.sql - SQL command file to create the petclinic database.
 - db-start - builds MSSQLserver DB & CLI images (if needed), starts both and initializes DB with SQL files.
 - db-stop - stops both DB and CLI containers.
 - response-file - used to silently install WAS installation during 0-build-image.sh execution.
 - was-exec-shell - execs into WAS container.
 - was-get-systemout-tail - gets last n lines of WAS SystemOut.log (n defaults to 100 if not provided)
 - was-restart-server - restarts WAS inside container - necessary after configuration.
 - was-start-container - starts and initializes WAS container, incl. CP.
 - was-stop-container - stops and removes WAS container.
 - wasascpdemo.config - configuration parameters.

## Hard-won knowledge
 - When creating the J2C authentication alias (step 1 in ASCP administration doc), use the actual user credentials for the database so you can test the connection before continuing. Once the connection test succeeds, change the User ID and Password to garbage values.
 - Account query strings CANNOT contain blank spaces or end with ';'. If you leave a ';' at the end, you'll get an error message. If you leave a blank space, your query will not find the account, but the error message will deceptively include the entire query, which actually succeeds in other contexts, e.g. w/ clipasswordsdk.
 - If you edit the account query, your changes will NOT take effect until you restart WAS.


## Helpful links
### IBM Installation Manager
 - Documentation: https://www.ibm.com/docs/en/installation-manager/1.9.2?topic=SSDV2W_1.9.2/com.ibm.silentinstall12.doc/topics/t_silent_installIM_IMinst.htm
 - Download: https://www.ibm.com/support/fixcentral/swg/selectFixes?parent=ibm~Rational&product=ibm/Rational/IBM+Installation+Manager&function=all

### WAS Repository installation
 - https://www.ibm.com/support/knowledgecenter/SSAW57_9.0.5/com.ibm.websphere.installation.nd.doc/ae/tins_productfiles_im.html

### MSSQLserver JDBC driver download
 - https://docs.microsoft.com/en-us/sql/connect/jdbc/download-microsoft-jdbc-driver-for-sql-server

### WAS Admin console
 - https://localhost:9043/ibm/console (or whatever port you set HTTPS_ADMIN_PORT to in config file).

### CyberArk ASCP doc pages
 - Installation: https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-CP/Latest/en/Content/CP%20and%20ASCP/Installing-App-Server-WebSphere-AppServerClassic.htm?tocpath=Installation%7CApplication%20Server%20Credential%20Provider%7CWebSphere%20installation%7C_____1#Installonaclassicserver
 - Configuration: https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-CP/Latest/en/Content/CP%20and%20ASCP/Configuring-App-Server-WebSphere-AppServerClassic.htm?tocpath=Administration%7CApplication%20Server%20Credential%20Provider%7CWebSphere%20Configuration%7C_____1#Globalconfiguration
