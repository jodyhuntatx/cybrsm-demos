- in host shell window:
  - run: cd build; build_conjur.sh; cd ..
  - run: ./start.sh - will put you in jenkins master container bash prompt
- in jenkins-master shell window:
  - cd /demo
  - run: ./0_init.sh
  - copy Initial Jenkins admin password to clipboard
- point browser at localhost:8080 - will put you at Jenkins init page

In Jenkins dashboard:
  - Setup admin user and install plugins
    - paste initial password
    - create first admin user as admin, password: Cyberark1
    - install default plugins
  - Enable remote triggers w/o authentication (for demo purposes only!)
    - in left sidebar menu, click Manage Jenkins/Configure Global Security
    - under CSRF protection, uncheck "Prevent Cross Site Request Forgery exploits"
    - click save

Create Internal Summon demo job:
- in Jenkins Dashboard:
   - click New Item, name it 1_InternalSummonDemo, click Pipeline, then OK at bottom
   - under Build Triggers, click "Trigger builds remotely", set token value to xyz
   - in shell window, cat Jenkinsfile.intsummon and paste contents in pipeline window
   - click Save
   - in shell window, run: ./1_build-int-summon.sh 
   - script should return immediately, job should run successfully in Jenkins
   - can also run w/ Build Now from Jenkins dashboard

Create External Summon demo job:
- in Jenkins Dashboard:
   - click New Item, name it 2_ExternalSummonDemo, click Pipeline, then OK at bottom
   - under General, click "This project is parameterized"
   - add String parameter named DB_UNAME, no default value
   - add Password parameter named DB_PWD, no default value
   - under Build Triggers, click "Trigger builds remotely", set token value to xyz
   - cat Jenkinsfile.extsummon and paste contents in pipeline window
   - click Save
   - in shell window, run: ./2_build-ext-summon.sh
   - script should return after slight pause, job should run successfully in Jenkins
   - can also run w/ Build Now w/ Parameters, but have to enter parameter values manually

Create Conjur API demo job (optional, just serves as a negative example vs. using Summon):
  - Setup Conjur Host Factory token as Credential:
    - in shell window - copy HF_TOKEN value from output from init step
    - in Jenkins dashboard:
      - in left sidebar menu, click Credentials/System
      - in window table click Global credentials (unrestricted)
      - in left sidebar menu, click Add Credentials
      - for Kind, select "Secret text", for Secret paste the HF_TOKEN value, for ID use ConjurHFToken
      - click Save
  - Setup Conjur endpoint environment variables:
    - in Jenkins left sidebar menu, click Manage Jenkins/Configure System
    - under Global Properties, click Environment Variables, click Add
    - add CONJUR_APPLIANCE_URL and CONJUR_CERT_FILE vars, cut/paste values from 0_init.sh script output
    - click New Item, name it ConjurAPIDemo, click Pipeline, click OK at bottom
    - in Build Triggers click "Trigger builds remotely", set token value to xyz
    - in Pipeline script, cat Jenkinsfile.api, select, copy and paste contents in window
    - click Save
    - in shell window, run: ./3_build-int-api.sh
    - script should return immediately, job should run successfully in Jenkins
    - can also run w/ Build Now from Jenkins dashboard

