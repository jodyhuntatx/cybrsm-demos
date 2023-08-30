# Dual Accounts Accelerator

## Goals:
- Demonstrate best-practices for Ansible w/ CyberArk Secrets Management.
- Provide example workflows for provisioning Ansible access to credentials managed by CyberArk.
- For a detailed description:
  - https://github.com/conjurdemos/Accelerator-Ansible#description-of-demo

## Prerequisites
 - Admin access to a NON-PRODUCTION Cyberark Identity tenant
 - Admin access to a NON-PRODUCTION CyberArk Privilege Cloud tenant
 - A CyberArk Identity service user & oauth2 confidential client with the Privilege Cloud Admin role.
 - A demo host - a MacOS or Linux VM environment with bash shell support, jq installed and IPV4 network access to the CyberArk PVWA APIs.
 - Make sure all scripts are executable. Run: chmod -R +x *.sh

## Why are Dual Accounts necessary?

 - Secret rotations are a fundamental security best-practice. But if care is not taken, rotating secrets can lead to application outages.
 - If an application holds onto a secret value, it won’t work once it’s been rotated in the target database, service, server, etc. This could lock the application out of the target system.
 - Applications should always fetch the secret from its source (CP, Conjur, Secrets Hub…) right before using it. That helps guarantee the application has an up-to-date secret, but is not sufficient:
   - Some applications require continuous connectivity.
   - Some databases will break a connection on password change.
   - With some secrets management solutions, there is unavoidable lag time (latency) between when the password is changed, and when the new value is available to the application.
 - One method to counter this is to coordinate rotations during a precisely timed change window. Most organizations dislike this idea, it’s inconvenient, definitely not foolproof, and some applications can’t be brought down or paused for a change window.
 - A more automated, simple and foolproof solution is Dual Accounts, supported by the CyberArk Vault.
 - Dual Accounts are similar to a DevOps application deployment model call [Blue/Green Deployments](https://www.redhat.com/en/topics/devops/what-is-blue-green-deployment).
 - See [this explainer video](https://youtu.be/i122iZWKVb0) for a thorough description and demo.

# Dual Accounts Automation

 - The scripts in the Dual Accounts Accelerator automate the tasks required to create Dual Accounts in Self-Hosted or Privilege Cloud vaults.
 - The Accelerator provides out-of-box support for the Platforms in the ./platformlib directory (the “Platform Library”).
 - Support for other Platforms can be added following the directions below.



# Manual Dual Accounts Configuration Overview

Dual Accounts are currently documented under the Central Credential Provider:
[Home > Administration > Central Credential Provider > Accounts and Safes > Manage dual accounts](https://docs.cyberark.com/AAM-CP/13.0/en/Content/CP%20and%20ASCP/cv_Managing-Dual-Accounts.htm)
The steps below map to the steps in documentation. The steps in the slides deviate somewhat from the manual configuration steps in the documentation. But they have the same effect. The [manual configuration steps](https://docs.cyberark.com/AAM-CP/13.0/en/Content/CP%20and%20ASCP/cv_Automatic_dual_account.htm?tocpath=Administration%7CCentral%20Credential%20Provider%7CAccounts%20and%20Safes%7CManage%20dual%20accounts%7C_____1) in the online docs for Self-Hosted PAM also work for Privilege Cloud.

Each step below has its own slide with more detailed instructions.
### Step 1: “Configure a rotational group platform”
A Rotational Group Platform is an Account Group Platform with important differences:
 - Its PlatformType is RotationalGroup
 - It contains an additional password change parameter called GracePeriod
 - It defines additional properties representing the state of individual sets of dual accounts: CurrInd, Index, VirtualUserName, DualAccountStatus
There is no need for more than one Rotational Group Platform unless you want to have groups with different Grace Periods.
### Step 2: “Configure the object’s platform for dual account support”
This entails modifying a target account platform to add three additional properties: Index, VirtualUserName, DualAccountStatus
### Step3: “Configure accounts and groups for dual account support”
To see the CPM tab and create groups, the safe must have a CPM assigned to it.
Account groups are not first-class UI objects in PVWA. They do not have their own pages for managing their lifecycle. In PVWA, they only appear in the classic UI on account pages under the CPM tab. 

### Step 4: “Set the index of the group object”
The documentation calls for using the Private Ark Client to modify the CurrInd value of a group. Fortunately, this step does not appear necessary, given that you cannot use the Private Ark Client with Privilege Cloud.

## 
![Dual Accounts Object Model](https://github.com/conjurdemos/Accelerator-DualAccounts/blob/main/DualAccountsObjectModel.png?raw=true)

# Step 1: “Configure a rotational group platform”
Under Groups, activate the Sample Password Group Platform, export it to a local zipfile & unzip to create two files:
Policy-SampleGroup.ini
Policy-SampleGroup.xml
Modify the .ini file:
Change the PolicyID and PolicyName to something meaningful, e.g. DualAccountsPolicy
Change the PolicyType to RotationalGroup (capitalization is significant)
Add the following lines at the end of the file, no leading or trailing spaces:
[ADExtraInfo]
[ChangeTask]
[ExtraInfo]
GracePeriod=6
NOTE: The GracePeriod value represents minutes and can be whatever you want. But pro tip – make the initial value low for testing, then change to a longer duration once rotation is functioning properly.
Modify the .xml file:
Replace <Optional /> with the following block:
<Optional>
<Property Name=”CurrInd" />
<Property Name="VirtualUserName" />
<Property Name="Index" />
<Property Name="DualAccountStatus" />
</Optional>

Create a zipfile containing the modified .ini and .xml file and import to your Vault.
Verify the new platform appears under Rotational Groups and the Grace Period value is displayed.
Click Edit and navigate to Target Account Platform->UI & Workflows->Properties->Optional  and verify the four properties you added are there.

# Step 2: “Configure the object’s platform for dual account support”
Export the the target platform to a local zipfile & unzip to create two files:
<base-platform-id>.ini
<base-platform-id>.xml
Modify the .ini file:
This is the metadata that governs the behavior for any account created for this platform type:
password change/verification/reconciliation parameters, drivers, etc. 
Modify the PlatformID & PolicyName to something indicative, e.g. MySQL-Dual
Modify the .xml file:
This is the metadata that (among other things) specifies the required and optional properties of an account.
Modify the PlatformID to match the one in the .ini file
Add the following properties. Making them optional allows using this platform for non-dual account purposes:
<Property Name="VirtualUserName" />
<Property Name="Index" />
<Property Name="DualAccountStatus" />

Create a zipfile containing the modified .ini and .xml file and import to your Vault.
Verify the new target platform appears in the appropriate category, e.g. Databases

# Step 3: “Configure accounts and groups for dual account support” 
Create two accounts that have the PlatformID of the target account platform created in step 2. 
The accounts must be in the same safe, and the safe must have a CPM assigned to it.
Using the classic UI, you must modify each account in a dual account pair.
Open one of the accounts in the PVWA classic UI:
Under the CPM tab, click “Create New” a specify a unique account group name for the pair of accounts with the Rotational Group as its platform.
Choose a VirtualUserName to represent this pair of accounts.
The VirtualUserName is effectively the Account Name of the pair of accounts.
It appears in Conjur variable names in place of either account name. It is used in CP queries to retrieve the currently active account properties.
Set Index property to: 1
Set DualAccountStatus property to: Active
Open the other account in the PVWA classic UI:
Under the CPM tab, click “Modify” and select the group name you created for the first account.
Set VirtualUserName to the same name as in the first account
Set Index property to: 2
Set DualAccountStatus property to: Inactive

# Step 4: Test Dual Account password rotation
In PVWA, click on one of the two accounts (doesn’t matter which one) and click “Change”
Click “Open” and the account will open with the classic UI.
Under Account Details, click “Change”, the click “Ok” to trigger immediate password change for the entire group.
Monitor the change process clicking Refresh until you see the DualAccountStatus change.
Start your timer and when the GracePeriod has elapsed, check to that the Inactive account’s password has changed in the account and target system.
Correct any errors and try again.
Typical errors are:
Incorrect or missing account properties: address, database, port, user
Port not open to the CPM’s IP address. To find that in Privilege Cloud, navigate to System Health->CPM and Accounts Discovery
Incorrect CPM driver for the target system.


