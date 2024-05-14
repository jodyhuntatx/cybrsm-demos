#!/usr/bin/python3

import json, requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

CCP_HOST = "192.168.50.131"
APP_ID = "ANSIBLE"
SAFE = "CICD_Secrets"
OBJECT = "MySQL"

ccp_url = "https://" + CCP_HOST					\
	+ "/AIMWebService/api/Accounts?AppID="	+ APP_ID	\
	+ "&Query=Safe=" + SAFE + ";Object=" + OBJECT

response = requests.get(ccp_url, verify=False)

print()
print("The retrieved values are:")
print(json.dumps(response.json(), indent=2, sort_keys=True))
