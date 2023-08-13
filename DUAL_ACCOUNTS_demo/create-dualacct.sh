# Set script variables
PVWAURL=""
AuthType="cyberark"
DisableSSLVerify=""
Interactive=""
NonInteractive=""
CsvPath=""
AccountPlatformID=""
GroupPlatformID=""
AccountSafeName=""
ScriptLocation="$(dirname "$0")"
ScriptVersion="1.1"
LOG_FILE_PATH="$ScriptLocation/DualAccounts.log"

# Set URLs
URL_PVWAAPI="$PVWAURL/api"
URL_Authentication="$URL_PVWAAPI/auth"
URL_Logon="$URL_Authentication/$AuthType/Logon"
URL_Logoff="$URL_Authentication/Logoff"
URL_Accounts="$URL_PVWAAPI/Accounts"
URL_AccountGroups="$URL_PVWAAPI/AccountGroups"
URL_AccountGroupMembers="$URL_PVWAAPI/AccountGroups/%s/Members"
URL_PlatformDetails="$URL_PVWAAPI/Platforms/%s"

main() {
  # Check if CSV file is provided
  if [ ! -z "$NonInteractive" ]; then
      if [ -z "$CsvPath" ]; then
          echo "CSV file path cannot be empty in non-interactive mode"
          exit 1
      fi
  
      # Read CSV and process accounts
      while IFS=, read -r UserName Address Password; do
          # Process the account
          # Call Add-DualAccount or equivalent function
          # ...
      done < "$CsvPath"
  else
      echo -n "Enter the application Virtual User Name: "
      read AppVirtualUserName
      echo -n "Enter the application Safe Name: "
      read AppSafeName
      echo -n "Enter the Dual Account Platform ID: "
      read AccountPlatformID
      echo -n "Enter the Rotational Group Platform ID: "
      read GroupPlatformID
  
      echo -n "Enter the first account's user name: "
      read```
}


# Function Collect-ExceptionMessage
# Function Test-CommandExists

# Function Disable-SSLVerification
Disable-SSLVerification() {
    # Disable SSL Verification (not recommended for security reasons)
    export CURL_CA_BUNDLE=""
    export NODE_TLS_REJECT_UNAUTHORIZED="0"
}

# Function Encode-URL($sText)

# Function Get-LogonHeader
# Function Run-Logoff

##############################
# Function Add-DualAccount
# Parameters.....: User Name, User password, PlatformID, Safe Name, VirtualUserName, Index
add_dual_account() {
  # test if account exists using name, address, safename
  # Test-Account -accountName $userName -accountAddress $address -safeName $safeName 
  if account-does-not-exist; then
    # create it
    $accName = ('{0}@{1}' -f $userName, $address)
    $objAccount.platformAccountProperties = New-Object PSObject
    $objAccount.secretManagement = "" | Select "automaticManagementEnabled"
    $objAccount.address = $address
    $objAccount.userName = $userName
    $objAccount.platformId = $platformID
    $objAccount.safeName = $safeName
    $objAccount.secretType = "password"
    $objAccount.secret = $userPassword
    $objAccount.secretManagement.automaticManagementEnabled = $true
    $objAccount.platformAccountProperties | Add-Member -NotePropertyName VirtualUserName -NotePropertyValue $virtualUserName
    $objAccount.platformAccountProperties | Add-Member -NotePropertyName Index -NotePropertyValue $index
    $dualAccountStatusValue = "Inactive"
    if ($index -eq 1) {
       $dualAccountStatusValue = "Active"
    }
    $objAccount.platformAccountProperties | Add-Member -NotePropertyName DualAccountStatus -NotePropertyValue $dualAccountStatusValue
    $addAccountResult = $(Invoke-Rest -Uri $URL_Accounts -Header $(Get-LogonHeader -Credentials $VaultCredentials) -Body $($objAccount | ConvertTo-Json -Depth 5) -Command "Post")
    return $addAccountResult.id
  else
    return accountId
  fi
}

# Function Get-RotationalGroupIDFromSafe
# Function Add-RotationalGroup
# Function Get-Account
# Function Test-Account

main "$@"
