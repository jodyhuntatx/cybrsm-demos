# End-to-End Provisioning/Deprovisioning Flows
# for CyberArk Privilege Cloud and Conjur Cloud

##End2End-Provision Flow:
Example flow that provisions a Safe, an SSH Account, a Vault AppID and Conjur workload with access to the Safe's accounts.
Key parameters are passed in to the webhook entrypoint.

Provisioning flow detail:
- base64 decodes SSH key passed to webhook
- calls GetAuthnTokens-SaaS to get Vault and Conjur access tokens
- Creates Safe
- Adds Conjur Sync user as member of Safe
- Creates AppID user
- Adds AppID user as member of Safe
- Adds SSH key account to Safe
- creates Conjur workload identity w/ API authn - same name as AppID
- loads delegation/consumers policy for Safe (avoids waiting for sync)
- grants delegation/consumers Role to workload identity
- sends confirmation email

##End2End-Deprovision Flow:
Example flow that performs the inverse of the End2End provisioning flow.
Webhook parameters are same as for the Provisioning workflow.

Deprovisioning flow detail:
- <SSH key account values ignored>
- calls GetAuthnTokens-SaaS to get Vault and Conjur access tokens
- deletes Conjur delegation/consumers policy and admin group
   for Safe (which also deletes all synced secrets)
- deletes Conjur host identity
- deletes AppID user
- deletes Safe
- sends confirmation email
