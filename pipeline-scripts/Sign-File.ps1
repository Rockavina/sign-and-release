<#
.SYNOPSIS
    Signs files using AzureSignTool and code signing certificate from Key Vault.
.DESCRIPTION
    Signs files using AzureSignTool and code signing certificate from Key Vault.

    Authenticate with azure using 'az login' before running this script.

.PARAMETER Path
    Path to file to sign.
    
    Accepts array of files.

.PARAMETER AzureSignToolExe
    Full path to AzureSignTool.exe.

    Example: ".\AzureSignTool.exe"

    Default: use environment variable AZURESIGNTOOL

.PARAMETER KeyVaultUrl
    Key Vault endpoint URL

    Example: "https://mykeyvault.vault.azure.net/"

    Default: use environment variable AZST_KEYVAULT_URL

.PARAMETER CertificateName
    Name of Key Vault certificate resource
    
    Example: "The-Code-Signing-Cert"

    Default: use environment variable AZST_CERTIFICATE_NAME
    
.PARAMETER TimeStampURL
    URL of timestamp service.
    
    Example: "http://timestamp.acs.microsoft.com"

    Default: use environment variable AZST_TIMESTAMP_URL
    
.PARAMETER TimeStampHash
    Hash function to use in timestamp.

    Accepted values:
        sha1
        sha256
        sha384
        sha512
    
    Default: "sha384"
#>

[cmdletbinding()]
param
(
    [Parameter(Mandatory)]
    [string[]]$Path,

    [Parameter()]
    [string]$AzureSignToolExe = $env:AZURESIGNTOOL,

    [Parameter()]
    [string]$KeyVaultUrl = $env:AZST_KEYVAULT_URL,
     
    [Parameter()]
    [string]$CertificateName = $env:AZST_CERTIFICATE_NAME,

    [Parameter()]
    [string]$TimeStampURL = $env:AZST_TIMESTAMP_URL,

    [Parameter()]
    [ValidateSet('sha1','sha256','sha384','sha512')]
    [string]$TimeStampHash = 'sha384'

)

$AzToken = az account get-access-token --resource 'https://vault.azure.net' --query accessToken -o tsv

if ($null -eq $AzToken) {

    throw "Authenticate with 'az login' first."

}

# Convert token to plaintext if necessary
if ($AzToken -is [system.security.securestring]) {

    $BSTR    = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AzToken)
    $AzToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

}

# Set command parameters for AzureSignTool.exe
$AzSignParams = "sign",
                "--azure-key-vault-url", "$($KeyVaultUrl)",
                "--azure-key-vault-accesstoken","$AzToken",
                "--azure-key-vault-certificate", "$($CertificateName)",
                "--timestamp-rfc3161","$($TimeStampURL)",
                "--timestamp-digest","$($TimeStampHash)"
                
# Add list of files to sign to command parameters
foreach ($File in $Path) {

    $AzSignParams += $File

}

# Run signing, capture and display output
& $AzureSignToolExe $AzSignParams | Tee-Object -Variable Result

# Throw error if signing failed
if (-not ($Result -match "Failed operations: 0")){

    throw "Failed to sign $Path"

}
