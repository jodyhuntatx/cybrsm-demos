# Bamboo Datacenter integration with Conjur Enterprise

### Run: 0-start-server.sh
This will build the Bamboo Datacenter image as an Ubuntu 20.04 Linux installation and create a Conjur host ID for use in configuring the Windtunnel Secret Managers plugin.

For a video to see how to configure Bamboo, the Windtunnel plugin and create a demo Project/Plan/Task watch:
https://www.youtube.com/watch?v=zA9gwd2I1Gw

Config steps:
 - Install cybr-cli locally and ensure it can login to Conjur Enterprise
 - run: 0-start-server.sh
 - Open Bamboo UI
 - Get demo license at link, copy/paste into window
 - Click Continue to accept default configuration values
 - Select H2 database as backing store, it takes a minute to initialize
 - On Import Data window, select default "Create new Bamboo home..." and continue
 - Create admin user w/ name & password of your choosing
 - Final setup takes another minute or so...
 - Click on sprocket icon in upper right, select Agents
 - Click Add Local Agent and give it a name of your choice
 - Ignore error notices about database and agent, they are apparently benign
 - On left navigation menu, scroll down to "Find apps", click to access Atlassian Marketplace
 - Search for "secret" (NOT plural) and select 

### Bamboo Datacenter doc:
- https://confluence.atlassian.com/bamboo/installing-bamboo-on-linux-289276792.html
### Secret Managers for Bamboo doc:
- https://windtunnel.io/products/smb/#/tutorials/cac

