import requests
import warnings
import contextlib
import json
import logging
from urllib3.exceptions import InsecureRequestWarning

old_merge_environment_settings = requests.Session.merge_environment_settings

@contextlib.contextmanager
def no_ssl_verification():
    opened_adapters = set()

    def merge_environment_settings(self, url, proxies, stream, verify, cert):
        # Verification happens only once per connection so we need to close
        # all the opened adapters once we're done. Otherwise, the effects of
        # verify=False persist beyond the end of this context manager.
        opened_adapters.add(self.get_adapter(url))

        settings = old_merge_environment_settings(self, url, proxies, stream, verify, cert)
        settings['verify'] = False

        return settings

    requests.Session.merge_environment_settings = merge_environment_settings

    try:
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', InsecureRequestWarning)
            yield
    finally:
        requests.Session.merge_environment_settings = old_merge_environment_settings

        for adapter in opened_adapters:
            try:
                adapter.close()
            except:
                pass

############################3
def HttpGet(url,authHeader):
#  logging.basicConfig(level=logging.DEBUG) 

  head = {'Content-type':'application/json','Accept':'application/json','Authorization': authHeader}
  parms = {'Accept':'application/json','Authorization': authHeader}
  with no_ssl_verification():
    response = requests.get(url,headers=head)
  if response.status_code != 200:
    raise Exception("Error: HTTP GET returned " + str(response.status_code) )
  return response.json()


############################3
def HttpPost(url,bodyContent,authHeader):
#  logging.basicConfig(level=logging.DEBUG) 

  head = {'Content-type':'application/json','Accept':'application/json','Authorization':authHeader}
  with no_ssl_verification():
    response = requests.post(url,headers=head,data=bodyContent)
  if response.status_code != 200:
    raise Exception("Error: HTTP POST returned " + str(response.status_code) )
  return response.json()
