#!/usr/bin/python

import os, base64, json, requests, subprocess
import urllib.parse

with open("conjur-cert.pem", "w") as text_file:
    text_file.write(os.environ['CONJUR_SSL_CERTIFICATE'])

with open(os.environ['CONJUR_AUTHN_TOKEN_FILE'], 'r') as file:
    authToken = file.read().rstrip()

token_b64 = base64.b64encode(authToken.encode('utf-8')).decode("utf-8")

#now we can retrieve secrets to our heart's content
conjur_url = "{conjur_appliance_url}/secrets/{account}/variable/".format(
                            conjur_appliance_url = os.environ['CONJUR_APPLIANCE_URL'],
                            account = os.environ['CONJUR_ACCOUNT']
                            )
dbHostname = requests.get(conjur_url + os.environ['DB_HOSTNAME_ID'],
			headers={'Authorization' : "Token token=\"" + token_b64 + "\""},
			verify='conjur-cert.pem').text
dbUname = requests.get(conjur_url + os.environ['DB_UNAME_ID'],
			headers={'Authorization' : "Token token=\"" + token_b64 + "\""},
			verify='conjur-cert.pem').text
dbPwd = requests.get(conjur_url + os.environ['DB_PWD_ID'],
			headers={'Authorization' : "Token token=\"" + token_b64 + "\""},
			verify='conjur-cert.pem').text

print()
print("The retrieved values are:")
print("  dbHostname: " + dbHostname)
print("  dbUname: " + dbUname)
print("  dbPwd: " + dbPwd)
print()

pwdArg = "--password=" + dbPwd
subprocess.run(["mysql", "-A", "-h", dbHostname, "-u", dbUname, pwdArg, "petclinic"])
