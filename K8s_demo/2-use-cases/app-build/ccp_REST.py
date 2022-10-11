#!/usr/bin/python

import warnings, json, requests
warnings.filterwarnings("ignore")

CCP_HOST = "192.168.50.131"
APP_ID = "ANSIBLE"
SAFE = "CICD_Secrets"
OBJECT = "MySQL"

ccp_url = "https://" + CCP_HOST + "/AIMWebService/api/Accounts?AppID=" + APP_ID \
		+ "&Query=Safe=" + SAFE + ";Object=" + OBJECT

result = requests.get(ccp_url, verify=False).text
parsed = json.loads(result)
print(json.dumps(parsed, indent=4, sort_keys=True))
