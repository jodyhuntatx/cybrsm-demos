# CredHub-Venafi

Commonly manage certificates in both Venafi and CredHub.

[![New Context](https://img.shields.io/badge/awesome-for%20hire-orange?style=for-the-badge)](http://www.newcontext.com)

CredHub-Venafi is a CLI tool (`cv`) that helps manage certificates located in Venafi TPP and Pivotal Cloud Foundry CredHub.

### Commands
* login
* create
* list
* delete

### `cv login`
* Logs into CredHub only.
* TPP authentication happens with each command.

### CredHub uses Cloud Foundry UAA

CV logs in the User Account and Authentication (UAA) Server by first contacting the CredHub Server. It retrieves the UAA path. Then, it contacts the UAA server with the credentials to get an access token.  That token is subsequently used to access the CredHub server.

### Config File
The config file is read from the  `.cv.conf` in the $HOME directory.

### Venafi Cloud
```
apikey: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
zone: zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz
connector_type: cloud
credhub_username: credhub
credhub_password: topsecret
credhub_endpoint: https://127.0.0.1:9000
skip_tls_validation: true
log_level: status
```
### Venafi Platform
```
vcert_username: tppadmin
vcert_password: topsecret
vcert_zone: \Certificates
vcert_base_url: https://yourvenafiinstall.com/vedsdk/
vcert_access_token: WkDQ/zJsFOXzLEWQQ51mlw== (optional)
connector_type: tpp
credhub_username: credhub
credhub_password: topsecret
credhub_endpoint: https://127.0.0.1:9000
skip_tls_validation: true
log_level: status
```

##### Direct Access Token Support
```
vcert_access_token: WkDQ/zJsFOXzLEWQQ51mlw== (bearer access token)
vcert_zone: \Certificates
vcert_base_url: https://yourvenafiinstall.com/vedsdk/
connector_type: tpp
credhub_username: credhub
credhub_password: topsecret
credhub_endpoint: https://127.0.0.1:9000
skip_tls_validation: true
log_level: status
```
##### Legacy APIKey Support

```
vcert_username: tppadmin
vcert_password: topsecret
vcert_legacy_auth: true
vcert_zone: \Certificates
vcert_base_url: https://yourvenafiinstall.com/vedsdk/
connector_type: tpp
credhub_username: credhub
credhub_password: topsecret
credhub_endpoint: https://127.0.0.1:9000
skip_tls_validation: true
log_level: status
```

```
Where:
vcert_username/vcert_password: will be credentials of the user to log into Venafi TPP
vcert_legacy_auth: if true then API-key authentication will be used (pre TPP v19.2)
vcert_zone: policy path in Venafi TPP to store certificates, this path MUST pre-created
vcert_base_url: the URL to Venafi TPP
vcert_access_token: bearer token obtained from Venafi TPP, used for token-based authentication in v19.2+ (optional)
connector_type: Venafi tpp or cloud
vault_token: access token to be used for Vault
vault_base_url: the URL to the Vault instance
vault_kv_path: the path in Vault where the key-value pair Venafi certificates are stored
vault_pki_path: the path in Vault where the Vault certificates are stored
vault_role: the role to use in Vault when creating certificates
Log_level: STATUS, VERBOSE, INFO or ERROR
skip_tls_validation: true (when using self-signed certificates)
```

**NOTE**: The vcert_access_token is optional as the Vault-Venafi tool will obtain a token on the fly for the username if one is not specified.

Previous to Venafi Trust Protection Platform (TPP) v19.2 all authentication was handled via username/password with an API-Key. With TPP v19.2 token-based authentication was introduced and Venafi plans to deprecate the API-Key authentication method at the end of 2020. TPP v20.4 will be the last release that supports API-Key authentication.

### CredHub Login Example

```
./cv login \
-url "https://127.0.0.1:9000" \
-u "credhub" \
-p "password" \
-skip-tls-validation
```

### After CredHub Login
After logging in to CredHub there will be a file at `$HOME/.cv/json.config` that contains the token and CredHub login settings.

```
{
  "access_token": "eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vMzUuMTk2LjMyLjY0Ojg0NDMvdG9rZW5fa2V5cyIsImtpZCI6ImxlZ2FjeS10b2tlbi1rZXkiLCJ0eXAiOiJKV1QifQ.eyJqdGkiOiI5MGVjNDI5NmNiN2U0ZGEyYWQxYmVkNzkyMzg3MjdlNiIsInN1YiI6IjY2ZTA4N2FhLWI2ZTItNGU5OC1iNjk5LWEwYzE3ZjE3NWIyNyIsInNjb3BlIjpbImNyZWRodWIud3JpdGUiLCJjcmVkaHViLnJlYWQiXSwiY2xpZW50X2lkIjoiY3JlZGh1Yl9jbGkiLCJjaWQiOiJjcmVkaHViX2NsaSIsImF6cCI6ImNyZWRodWJfY2xpIiwicmV2b2NhYmxlIjp0cnVlLCJncmFudF90eXBlIjoicGFzc3dvcmQiLCJ1c2VyX2lkIjoiNjZlMDg3YWEtYjZlMi00ZTk4LWI2OTktYTBjMTdmMTc1YjI3Iiwib3JpZ2luIjoidWFhIiwidXNlcl9uYW1lIjoiY3JlZGh1YiIsImVtYWlsIjoiY3JlZGh1YiIsImF1dGhfdGltZSI6MTU3NzExNTgwNywicmV2X3NpZyI6IjVkZWRmNjhkIiwiaWF0IjoxNTc3MTE1ODA3LCJleHAiOjE1NzcyMDIyMDcsImlzcyI6Imh0dHBzOi8vMzUuMTk2LjMyLjY0Ojg0NDMvb2F1dGgvdG9rZW4iLCJ6aWQiOiJ1YWEiLCJhdWQiOlsiY3JlZGh1Yl9jbGkiLCJjcmVkaHViIl19.n_-b1kJiCRNB_4VHNQJg3kBRMDsorI5eaB8r8E-1U9K04Yszuz5Qu4BkLO4v-fNtXpQzY4KjxMRW9pvIi0RVjEOleFmSQyEW1PgJFOtYIlLS2l75oWT-_-Gvbj3mDnyx_qOJqqCbe1c2y9M-xxSbRLU4VgrqGFnSFMxPnUXjVWHPs6XMvZBLkKWZ4YyLSVoMIA98h9NgHsRzo5tBrX4xX5YZ3z1xJsJTh-ZgPgpDao38NUKYpHUlscPOcC9-FlO7J8v-QCVav3lu_H9SdWC_b7Oi-SFpDO6InUBQDUR9z2XTcsICQ1KPUgAm3LQJgeNyE2OLO-Y1JCsaPk4aXn01Kw",
  "refresh_token": "eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vMzUuMTk2LjMyLjY0Ojg0NDMvdG9rZW5fa2V5cyIsImtpZCI6ImxlZ2FjeS10b2tlbi1rZXkiLCJ0eXAiOiJKV1QifQ.eyJqdGkiOiJkZjFmYTIwNTMzMjY0Mzk4OGRlZTk1MzM0NGUyMGQ2OS1yIiwic3ViIjoiNjZlMDg3YWEtYjZlMi00ZTk4LWI2OTktYTBjMTdmMTc1YjI3IiwiaWF0IjoxNTc3MTE1ODA3LCJleHAiOjE1NzcyODg2MDcsImNpZCI6ImNyZWRodWJfY2xpIiwiY2xpZW50X2lkIjoiY3JlZGh1Yl9jbGkiLCJpc3MiOiJodHRwczovLzM1LjE5Ni4zMi42NDo4NDQzL29hdXRoL3Rva2VuIiwiemlkIjoidWFhIiwiYXVkIjpbImNyZWRodWJfY2xpIiwiY3JlZGh1YiJdLCJncmFudGVkX3Njb3BlcyI6WyJjcmVkaHViLndyaXRlIiwiY3JlZGh1Yi5yZWFkIl0sImFtciI6WyJwd2QiXSwiYXV0aF90aW1lIjoxNTc3MTE1ODA3LCJncmFudF90eXBlIjoicGFzc3dvcmQiLCJ1c2VyX25hbWUiOiJjcmVkaHViIiwib3JpZ2luIjoidWFhIiwidXNlcl9pZCI6IjY2ZTA4N2FhLWI2ZTItNGU5OC1iNjk5LWEwYzE3ZjE3NWIyNyIsInJldm9jYWJsZSI6dHJ1ZSwicmV2X3NpZyI6IjVkZWRmNjhkIn0.diepSbpVg2tTLxNK9AOLFwRokH1X86UcWpj5fpYSUCvelU8nJzK-iEH_YYDVc1vGcp5rw5R2UMHBglgTT5ivGNCsWOzTov5ed2okWKGGhgyc6LsiCEjipisFmtQP5lYCA65Ka-EpphpkA6leI5OW8XjAGfuWwTiI2_r2irYMf7MTXgzBFH-pgSsi34uhXw-uZ-ZEGgSmA5PKwcLn3RWC3VHzWdNlLycOMH9l2JkG-HC6xSizeYRhEaj-7xCOfFYmO3-LKAcboL1kMYg8UuJpnksaep3JmhcE2NbBYFYP5ErBm8UeaKcNokVb9AIYCpvsULIEMGr9WMmCcJtdoHuegw",
  "credhub_url": "https://127.0.0.1:9000",
  "auth_url": "https://35.35.35.35:8443",
  "skip_tls_validation": true
}
```

### `cv create` example
Create a certificate on the Venafi side and upload to CredHub

```
./cv create -cn "atestcert3" -name "mycertfromvenafi26"
```

### CV create example
Create a certificate on the Credhub and upload to Venafi

```
./cv create \
    -credhub \
    -name mycredname28 \
    -cn mycredname28 \
    -key-usage data_encipherment \
    -ext-key-usage client_auth \
    -ca "/aname"
```

Uses -credhub flag.

**Note:** The above command requires the certifate authority to preexist. For simple testing purposes you can replace the -ca option with the -self-sign option.

```
./cv create -credhub -name mycredname29 -cn mycredname29 -key-usage data_encipherment -self-sign
```

### CV Create Help Usage</h2>
Adding the `-h` flag to command reveals the help associated with that command.

i.e.
```
Usage of cv:
  -bycommonname
        Compare by certificate common name from Venafi and file basename on the CredHub side.
  -bypath
        Compare by path
  -bythumbprint
        Compare by thumbprint. Note this will be slower due to the need to download each cert from CredHub.
  -cprefix string
        Credhub prefix to strip from returned values
  -croot string
        Subpath to search in CredHub
  -vlimit int
        (Default 100) Limits the number of Venafi results returned (default 100)
  -vprefix string
        Venafi prefix to strip from returned values
  -vroot string
        Subpath to search in Venafi
```


### Policy folder
The policy folder is configured with the `vcert_zone` key.
`vcert_zone: \Certificates`

### `cv list` examples
Compare by thumbprint

```
cv list -bythumbprint \
     -vroot "\\VED\\Policy\\Certificates\\Division 3\\"
```

Compare by CommonName

```
cv list -bycommonname \
  -vroot "\\VED\\Policy\\Certificates\\Division 3\\"</pre>
```

Compare by path

```
cv list -bypath \
  -vroot "\\VED\\Policy\\Certificates\\Division 3\\"</pre>
```


### CV List
Compare by thumbprint

```
cv list -bythumbprint \
  -vroot "\\VED\\Policy\\Certificates\\Division 3\\"</pre>
```

This mode takes the provided thumbprint on the Venafi side and on the CredHub side it lists and then pulls and computes the thumbprint for each credential because CredHub does not provide the thumbprint.

### CV List
Compare by CommonName

```
cv list -bycommonname \
  -vroot "\\VED\\Policy\\Certificates\\Division 3\\"</pre>
```

Compares CommonName from the Venafi side with basename on the CredHub side. (i.e the last segment of path "/credhubpath/thebasename")

### CV List
Compare by path basename

Compares path from Venafi side with path from the CredHub side. There are command line options for removing portions of the prefix on each side.

### CV Delete
Deletes a certificate on both systems by first looking it up from the CredHub side by name, calculating the thumbprint and deleting from the Venafi side.

# Powered by New Context

[![New Context Logo](https://newcontext.com/wp-content/uploads/2018/02/New-Context-logo2.png)](http://www.newcontext.com)

CredHub-Venafi is maintained and funded by New Context, which provides "security first" automation to mission critical infrastructure.
We were doing DevSecOps before it became a buzzword, you can [hire us](https://newcontext.com/contact-us/) to
improve your time-to-market, reduce risk, and boost your security/compliance posture.
