from tkinter import *
from tkinter import ttk
import json

import cybrhttp
import platformlist
from platformlist import PlatformListBox

baseUrl = 'https://comp_server/passwordvault/api/'

url= baseUrl + 'auth/Cyberark/Logon'
payload = {'username':'Administrator',
           'password':'Cyberark1',
           'concurrentSession':'true'}
payld = json.dumps(payload)

sessionToken = cybrhttp.HttpPost(url,payld,"")

#url = baseUrl + 'platforms?Active=True'
#url = baseUrl + 'platforms'
#platformList = cybrhttp.HttpGet(url,sessionToken)
#print(platformList)

#url = baseUrl + 'safes'
#safeList = cybrhttp.HttpGet(url,sessionToken)
#print(safeList)

#url = baseUrl + 'accounts?filter=safename eq CICD_Secrets'
#print(json.dumps(accountList, indent=2))
#accountList = cybrhttp.HttpGet(url,sessionToken)

with open("platforms.json") as file:
  platformList = json.load(file)

root = Tk()
root.title("Platforms")
root.columnconfigure(0, weight=1)
root.rowconfigure(0, weight=1)
plb = PlatformListBox(root, platformList)
root.mainloop()
