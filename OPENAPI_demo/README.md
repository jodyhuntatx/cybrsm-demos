# Ansible Tower & Conjur OSS Quickstart

Prerequisites:
 - jq
 - docker
 - docker-compose
 - Ansible Tower v3.5 or greater
   * see: https://docs.ansible.com/ansible-tower/3.5.0/html/administration/credential_plugins.html)

Steps:
1) Run the start-conjur script. This automates the Conjur OSS Quickstart steps.
   * see: https://www.conjur.org/get-started/quick-start/oss-environment/
2) Run setup-ansible-demo.sh. This loads a Conjur policy to create an identity with access to two secrets.
3) Use values in the output from setup script to create a Conjur credential retriever
   * see: https://docs.ansible.com/ansible-tower/3.5.0/html/administration/credential_plugins.html#cyberark-conjur-secret-lookup
4) Use the test button to verify the credential retriever can retrieve the aws-access-key and aws-secret-key values
5) Create an Amazon Web Services credential
   * see: https://docs.ansible.com/ansible-tower/3.5.0/html/userguide/credentials.html#amazon-web-services
6) Replace the Access Key value with the Conjur Credential Retriever configured to retrieve the aws-access-key value
7) Replace the Secret Key value with the Conjur Credential Retriever configured to retrieve the aws-secret-key value
8) Create a job template that uses the AWS credential and runs the following playbook:
```
---
- hosts: all
  gather_facts: False
  tasks:
    - debug:
        msg:
        - Access Key is {{ lookup('env', "AWS_ACCESS_KEY_ID") }}
        - Secret Key is {{ lookup('env', "AWS_SECRET_ACCESS_KEY") }}
```
9) Run the job and examine the output
10) Change the value of one or both variables using the conjur-variable script.
    e.g.:
```
	>> ./conjur-variable set aws-access-key a-new-value
```
11) Re-run the job and verify the output contains the new value.
12) Your Ansible job now uses dynamically retrieved credentials!
