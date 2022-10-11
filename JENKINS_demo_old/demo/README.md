# Demo Flow
## Abstract: 
The goal of the demo is to highlight how easy it is to use an external secrets service like CyberArk Conjur with Jenkins pipelines. By making dynamic secrets retrieval transparent to Jenkins workflows, compliance with security policies is more likely to happen. Secrets can be centrally secured, managed and rotated without impacting CI/CD workflows.
The demo shows three different ways to inject or pull secrets into Jenkins pipelines:
 - Summon is called from within the pipeline. The Conjur identity is the host node's machine identity.
 - Summon is called externally to retrieve secrets and bind them to parameters for a Jenkins build before triggering the job via the Jenkins REST API. The Conjur identity is dynamically created using the job name.
 - The Conjur REST API is called from scripts invoked within the Jenkins pipeline. The Conjur identity is dynamically created using the Node name and Executor number.

## Demo steps:
### Show how Summon works
  - run: cat secrets.yml
  - show 3 environments (dev/test/prod), DB_* vars will have different values based on env
  - only for prod will we pull secrets from Conjur (because of !var tag)
  - run: summon -e dev ./secrets_echo.sh, shows literal values
  - run: summon -e test ./secrets_echo.sh, shows literal values
  - run: summon -e prod ./secrets_echo.sh, shows values from Conjur
  - in Conjur UI, change secrets/db_username or db_password
  - run: summon -e prod ./secrets_echo.sh, shows updated values from Conjur

### Scenario 1: Jenkins pipeline calls Summon 
  - Basically the same thing as just demonstrated, just called from the pipeline
  - rotate a secret again and show the pipeline pulling the new value
  - discuss node identity, that identity needs access to all secrets for all build jobs
  - case of potential overprivilege, non-SoD
  - can remedy w/ multiple nodes w/ different identities/permissions
  - delegate jobs accordingly w/ Jenkins pipeline syntax (e.g. agent { label 'releaser-v2' })
  - another option is to use jobs as identities (segue to Scenario 2)

### Scenario 2: Summon triggers Jenkins job with parameters
  - by invoking Summon externally we have more control over the identity it uses
  - in this case, for prod we use a dynamically created host identity, the Job name is the login name
  - the script will use the HF token cached in a file to create the identity and return its API key
  - if the identity already exists, it just rotates the API key 
  - Summon uses the API key and Job name to authenticate, pull secrets and those values are bound into the Jenkins REST API call that triggers the job
  - show job run console output
  - show pipeline code, how clean it is, no reference to Conjur or Summon anywhere

### Scenario 3: Jenkins pipeline calls scripts that use Conjur REST API
  - this is an anti-pattern, why you don't want to use APIs for secrets retrieval in pipelines
  - cat Jenkinsfile.api and show how verbose it is
  - if you run it, show how the HF token Jenkins credential is redacted, but it's hard to suppress the AUTH_TOKEN value, source of secrets leakage
  - could perhaps be more elegant using groovy functions, but...what's the point given Summon?
