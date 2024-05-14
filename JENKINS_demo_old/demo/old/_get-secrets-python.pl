import conjur
import os
from conjur import config

login=os.environ['CONJUR_AUTHN_LOGIN']
api_key=os.environ['CONJUR_AUTHN_API_KEY']
api=conjur.new_from_key(login, api_key)

access_token = api.authenticate()

# Use the API to fetch the value of a variable
#var_uname=os.environ['VAR_UNAME']
#var_pname=os.environ['VAR_PNAME']
var_uname="secrets/db_username"
var_pname="secrets/db_password"

#os.system('clear')
print("\n\nHost name: %s" % login)
print("API key: %s" % api_key)
print("Var Uname: %s" % var_uname)
print("Var Pname: %s\n" % var_pname)

raw_input("Press Enter to continue...")

secret = api.variable(var_uname).value()
print("\nValue for %s is: %s" % (var_uname, secret))

secret = api.variable(var_pname).value()
print("Value for %s is: %s\n\n" % (var_pname, secret))
