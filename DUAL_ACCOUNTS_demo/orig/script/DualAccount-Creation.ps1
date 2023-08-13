# =================================================================================================================================
# Name..............: Dual Account Creation
# Comment...........: This script will create Dual Account using REST API
# Supported Versions: CyberArk Vault and PVWA v12.1 and CP v12.0 and above
# Requires..........: This script requires PowerShell version 3 or above
# =================================================================================================================================

param
(
    [Parameter()]
    [string]$PASUserName,
    [Parameter()]
    [string]$PASPassword,
    [Parameter()]
    [string]$AccountList,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$AuthenticationType = "cyberark",
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigFileFullPath = $( Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Policy-DualAccount-Creation.json" ),
    [parameter()]
    [string]$TenantName
)

# Global Parameters
# --------------------------------------------------------------------------------------------------------------------------------
$global:ScriptVersion = "1.0"
$global:ScriptLocation = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:ParamsObj = @{ }
$global:DefaultParamsObj =
@{
    LogFileFullPath = Join-Path ($ScriptLocation) "Logs-DualAccount.log";
    AccountDelimiter = "@";
    ListDelimiter = ";";
    GracePeriod = 6;
    AuthenticationType = "cyberark";
    LogDebugLevel = $false;
    LogVerboseLevel = $false;
    DisableSSLVerify = $false
}
$global:AccountListObj = [System.Collections.ArrayList]@{ }
$global:LogonHeader = $null
$global:IdentityFQDN = $null

# Global URLS
# --------------------------------------------------------------------------------------------------------------------------------
$global:URL_PVWAAPI = $null
$global:URL_Authentication = $null
$global:URL_Logon = $null
$global:URL_Logoff = $null

# Global URL Methods
# --------------------------------------------------------------------------------------------------------------------------------
$global:URL_PlatformDetails = $null
$global:URL_ImportPlatforms = $null
$global:URL_ExportPlatforms = $null
$global:URL_GetGroupPlatforms = $null
$global:URL_GetRotationalGroupPlatforms = $null
$global:URL_DeleteGroupPlatforms = $null
$global:URL_DeleteRotationalGroupPlatforms = $null
$global:URL_Accounts = $null
$global:URL_AccountsDetails = $null
$global:URL_AccountGroups = $null
$global:URL_AccountGroupMembers = $null

#region Writer Functions
# @FUNCTION@ ======================================================================================================================
# Name...........: Write-LogMessage
# Description....: Writes the message to log and screen
# Parameters.....: LogFile, MSG, (Switch)Header, (Switch)SubHeader, (Switch)Footer, Type
# Return Values..: None
# =================================================================================================================================
function Write-LogMessage
{
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$MSG,
        [Parameter(Mandatory = $false)]
        [Switch]$Header,
        [Parameter(Mandatory = $false)]
        [Switch]$SubHeader,
        [Parameter(Mandatory = $false)]
        [Switch]$Footer,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug", "Verbose")]
        [String]$type = "Info"
    )

    if (( This-ContainsKeyInParamsObj -name "LogFileFullPath") -and ( !(This-ParameterEmptyOrWhiteSpace -value $global:ParamsObj.LogFileFullPath)))
    {
        $LogFile = $global:ParamsObj.LogFileFullPath
    }
    else
    {
        $LogFile = $global:DefaultParamsObj.LogFileFullPath
    }

    $InDebug = $global:ParamsObj.LogDebugLevel
    $InVerbose = $global:ParamsObj.LogVerboseLevel

    try
    {
        if ($Header)
        {
            "=========================================================================================" | Out-File -Append -FilePath $LogFile
            Write-Host "========================================================================================="
        }
        elseif ( $SubHeader )
        {
            "-----------------------------------------------------------------------------------------" | Out-File -Append -FilePath $LogFile
            Write-Host "-----------------------------------------------------------------------------------------"
        }

        $msgToWrite = "[$( Get-Date -Format "yyyy-MM-dd hh:mm:ss" )]`t"
        $writeToFile = $true
        # Replace empty message with 'N/A'
        if ( [string]::IsNullOrEmpty($Msg))
        {
            $Msg = "N/A"
        }
        # Mask Passwords
        if ($Msg -match '((?:"password"|"secret"|"NewCredentials")\s{0,}["\:=]{1,}\s{0,}["]{0,})(?=([\w!@#$%^&*()-\\\/]+))')
        {
            $Msg = $Msg.Replace($Matches[2], "****")
        }
        # Check the message type
        switch ($type)
        {
            "Info"
            {
                Write-Host $MSG.ToString()
                $msgToWrite += "[INFO]`t$Msg"
            }
            "Warning"
            {
                Write-Host $MSG.ToString() -ForegroundColor DarkYellow
                $msgToWrite += "[WARNING]`t$Msg"
            }
            "Error"
            {
                Write-Host $MSG.ToString() -ForegroundColor Red
                $msgToWrite += "[ERROR]`t$Msg"
            }
            "Debug"
            {
                if ($InDebug)
                {
                    Write-Debug $MSG
                    $msgToWrite += "[DEBUG]`t$Msg"
                }
                else
                {
                    $writeToFile = $False
                }
            }
            "Verbose"
            {
                if ($InVerbose)
                {
                    Write-Verbose $MSG
                    $msgToWrite += "[VERBOSE]`t$Msg"
                }
                else
                {
                    $writeToFile = $False
                }
            }
        }

        if ($writeToFile)
        {
            $msgToWrite | Out-File -Append -FilePath $LogFile
        }
        if ($Footer)
        {
            "=========================================================================================" | Out-File -Append -FilePath $LogFile
            Write-Host "========================================================================================="
        }
    }
    catch
    {
        Write-Error "Error in writing log: $( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Collect-ExceptionMessage
# Description....: Formats exception messages
# Parameters.....: Exception
# Return Values..: Formatted String of Exception messages
# =================================================================================================================================
function Collect-ExceptionMessage
{
    param ([Exception]$e)

    begin
    {
    }
    process
    {
        $msg = "Source:{0} Message: {1}" -f $e.Source, $e.Message
        while ($e.InnerException)
        {
            $e = $e.InnerException
            $msg += "`n`t->Source:{0}; Message: {1}" -f $e.Source, $e.Message
        }
        return $msg
    }
    end
    {
    }
}
#endregion

#region Params objects Helper Functions
# @FUNCTION@ ======================================================================================================================
# Name...........: This-ContainsKeyInParamsObj
# Description....: 
# Parameters.....: name
# Return Values..: Boolean
# =================================================================================================================================
function This-ContainsKeyInParamsObj
{
    param ([string]$name)

    return ( $global:ParamsObj.ContainsKey($name))
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-ValueInParamsObj
# Description....: Set value in ParamsObj item
# Parameters.....: name,value,override
# Return Values..: None
# =================================================================================================================================
function Set-ValueInParamsObj
{
    param ([string]$name, $value, [boolean]$override = $true)

    if (This-ContainsKeyInParamsObj -name $name)
    {
        if ($override)
        {
            $global:ParamsObj[$name] = $value
        }
    }
    else
    {
        $global:ParamsObj.Add($name, $value)
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-DefaultValueInParamsObj
# Description....: Set default value in ParamsObj item
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Set-DefaultValueInParamsObj
{
    foreach ($item in $global:DefaultParamsObj.GetEnumerator())
    {
        Set-ValueInParamsObj -name $item.Name -value $item.Value -override $false
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-ValueFromParamsObj
# Description....: Get item value
# Parameters.....: name
# Return Values..: value
# =================================================================================================================================
function Get-ValueFromParamsObj
{
    param ([string]$name)

    $value = $null
    if (This-ContainsKeyInParamsObj -name $name)
    {
        $value = $global:ParamsObj.Get_Item($name)
    }

    return $value
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Verify-MandatoryParam
# Description....: Verify the parameter is not empty
# Parameters.....: name
# Return Values..: None
# =================================================================================================================================
function Verify-EmptyOrWhiteSpaceParam
{
    param ([string]$name)

    $value = Get-ValueFromParamsObj -name $name

    if (This-ParameterEmptyOrWhiteSpace -value $value)
    {
        throw "The parameter: $name can not be empty"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Verify-PVWAURLParam
# Description....: Verify PVWAURL param is ok
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Verify-PVWAURLParam
{
    $name = "PVWAURL"
    $value = Get-ValueFromParamsObj -name $name

    if ($value.Substring($value.Length - 1) -eq "/")
    {
        Set-ValueInParamsObj -name $name -value $value.Substring(0, $value.Length - 1)
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Verify-AuthenticationType
# Description....: Verify authentication type
# Parameters.....: AuthType
# Return Values..: None
# =================================================================================================================================
function Verify-AuthenticationType
{
    $name = "AuthenticationType"
    $value = Get-ValueFromParamsObj -name $name

    if (( $value -ne "cyberark") -and ( $value -ne "ldap") -and ( $value -ne "radius"))
    {
        throw "The authentication type: $( $value ) is not one of cyberark, ldap and radius"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Verify-GracePeriodParam
# Description....: Verify grace period is a valid parameter
# Parameters.....: 
# Return Values..: None
# =================================================================================================================================
function Verify-GracePeriodParam
{
    $name = "GracePeriod"
    $value = $null

    if (This-ContainsKeyInParamsObj -name $name)
    {
        $value = $global:ParamsObj.Get_Item($name)

        if (!( This-Numeric -value $value) -or ( This-ParameterEmptyOrWhiteSpace -value $value) -or ( 0 -eq $value))
        {
            Write-LogMessage -Type Warning -Msg "The value of Grace Period parameter is not valid, the parameter will get the default value 6"
            $global:ParamsObj.GracePeriod = $global:DefaultParamsObj.GracePeriod
        }
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Verify-LogFilePathParam
# Description....: Verify log file full path parameter is not empty
# Parameters.....: 
# Return Values..: None
# =================================================================================================================================
function Verify-LogFilePathParam
{
    $name = "LogFileFullPath"
    $value = $null

    if (This-ContainsKeyInParamsObj -name $name)
    {
        $value = $global:ParamsObj.Get_Item($name)

        if (This-ParameterEmptyOrWhiteSpace -value $value)
        {
            $global:ParamsObj.LogFileFullPath = $global:DefaultParamsObj.LogFileFullPath
        }
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Verify-GroupNameParam
# Description....: Verify group name parameter
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Verify-GroupNameParam
{
    $safeName = $global:ParamsObj.SafeName
    $groupName = $global:ParamsObj.GroupName

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $groupResult = $( Get-Group -groupName $groupName -safeName $safeName -VaultCredentials $creds -ErrAction "SilentlyContinue" )
        if (!( ( $null -eq $groupResult) -or ( $groupResult.count -eq 0)))
        {
            # Group Exists
            throw "There is already a group ['$groupName'] with the same name in the safe ['$safeName']"
        }
    }
    catch
    {
        throw "$( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Verify-VirtualUserNameParam
# Description....: Verify virtual user name parameter
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Verify-VirtualUserNameParam
{
    $safeName = $global:ParamsObj.SafeName
    $virtualUserName = $global:ParamsObj.VirtualUserName

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $virtualUserNameResult = $( Get-VirtualUserName -virtualUserName $virtualUserName -safeName $safeName -VaultCredentials $creds -ErrAction "SilentlyContinue" )
        if (!( ( $null -eq $virtualUserNameResult) -or ( $virtualUserNameResult.count -eq 0)))
        {
            # Group Exists
            throw "There is already a virtual user name ['$virtualUserName'] with the same name in the safe ['$safeName']"
        }
    }
    catch
    {
        throw "$( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-ValuesInAccountListObj
# Description....: Set accounts values in AccountListObj item
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Set-ValuesInAccountListObj
{
    $accountArray = $AccountList -Split $global:ParamsObj.ListDelimiter

    if ($accountArray.length -lt 2)
    {
        throw "The number of accounts can not be less than two"
    }

    for ($i = 0; $i -lt $accountArray.length; $i++)
    {
        $userName, $address, $password = $accountArray[$i] -Split $global:ParamsObj.AccountDelimiter

        if (This-ParameterEmptyOrWhiteSpace -value $userName)
        {
            throw "The account's username parameter cannot be empty"
        }

        if (This-ParameterEmptyOrWhiteSpace -value $address)
        {
            throw "The account's address parameter cannot be empty"
        }

        if (This-ParameterEmptyOrWhiteSpace -value $password)
        {
            throw "The account's password parameter cannot be empty"
        }

        if (Test-Path -Path $password)
        {
            $password = Get-Content -Raw -Path $password | %{ $_ -replace [RegEx]::Escape("\"), "\\" }
        }

        $dualAccountStatusValue = "Inactive"
        if ($( $i + 1 ) -eq 1)
        {
            $dualAccountStatusValue = "Active"
        }

        $accountObj =
        @{
            address = $address;
            userName = $userName;
            platformId = $global:ParamsObj.PlatformID + "-DualAccount";
            groupPlatformId = "RotationalGroup";
            safeName = $global:ParamsObj.SafeName;
            secretType = "password";
            secret = $( ConvertTo-SecureString -String $password -AsPlainText -Force );
            platformAccountProperties =
            @{
                VirtualUserName = $global:ParamsObj.VirtualUserName;
                Index = $( $i + 1 );
                DualAccountStatus = $dualAccountStatusValue;
            }
            secretManagement =
            @{
                automaticManagementEnabled = $true;
            }
        }

        $index = $global:AccountListObj.Add($accountObj)
    }
}
#endregion

#region Helper Functions
# @FUNCTION@ ======================================================================================================================
# Name...........: This-ParameterEmptyOrWhiteSpace
# Description....: Check if parameter is empty or white space
# Parameters.....: value
# Return Values..: Boolean values
# =================================================================================================================================
function This-ParameterEmptyOrWhiteSpace
{
    param ($value)

    return(([string]::IsNullOrEmpty($value) -or [string]::IsNullOrWhiteSpace($value)))
}

# @FUNCTION@ ======================================================================================================================
# Name...........: This-Numeric
# Description....: Check if parameter is numeric
# Parameters.....: value
# Return Values..: Boolean values
# =================================================================================================================================
function This-Numeric
{
    param ($value)

    return($value -match "^\d+$")
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Test-CommandExists
# Description....: Tests if a command exists
# Parameters.....: Command
# Return Values..: True / False
# =================================================================================================================================
function Test-CommandExists
{
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try
    {
        if (Get-Command $command)
        {
            return $true
        }
    }
    catch
    {
        return $false
    }
    finally
    {
        $ErrorActionPreference = $oldPreference
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-ZipContent
# Description....:
# Parameters.....: 
# Return Values..: 
# =================================================================================================================================
function Get-ZipContent
{
    param ([string]$zipPath)

    $zipContent = $null
    try
    {
        if (Test-Path $zipPath.Trim())
        {
            $zipContent = [System.IO.File]::ReadAllBytes($( Resolve-Path $zipPath.Trim() ))
        }
        else
        {
            throw "Could not find Platform ZIP in '$zipPath'"
        }

    }
    catch
    {
        throw "An error occurred while reading ZIP file: $( $_.Exception.Message )"
    }

    return $zipContent
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Extract-ZipToTempDirectory
# Description....: Extract Zip package to folder
# Parameters.....: zipPath
# Return Values..: folderPath
# =================================================================================================================================
function Extract-ZipToDirectory
{
    Param ([string]$zipPath)

    try
    {
        if (Test-Path -Path $zipPath)
        {
            $Package = Get-Item -Path $zipPath
            $zipFullPath = $Package.FullName

            # Load ZIP methods
            Add-Type -AssemblyName System.IO.Compression.FileSystem

            # Extract ZIP to temp folder
            Write-LogMessage -Type Debug -Msg "Extracting ZIP file '$zipPath'"
            $tempFolder = Join-Path -Path $Package.Directory -ChildPath $Package.BaseName
            if (Test-Path $tempFolder)
            {
                Remove-Item -Recurse $tempFolder
            }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($Package.FullName, $tempFolder)
        }
        else
        {
            throw "Could not find Platform ZIP in '$zipPath'"
        }
    }
    catch
    {
        throw "An error occurred while reading ZIP file: $( $_.Exception.Message )"
    }

    return $tempFolder
}
#endregion

#region REST API Functions
# @FUNCTION@ ======================================================================================================================
# Name...........: Disable-SSLVerification
# Description....: Disables the SSL Verification (bypass self signed SSL certificates)
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Disable-SSLVerification
{
    # Using Proxy Default credentials if the Server needs Proxy credentials
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    # Using TLS 1.2 as security protocol verification
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    # Disable SSL Verification
    if (-not("DisableCertValidationCallback" -as [type]))
    {
        add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public static class DisableCertValidationCallback {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }
    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(DisableCertValidationCallback.ReturnTrue);
    }
}
"@
    }

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [DisableCertValidationCallback]::GetDelegate()
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Encode-URL
# Description....: HTTP Encode test in URL
# Parameters.....: Text to encode
# Return Values..: Encoded HTML URL text
# =================================================================================================================================
function Encode-URL
{
    param ($sText)

    if ($sText.Trim() -ne "")
    {
        return [System.Web.HttpUtility]::UrlEncode($sText)
    }
    else
    {
        return $sText
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Invoke-Rest
# Description....: Invoke REST Method
# Parameters.....: Command method, URI, Header, Body
# Return Values..: REST response
# =================================================================================================================================
function Invoke-Rest
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "DELETE", "PATCH")]
        [String]$Command,
        [Parameter(Mandatory = $true)]
        [String]$URI,
        [Parameter(Mandatory = $false)]
        $Header,
        [Parameter(Mandatory = $false)]
        [String]$Body,
        [Parameter(Mandatory = $false)]
        [String]$OutFile,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Ignore", "Inquire", "SilentlyContinue", "Stop", "Suspend")]
        [String]$ErrAction = "Continue"
    )

    if (( Test-CommandExists Invoke-RestMethod) -eq $false)
    {
        throw "This script requires PowerShell version 3 or above"
    }
    $restResponse = ""
    try
    {
        $cmd = @{ Uri = $URI; Method = $Command; Header = $Header; ContentType = "application/json"; TimeoutSec = 36000 }
        if (![string]::IsNullOrEmpty($Body))
        {
            $cmd.Add("Body", $Body)
        }
        if (![string]::IsNullOrEmpty($OutFile))
        {
            $cmd.Add("OutFile", $OutFile)
        }
        Write-LogMessage -Type Verbose -Msg "Executing REST API: $( $cmd -join '-' )"
        $restResponse = Invoke-RestMethod @cmd -Debug:$global:ParamsObj.LogDebugLevel -Verbose:$global:ParamsObj.LogVerboseLevel
    }
    catch [System.Net.WebException]
    {
        # ErrorCode: 409, Failed to import target account platform because a platform with the same name already exist       
        if ($_.Exception.Response.StatusCode.Value__ -eq 409)
        {
            $restResponse = $null
        }
        elseif ($_.Exception.Response.StatusCode.Value__ -eq 404)
        {
            throw "404 - File or directory not found, The resource you are looking for might have been removed, had its name changed, or is temporarily unavailable"
        }
        elseif ($_.Exception.Response.StatusCode.Value__ -eq 500)
        {
            throw "$( $_.Exception )"
        }
        else
        {
            throw "$( $_.ErrorDetails.Message )"
        }
    }
    catch
    {
        throw $( New-Object System.Exception ("Executing REST API: Error in running $Command on '$URI'", $_.Exception) )
    }
    Write-LogMessage -Type Verbose -Msg "Executing REST API response: $restResponse"
    return $restResponse
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-LogonHeader
# Description....: Invoke REST Method
# Parameters.....: Credentials
# Return Values..: Logon Header
# =================================================================================================================================
Function Get-LogonHeader
{
    param ([Parameter(Mandatory = $true)] [PSCredential]$Credentials)

    if ( [string]::IsNullOrEmpty($global:LogonHeader))
    {
        # Disable SSL Verification to contact PVWA
        if ($DisableSSLVerify)
        {
            Disable-SSLVerification
        }

        if (This-ContainsKeyInParamsObj -name "TenantName")
        {
            $logonToken = Get-LogonTokenUMEnv -Credentials $Credentials
            $logonToken = -join ("Bearer ", $logonToken)
        }
        else
        {
            $logonToken = Get-LogonTokenStandardEnv -Credentials $Credentials
        }

        $logonHeader = $null
        if ( [string]::IsNullOrEmpty($logonToken))
        {
            throw "Executing logon REST API: Logon token is empty - Cannot login"
        }

        # Create a Logon Token Header (This will be used through out all the script)
        $logonHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $logonHeader.Add("Authorization", $logonToken)

        Set-Variable -Name LogonHeader -Value $logonHeader -Scope global
    }

    return $LogonHeader
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-LogonTokenStandardEnv
# Description....: Invoke REST Method
# Parameters.....: Credentials
# Return Values..: Logon Token
# =================================================================================================================================
Function Get-LogonTokenStandardEnv
{
    param ([Parameter(Mandatory = $true)] [PSCredential]$Credentials)
    # Create the POST Body for the Logon
    $logonBody = @{ username = $Credentials.username.Replace('\', ''); password = $Credentials.GetNetworkCredential().password } | ConvertTo-Json
    try
    {
        # Logon
        $logonToken = Invoke-Rest -Command Post -Uri $URL_Logon -Body $logonBody

        # Clear logon body
        $logonBody = ""
    }
    catch
    {
        throw $( $_.Exception.Message )
    }
    return $logonToken
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-LogonTokenUMEnv
# Description....: Invoke REST Method
# Parameters.....: Credentials
# Return Values..: Logon Token
# =================================================================================================================================
Function Get-LogonTokenUMEnv
{
    param ([Parameter(Mandatory = $true)] [PSCredential]$Credentials)

    try
    {
        $subDomain = ([URI]$global:ParamsObj.PVWAURL).Host.Split('.')[0]
        $pvwaDomain = ($global:ParamsObj.PVWAURL.ToLower() -replace "/passwordvault", "") -replace ".privilegecloud", ""
        $global:URL_IdentityFQDN = ($global:URL_IdentityFQDN -f $pvwaDomain, $subDomain)

        # get the IdentityFQDN
        $global:IdentityFQDN = (Invoke-Rest -URI $global:URL_IdentityFQDN -Command Get).fqdn
        $global:URL_Logoff = "https://" + $global:IdentityFQDN + "/security/Logout"
        $identityFQDNDomain = "https://" + $global:IdentityFQDN
        $identityTenantID = $global:IdentityFQDN.Split('.')[0]

        #StartAuthentication API call
        $startAuthenticationURL = $identityFQDNDomain + "/Security/StartAuthentication"
        $startAuthenticationBody = @{
            User = $Credentials.username.Replace('\', '');
            Version = "1.0";
            PlatformTokenResponse = "true"
        } | ConvertTo-Json
        $startAuthenticationResponse = $( Invoke-Rest -Command POST -Uri $startAuthenticationURL -Body $startAuthenticationBody )

        # use these parameters as parameters to AdvanceAuthentication
        $sessionId = $startAuthenticationResponse.Result.SessionId
        $mechanismId = Get-MechanismId -json $startAuthenticationResponse

        #AdvanceAuthentication API call
        $advanceAuthenticationURL = $identityFQDNDomain + "/Security/AdvanceAuthentication"
        $advanceAuthenticationBody = @{
            TenantId = $identityTenantID;
            SessionId = $sessionId;
            MechanismId = $mechanismId;
            Action = "Answer";
            Answer = $Credentials.GetNetworkCredential().password
        } | ConvertTo-Json
        $advanceAuthenticationResponse = $( Invoke-Rest -Command POST -Uri $advanceAuthenticationURL -Body $advanceAuthenticationBody )

        #The token for the REST API calls
        $token = $advanceAuthenticationResponse.Result.Token
    }
    catch
    {
        throw $( $_.Exception.Message )
    }
    return $token
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-MechanismId
# Description....: Get the correct mechanism id
# Parameters.....: StartAuthentication REST call reponse
# Return Values..: Mechanism id
# =================================================================================================================================
Function Get-MechanismId
{
    param ([Parameter(Mandatory = $true)] $json)

    $challenges = $json.Result.Challenges
    $mechanismId = $null
    $bFound = $false

    foreach ($challenge in $challenges)
    {
        $mechanisms = $challenge.mechanisms
        foreach ($mechanism in $mechanisms)
        {
            if ($mechanism.PromptSelectMech -eq "Password")
            {
                $bFound = $true
                $mechanismId = $mechanism.MechanismId
                break
            }
        }
    }

    if ($bFound -eq $false)
    {
        throw "mechanism id couldn't be found"
    }
    return $mechanismId
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Update-ValueInINIFile
# Description....: Update parameter in INI file
# Parameters.....: platformZipPath, name, currentValue, requiredValue
# Return Values..: None
# =================================================================================================================================
function Update-ParamInINIFile
{
    param ($platformZipPath, $name, $currentValue, $requiredValue)

    try
    {
        $platformZipFolder = Extract-ZipToDirectory -zipPath $platformZipPath

        # Find all ini files in the platform ZIP
        $fileEntries = Get-ChildItem -Path $platformZipFolder -Filter '*.ini'
        Write-LogMessage -Type Verbose -Msg $fileEntries

        # There should be only one file
        if ($fileEntries.Count -eq 0)
        {
            throw "Platform zip file does not contain a policy INI file"
        }
        elseif ( $fileEntries.Count -ne 1 )
        {
            throw "Invalid platform ZIP file - duplicate INI file"
        }

        $iniContent = Get-Content -Path $fileEntries[0].FullName
        $iniContent = $iniContent.Replace("$( $name )=$( $currentValue )", "$( $name )=$( $requiredValue )")
        $iniContent | Out-File $fileEntries[0].FullName -Force -Encoding ASCII

        Write-LogMessage -Type Debug -Msg "Deleted original ZIP and packing the new platform in a new ZIP"
        Remove-Item $platformZipPath

        [System.IO.Compression.ZipFile]::CreateFromDirectory($platformZipFolder, $platformZipPath)
        Write-LogMessage -Type Debug -Msg "Removing extracted ZIP folder"
        Remove-Item -Recurse $platformZipFolder
    }
    catch
    {
        throw "$( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Update-GracePeriodParam
# Description....: Update Grace Period parameter
# Parameters.....: platformPath, name, currentValue, requiredValue
# Return Values..: platformZipPath
# =================================================================================================================================
function Update-GracePeriodParam
{
    param ($platformPath, $name, $currentValue, $requiredValue)

    try
    {
        Copy-Item $platformPath $ENV:Temp -Force

        $platformZipPath = $( Join-Path -Path $ENV:Temp $( split-path $platformPath -Leaf ) )

        Update-ParamInINIFile -platformZipPath $platformZipPath -name "GracePeriod" -currentValue $global:DefaultParamsObj.GracePeriod -requiredValue $global:ParamsObj.GracePeriod
    }
    catch
    {
        throw "An error occurred while updating platform's Grace Period parameter, Error: $( $_.Exception.Message )"
    }

    return $platformZipPath
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Update-PolicyTypeParam
# Description....: Update Policy Type parameter
# Parameters.....: platformID, currentValue, requiredValue, id
# Return Values..: platformZipPath
# =================================================================================================================================
function Update-PolicyTypeParam
{
    param ($platformID, $currentValue, $requiredValue, $id)

    try
    {
        $platformZipPath = $( Export-Platform -platformID $platformID )

        Update-ParamInINIFile -platformZipPath $platformZipPath -name "PolicyType" -currentValue $currentValue -requiredValue $requiredValue

        switch ($currentValue)
        {
            "Group"
            {
                Delete-GroupPlatform -id $id
            }
            "RotationalGroup"
            {
                Delete-RotationalGroupPlatform -id $id
            }
        }
    }
    catch
    {
        throw "There is an error while updating platform's policy type parameter, Error: $( $_.Exception.Message )"
    }

    return $platformZipPath
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Import-Platform
# Description....: 
# Parameters.....: 
# Return Values..: 
# =================================================================================================================================
function Import-Platform
{
    param ($platformPath)

    $importBody = @{ ImportFile = $( Get-ZipContent $platformPath ) } | ConvertTo-Json -Depth 5

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $ImportPlatformResponse = Invoke-Rest -Command POST -Uri $global:URL_ImportPlatforms -Header $( Get-LogonHeader $creds ) -Body $importBody
        if ($null -ne $ImportPlatformResponse)
        {
            Write-LogMessage -Type Info -Msg "Platform ID imported: $( $ImportPlatformResponse.PlatformID )"
        }
        else
        {
            Write-LogMessage -Type Info -Msg "No need to import $( split-path $platformPath -Leaf ) because a platform with the same name already exists"
        }
    }
    catch
    {
        throw "An error occurred while importing the platform, Error: $( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Export-Platform
# Description....: 
# Parameters.....: 
# Return Values..: 
# =================================================================================================================================
function Export-Platform
{
    param ($platformID)

    $exportPath = "$( Join-Path -Path $ENV:Temp -ChildPath $platformID ).zip"

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $exportURL = $global:URL_ExportPlatforms -f $platformID
        Invoke-Rest -Command POST -Uri $exportURL -Header $( Get-LogonHeader $creds ) -OutFile $exportPath
    }
    catch
    {
        throw "An error occurred while exporting platform $platformID, Error: $( $_.Exception.Message )"
    }

    return $exportPath
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-GroupPlatformID
# Description....: Get group platform id (if exists)
# Parameters.....: PlatformName
# Return Values..: id
# =================================================================================================================================
function Get-GroupPlatformID
{
    param ($PlatformName)

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $id = $null
        $platformsDetailResults = Invoke-Rest -Command GET -Uri $global:URL_GetGroupPlatforms -Header $( Get-LogonHeader $creds )

        if ($platformsDetailResults.Total -ge 1)
        {
            foreach ($platform in $platformsDetailResults.platforms)
            {
                if ($platform.Name -eq $PlatformName)
                {
                    $id = $platform.id
                    break
                }
            }
        }

        return $id
    }
    catch
    {
        throw "Executing REST API: Failed to get group platform ID, Error: $( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-RotationalGroupPlatformID
# Description....: Get rotational platform id (if exists)
# Parameters.....: PlatformName
# Return Values..: id
# =================================================================================================================================
function Get-RotationalGroupPlatformID
{
    param ($PlatformName)

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $id = $null
        $platformsDetailResults = Invoke-Rest -Command GET -Uri $global:URL_GetRotationalGroupPlatforms -Header $( Get-LogonHeader $creds )

        if ($platformsDetailResults.Total -ge 1)
        {
            foreach ($platform in $platformsDetailResults.platforms)
            {
                if ($platform.Name -eq $PlatformName)
                {
                    $id = $platform.id
                    break
                }
            }
        }

        return $id
    }
    catch
    {
        throw "Executing REST API: Failed to get rotational group platform ID, Error: $( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Delete-GroupPlatform
# Description....: Delete group platform
# Parameters.....: id
# Return Values..: None
# =================================================================================================================================
function Delete-GroupPlatform
{
    param ($id)

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $deleteURL = $global:URL_DeleteGroupPlatforms -f $id
        Invoke-Rest -Command DELETE -Uri $deleteURL -Header $( Get-LogonHeader $creds )
    }
    catch
    {
        throw "An error occurred while deleting group platform, Error: $( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Delete-RotationalGroupPlatform
# Description....: Delete rotational group platform
# Parameters.....: id
# Return Values..: None
# =================================================================================================================================
function Delete-RotationalGroupPlatform
{
    param ($id)

    $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

    try
    {
        $deleteURL = $global:URL_DeleteRotationalGroupPlatforms -f $id
        Invoke-Rest -Command DELETE -Uri $deleteURL -Header $( Get-LogonHeader $creds )
    }
    catch
    {
        throw "An error occurred while deleting rotational group platform, Error: $( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Run-Logoff
# Description....: Logoff PVWA
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
Function Run-Logoff
{
    try
    {
        # Logoff the session
        Write-LogMessage -Type Info -Msg "Logoff Session..."

        if ($null -ne $global:LogonHeader)
        {
            Invoke-Rest -Command Post -Uri $global:URL_Logoff -Header $global:LogonHeader | out-null
            $global:LogonHeader = $null
        }
    }
    catch
    {
        throw "Executing REST API: Failed to logoff session, Error: $( $_.Exception.Message )"
    }
}

#endregion

#region Account Handler Functions
# @FUNCTION@ ======================================================================================================================
# Name...........: Add-DualAccountProperties
# Description....: 
# Parameters.....: 
# Return Values..: 
# =================================================================================================================================
function Add-DualAccountProperties
{
    param ($tempFolder)

    Write-LogMessage -Type Debug -Msg "Adding dual account support to platform $PlatformID"

    # Find all XML files in the platform ZIP
    $fileEntries = Get-ChildItem -Path $tempFolder -Filter '*.xml'
    Write-LogMessage -Type Verbose -Msg $fileEntries

    # There should be only one file
    if ($fileEntries.Count -ne 1)
    {
        throw "Invalid Platform ZIP file - duplicate XML file"
    }

    [xml]$xmlContent = Get-Content $fileEntries[0].FullName
    # Add PSM details to XML
    Write-LogMessage -Type Debug -Msg "Adding dual account Properties"

    $propNode = $xmlContent.CreateNode("element", "Property", "")
    $propNode.SetAttribute("Name", "Index")
    $xmlContent.Device.Policies.Policy.Properties.Optional.AppendChild($propNode) | Out-Null
    $propNode = $xmlContent.CreateNode("element", "Property", "")
    $propNode.SetAttribute("Name", "DualAccountStatus")
    $xmlContent.Device.Policies.Policy.Properties.Optional.AppendChild($propNode) | Out-Null
    $propNode = $xmlContent.CreateNode("element", "Property", "")
    $propNode.SetAttribute("Name", "VirtualUsername")
    $xmlContent.Device.Policies.Policy.Properties.Optional.AppendChild($propNode) | Out-Null

    $newPlatformID = $global:ParamsObj.platformID + "-DualAccount"
    Write-LogMessage -Type Debug -Msg "Renaming platform for dual accounts - $platformID"
    $xmlContent.Device.Policies.Policy.ID = $newPlatformID
    Write-LogMessage -Type Debug -Msg "New platform ID: $( $xmlContent.Device.Policies.Policy.ID )"
    $xmlContent.Save($fileEntries[0].FullName)
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Edit-PlatformINIFile
# Description....: Edit the Platform INI file
# Parameters.....: tempFolder
# Return Values..: None
# =================================================================================================================================
function Edit-PlatformINIFile
{
    param ($tempFolder)

    # Find all ini files in the platform ZIP
    $fileEntries = Get-ChildItem -Path $tempFolder -Filter '*.ini'
    Write-LogMessage -Type Verbose -Msg $fileEntries

    # There should be only one file
    if ($fileEntries.Count -ne 1)
    {
        throw "Invalid Platform ZIP file - duplicate INI file"
    }

    $iniContent = Get-Content -Path $fileEntries[0].FullName
    $newPlatformID = $global:ParamsObj.platformID + "-DualAccount"
    $iniContent = $iniContent.Replace($global:ParamsObj.platformID, $newPlatformID)

    $platformNameArray = ($iniContent -match "PolicyName=([\w ]{1,})").Replace("PolicyName=", "").Split(';')

    # Found the Platform name, add Dual Accounts to it
    $platformName = $platformNameArray[0].TrimEnd()
    $iniContent = $iniContent.Replace($platformName, $platformName + " Dual Account")

    $iniContent | Out-File $fileEntries[0].FullName -Force -Encoding ASCII
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Create-DualAccountPlatformZip
# Description....: 
# Parameters.....: 
# Return Values..: 
# =================================================================================================================================
function Create-DualAccountPlatformZip
{
    param ($platformZipPath)

    try
    {
        $platformZipFolder = Extract-ZipToDirectory -zipPath $platformZipPath
        Add-DualAccountProperties -tempFolder $platformZipFolder
        Edit-PlatformINIFile -tempFolder $platformZipFolder

        Write-LogMessage -Type Debug -Msg "Deleted original ZIP and packing the new platform in a new ZIP"
        Remove-Item $platformZipPath

        [System.IO.Compression.ZipFile]::CreateFromDirectory($platformZipFolder, $platformZipPath)
        Write-LogMessage -Type Debug -Msg "Removing extracted ZIP folder"
        Remove-Item -Recurse $platformZipFolder
    }
    catch
    {
        throw "Error while converting platform to Dual Account platform, Error: $( $_.Exception.Message )"
    }

    return $platformZipPath
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-Account
# Description....: Returns a list of accounts based on a filter
# Parameters.....: Account name, Account address, Account Safe Name
# Return Values..: List of accounts
# =================================================================================================================================
function Get-Account
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$accountName,
        [Parameter(Mandatory = $true)]
        [String]$accountAddress,
        [Parameter(Mandatory = $true)]
        [String]$platformID,
        [Parameter(Mandatory = $true)]
        [String]$safeName,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Ignore", "Inquire", "SilentlyContinue", "Stop", "Suspend")]
        [String]$errAction = "Continue",
        [Parameter(Mandatory = $true)]
        [PSCredential]$vaultCredentials
    )

    $retAccount = $null
    $accounts = $null

    try
    {
        $urlSearchAccount = $URL_Accounts + "?filter=safename eq " + $( Encode-URL $safeName ) + "&search=" + $( Encode-URL "$accountName $accountAddress $platformID" )

        # Search for created account
        $accounts = $( Invoke-Rest -Uri $urlSearchAccount -Header $( Get-LogonHeader -Credentials $vaultCredentials ) -Command "Get" -ErrAction $errAction )
        if ($null -ne $accounts)
        {
            foreach ($item in $accounts.value)
            {
                if (( $item -ne $null) -and ( $item.username -ceq $accountName) -and ( $item.address -eq $accountAddress) -and ( $item.platformID -eq $platformID))
                {
                    $retAccount = $item
                    break;
                }
            }
        }
    }
    catch
    {
        throw "An error occurred while retreiving the account object, $( $_.Exception.Message )"
    }

    return $retAccount
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-Group
# Description....: Returns a list of groups based on a filter
# Parameters.....: Safe Name,Account Name
# Return Values..: List of accounts
# =================================================================================================================================
function Get-Group
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$safeName,
        [Parameter(Mandatory = $true)]
        [String]$groupName,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Ignore", "Inquire", "SilentlyContinue", "Stop", "Suspend")]
        [String]$errAction = "Continue",
        [Parameter(Mandatory = $true)]
        [PSCredential]$vaultCredentials
    )

    $retGroup = $null
    $groups = $null

    try
    {
        $urlSearchGroup = $global:URL_AccountGroups + "?safe=$safeName"

        # Search for group
        $groups = $( Invoke-Rest -Uri $urlSearchGroup -Header $( Get-LogonHeader -Credentials $vaultCredentials ) -Command "Get" -ErrAction $errAction )
        if ($null -ne $groups)
        {
            foreach ($item in $groups)
            {
                if (( $item -ne $null) -and ( $item.groupName -eq $groupName))
                {
                    $retGroup = $item
                    break;
                }
            }
        }
    }
    catch
    {
        throw "An error occurred while retreiving the group object, $( $_.Exception.Message )"
    }

    return $retGroup
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-VirtualUserName
# Description....: Returns a list of virtual user name based on a filter
# Parameters.....: Safe Name,Account Name
# Return Values..: List of virtual user name
# =================================================================================================================================
function Get-VirtualUserName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$safeName,
        [Parameter(Mandatory = $true)]
        [String]$virtualUserName,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Ignore", "Inquire", "SilentlyContinue", "Stop", "Suspend")]
        [String]$errAction = "Continue",
        [Parameter(Mandatory = $true)]
        [PSCredential]$vaultCredentials
    )

    $retVirtualUserName = $null
    $accounts = $null;

    try
    {
        $urlSearchAccount = $URL_Accounts + "?filter=safename eq " + $( Encode-URL $safeName ) + "&search=" + $( Encode-URL "$VirtualUserName" )

        # Search for created account
        $accounts = $( Invoke-Rest -Uri $urlSearchAccount -Header $( Get-LogonHeader -Credentials $vaultCredentials ) -Command "Get" -ErrAction $errAction )
        if ($null -ne $accounts)
        {
            foreach ($item in $accounts.value)
            {
                if (( $item -ne $null) -and ( $item.platformAccountProperties.VirtualUsername -eq $virtualUserName))
                {
                    $retVirtualUserName = $item
                    break;
                }
            }
        }
    }
    catch
    {
        throw "An error occurred while retreiving the account object, $( $_.Exception.Message )"
    }

    return $retVirtualUserName
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Test-AccountExist
# Description....: Checks if an account exists
# Parameters.....: Account name, Account address, Account Safe Name
# Return Values..: True / False
# =================================================================================================================================
function Test-AccountExist
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$accountName,
        [Parameter(Mandatory = $true)]
        [String]$accountAddress,
        [Parameter(Mandatory = $true)]
        [String]$platformID,
        [Parameter(Mandatory = $true)]
        [String]$safeName,
        [Parameter(Mandatory = $true)]
        [PSCredential]$VaultCredentials
    )

    try
    {
        $accountResult = $( Get-Account -accountName $accountName -accountAddress $accountAddress -platformID $platformID -safeName $safeName -VaultCredentials $VaultCredentials -ErrAction "SilentlyContinue" )
        if (( $null -eq $accountResult) -or ( $accountResult.count -eq 0))
        {
            # No accounts found
            Write-LogMessage -Type Debug -MSG "Account $accountName does not exist"
            return $false
        }
        else
        {
            # Account Exists
            Write-LogMessage -Type Info -MSG "Account $accountName exist"
            return $true
        }
    }
    catch
    {
        throw "$( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-RotationalGroupIDFromSafe
# Description....: Get the rotational Group ID (if exists) from a safe
# Parameters.....: GroupPlatformID, Safe Name, GroupName
# Return Values..: Group ID
# =================================================================================================================================
function Get-RotationalGroupIDFromSafe
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupPlatformID,
        [Parameter(Mandatory = $true)]
        [string]$safeName,
        [Parameter(Mandatory = $true)]
        [string]$groupName,
        [Parameter(Mandatory = $true)]
        [PSCredential]$vaultCredentials
    )

    try
    {
        # Check if this safe already has a Rotational Group for this Account
        Write-LogMessage -Type Debug -Msg "Searching for $groupName rotational group in safe $safeName"

        $groupID = $null
        $urlSafeAccountGroups = $global:URL_AccountGroups + "?safe=$safeName"
        $safeAccountGroupsResult = Invoke-Rest -Command GET -Uri $urlSafeAccountGroups -Header $( Get-LogonHeader -Credentials $VaultCredentials )

        if ($safeAccountGroupsResult -ne $null -or $safeAccountGroupsResult.Count -ge 1)
        {
            Write-LogMessage -Type Verbose -Msg "Going over $( $safeAccountGroupsResult.Count ) found account group"
            foreach ($group in $safeAccountGroupsResult)
            {
                if (( $group.GroupPlatformID -eq $groupPlatformID) -and ( $group.GroupName -eq $groupName))
                {
                    # Get existing group ID
                    $groupID = $group.GroupID
                    Write-LogMessage -Type Debug -Msg "Found rotational group ID: $groupID"
                }
            }
        }

        return $groupID
    }
    catch
    {
        throw "Executing REST API: Failed to get rotational group ID from safe, Error: $( $_.Exception.Message )"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Add-RotationalGroup
# Description....: Create a new Rotational group for Dual Accounts
# Parameters.....: GroupPlatformID, Safe Name, VirtualUserName, AccountID
# Return Values..: None
# =================================================================================================================================
Function Add-RotationalGroup
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$groupPlatformID,
        [Parameter(Mandatory = $true)]
        [string]$safeName,
        [Parameter(Mandatory = $true)]
        [string]$virtualUserName,
        [Parameter(Mandatory = $true)]
        [string]$accountID,
        [Parameter(Mandatory = $true)]
        [PSCredential]$vaultCredentials
    )

    try
    {
        $groupID = $null
        $groupName = $global:ParamsObj.GroupName
        $groupID = Get-RotationalGroupIDFromSafe -groupPlatformID $groupPlatformID -safeName $safeName -groupName $groupName -VaultCredentials $vaultCredentials
        Write-LogMessage -Type Verbose -Msg "Found group ID: $groupID"

        # Create a new Group
        if ( [string]::IsNullOrEmpty($groupID))
        {
            # If no group - create the group
            $groupBody = "" | Select GroupName, GroupPlatformId, Safe
            $groupBody.GroupName = $groupName
            $groupBody.GroupPlatformID = $groupPlatformID
            $groupBody.Safe = $safeName

            $addAccountGroupResult = Invoke-Rest -Command Post -URI $global:URL_AccountGroups -Header $( Get-LogonHeader -Credentials $vaultCredentials ) -Body $( $groupBody | ConvertTo-Json )
            if ($addAccountGroupResult -ne $null)
            {
                Write-LogMessage -Type Verbose -Msg "Rotational group created. Group ID: $( $addAccountGroupResult.GroupID )"
                $groupID = $addAccountGroupResult.GroupID
            }
        }
        # Check that a group was created or found
        if (![string]::IsNullOrEmpty($groupID))
        {
            # Add the Account to the Rotational Group
            $accountGroupMemberBody = "" | Select AccountID
            $accountGroupMemberBody.AccountID = $accountID

            $addAccountGroupMemberResult = Invoke-Rest -Command Post -URI ($global:URL_AccountGroupMembers -f $groupID) -Header $( Get-LogonHeader -Credentials $vaultCredentials ) -Body $( $accountGroupMemberBody | ConvertTo-Json )
        }
        else
        {
            throw "An error occurred while getting the rotational group ID"
        }
    }
    catch
    {
        throw "($_.Exception.Message)"
    }
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Add-DualAccount
# Description....: Create a new Dual Account
# Parameters.....: User Name, User password, PlatformID, Safe Name, VirtualUserName, Index
# Return Values..: None
# =================================================================================================================================
function Add-DualAccount
{
    try
    {
        $creds = New-Object -TypeName System.Management.Automation.PSCredential($global:ParamsObj.PASUserName, $global:ParamsObj.PASPassword)

        foreach ($account in $global:AccountListObj)
        {
            $accountName = ('{0}@{1}' -f $account.userName, $account.address)

            if (( Test-AccountExist -accountName $account.userName -accountAddress $account.address -safeName $account.safeName -platformID $account.platformId -VaultCredentials $creds) -eq $false)
            {
                Write-LogMessage -Type Debug -Msg "Creating a new account for $accName"

                $accountCreds = New-Object -TypeName System.Management.Automation.PSCredential($account.username, [SecureString]$account.secret)
                $account.secret = $accountCreds.GetNetworkCredential().password
                $addAccountResult = $( Invoke-Rest -Uri $global:URL_Accounts -Header $( Get-LogonHeader -Credentials $creds ) -Body $( $account | ConvertTo-Json -Depth 5 ) -Command "Post" )

                # Create the Roataional Group
                Write-LogMessage -Type Info -MSG "Assigning the account '$accountName' to a rotational group"
                Add-RotationalGroup -groupPlatformID $account.groupPlatformId -safeName $account.safeName -virtualUserName $account.userName -accountID $addAccountResult.id -VaultCredentials $creds
            }
        }
    }
    catch
    {
        throw "Executing REST API: Failed to add the account '$accountName', Error: $( $_.Exception.Message )"
    }
}

#endregion

#region Functions
# @FUNCTION@ ======================================================================================================================
# Name...........: Set-URLParameters
# Description....: Set value in URL parameters
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Set-URLParameters
{
    # URLS
    # -----------

    $global:URL_PVWAAPI = $global:ParamsObj.PVWAURL + "/api"
    $global:URL_Authentication = $global:URL_PVWAAPI + "/auth"
    $global:URL_Logon = $global:URL_Authentication + "/cyberark/Logon"
    $global:URL_Logoff = $global:URL_Authentication + "/Logoff"


    # URL Methods
    # -----------
    $global:URL_PlatformDetails = $global:URL_PVWAAPI + "/Platforms/{0}"
    $global:URL_ImportPlatforms = $global:URL_PVWAAPI + "/Platforms/Import"
    $global:URL_ExportPlatforms = $global:URL_PlatformDetails + "/Export"
    $global:URL_GetGroupPlatforms = $global:URL_PVWAAPI + "/Platforms/Groups"
    $global:URL_GetRotationalGroupPlatforms = $global:URL_PVWAAPI + "/Platforms/RotationalGroups"
    $global:URL_DeleteGroupPlatforms = $global:URL_PVWAAPI + "/Platforms/Groups/{0}"
    $global:URL_DeleteRotationalGroupPlatforms = $global:URL_PVWAAPI + "/Platforms/RotationalGroups/{0}"
    $global:URL_Accounts = $global:URL_PVWAAPI + "/Accounts"
    $global:URL_AccountsDetails = $URL_Accounts + "/{0}"
    $global:URL_AccountGroups = $URL_PVWAAPI + "/AccountGroups"
    $global:URL_AccountGroupMembers = $URL_PVWAAPI + "/AccountGroups/{0}/Members"

    # UM URLS
    $global:URL_IdentityFQDN = "{0}/shell/api/endpoint/{1}"

}

# @FUNCTION@ ======================================================================================================================
# Name...........: Initialization
# Description....: Initialization function, initialize script parameters
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
function Initialization
{
    # Create ParamsObj
    # -----------------------------------------------------------------------------------------------------------------------------

    # Set command line arguments    
    if (!( This-ParameterEmptyOrWhiteSpace -value $PASPassword))
    {
        $PASPassword = ConvertTo-SecureString -String $PASPassword -AsPlainText -Force
    }

    Set-ValueInParamsObj -name "PASPassword" -value $PASPassword
    Set-ValueInParamsObj -name "PASUserName" -value $PASUserName
    Set-ValueInParamsObj -name "AuthenticationType" -value $AuthenticationType
    Set-ValueInParamsObj -name "ConfigFileFullPath" -value $ConfigFileFullPath

    if (-not([string]::IsNullOrEmpty($TenantName)))
    {
        Set-ValueInParamsObj -name "TenantName" -value $TenantName
    }

    # Set config file values
    if (Test-Path -Path $global:ParamsObj.ConfigFileFullPath)
    {
        $policyJson = Get-Content -Raw -Path  $global:ParamsObj.ConfigFileFullPath | %{ $_ -replace [RegEx]::Escape("\"), "\\" } | ConvertFrom-Json
    }
    else
    {
        throw "Cannot find config file path - file does not exist"
    }

    Write-LogMessage -Type Info -MSG "The following values were read from the configuration file:" -SubHeader
    foreach ($item in $policyJson.PSObject.Properties)
    {
        Set-ValueInParamsObj -name $item.Name -value $item.Value
        Write-LogMessage -Type Info -MSG "The value of: '$( $item.Name )' is: $( $item.Value )"
    }

    # Verify Grace Period parameter
    Verify-GracePeriodParam

    # Verify Log File Full Path parameter
    Verify-LogFilePathParam

    # Set a default value if needed
    Set-DefaultValueInParamsObj

    # Verify empty or white space parameters
    foreach ($item in $global:ParamsObj.GetEnumerator())
    {
        Verify-EmptyOrWhiteSpaceParam -name $item.Name -value $item.Value
    }

    # Verify PVWA URL parameter
    Verify-PVWAURLParam

    # Verify authentication type parameter
    Verify-AuthenticationType

    # Create AccountListObj
    # -----------------------------------------------------------------------------------------------------------------------------

    # Set accounts values
    if (!( This-ParameterEmptyOrWhiteSpace -value $AccountList))
    {
        Set-ValuesInAccountListObj
    }
    else
    {
        throw "The parameter: AcountList can not be empty"
    }

    # URL parameters
    # -----------------------------------------------------------------------------------------------------------------------------

    # Set value to URL parameters
    Set-URLParameters


    # Verify group name parameter
    Verify-GroupNameParam

    # Verify virtual user name parameter
    Verify-VirtualUserNameParam
}
#endregion

# =================================================================================================================================
# Main script
# =================================================================================================================================

try
{
    # Steps:
    # -----------------------------------------------------------------------------------------------------------------------------
    # 1. Initialize script parameters
    # 2. Import the 'Rotation Groups' platform sample template
    # 3. Export platform
    # 4. Create dual account platform
    # 5. Import dual account platform
    # 6. Add dual account
    # 7. Set 'Rotation Groups'platform Police Type to "RotationGroup"
    # 8. Logoff the session 

    Initialization

    Write-LogMessage -Type Info -MSG "Starting 'Dual Account - Creation' script (v$ScriptVersion)" -Header
    Write-LogMessage -Type Info -MSG "Running PowerShell version $( $PSVersionTable.PSVersion.Major )" -SubHeader

    # Clear sensitive data
    $PASPassword = $null
    $AccountList = $null

    if ($global:ParamsObj.LogDebugLevel)
    {
        Write-LogMessage -Type Info -MSG "Running 'Dual Account Creation' script in Debug mode" -Header
    }
    if ($global:ParamsObj.LogVerboseLevel)
    {
        Write-LogMessage -Type Info -MSG "Running 'Dual Account Creation' script in Verbose mode" -Header
    }

    $id = Get-RotationalGroupPlatformID -PlatformName "Sample Rotational Group"
    if ($null -ne $id)
    {
        Import-Platform -platformPath $( Update-PolicyTypeParam -platformID "RotationalGroup" -currentValue "RotationalGroup" -requiredValue "group" -id $id )
    }
    elseif ( $global:ParamsObj.GracePeriod -ne $global:DefaultParamsObj.GracePeriod )
    {
        Import-Platform -platformPath $( Update-GracePeriodParam -platformPath $global:ParamsObj.PlatformSampleTemplate )
    }
    else
    {
        Import-Platform -platformPath $global:ParamsObj.PlatformSampleTemplate
    }

    Import-Platform -platformPath $( Create-DualAccountPlatformZip -platformZipPath $( Export-Platform -platformID $global:ParamsObj.PlatformID ) )

    Add-DualAccount

    $id = Get-GroupPlatformID -PlatformName "Sample Rotational Group"
    if ($null -ne $id)
    {
        Import-Platform -platformPath $( Update-PolicyTypeParam -platformID "RotationalGroup" -currentValue "group" -requiredValue "RotationalGroup" -id $id )
    }

    Write-LogMessage -Type Info -MSG "Dual Account - Creation: successful" -Header

    Exit 0
}
catch
{
    Write-LogMessage -Type Error -MSG "$( $_.Exception.Message )"

    Write-LogMessage -Type Info -MSG "Dual Account - Creation: failed" -Header

    Exit 1
}
finally
{
    Run-Logoff

    Write-LogMessage -Type Info -MSG "Dual Account - Creation: script ended"
}
