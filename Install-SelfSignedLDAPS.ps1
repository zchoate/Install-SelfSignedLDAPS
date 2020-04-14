<#
.DESCRIPTION
    Generate self-signed certificate signed by CA and install for use with LDAPS.
    Eliminates need to install AD Certificate Services.
    Can be used to output CA cert and LDAPS cert as base 64 encoded certificates.
.PARAMETER exportCerts
    Export CA and CA-signed certificate upon script completion.
.PARAMETER exportPath
    Defaults to $env:TEMP but path can be specified with this parameter.
    Example: Install-SelfSignedLDAPS.ps1 -exportCerts -exportPath "C:\Certs"
.PARAMETER caValidYears
    Defaults to 1
    Specify validity of CA in years.
.PARAMETER certValidYears
    Defaults to 1
    Specify validity of cert in years.
    Must be less than or equal to CA validity.
.EXAMPLE
    Install-SelfSignedLDAPS.ps1 -exportCerts -exportPath "C:\Certs" -caValidYears 5 -certValidYears 5
.NOTES
    Version:        0.1
    Last updated:   04/14/2020
    Creation date:  04/14/2020
    Author:         Zachary Choate
    URL:            
#>

param(
    [switch]$exportCerts,
    [string]$exportPath,
    [int]$caValidYears,
    [int]$certValidYears
)

# Check to see if parameters are set. If not, set defaults.
if( [string]::IsNullOrEmpty($exportPath) ) {
    $exportPath = $env:TEMP
}
if( !($caValidYears) ) {
    $caValidYears = 1
}
if( !($certValidYears) ) {
    $certValidYears = 1
}

# Get AD details
$domainDNSRoot = (Get-ADDomain).DNSRoot
$caName = "$domainDNSRoot Root Cert"
$certDomain = "*.$domainDNSRoot"

# Generate self-signed CA
$caCert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -HashAlgorithm SHA256 -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears($caValidYears) -KeyUsage KeyEncipherment, DataEncipherment, CertSign -KeyUsageProperty All -FriendlyName "$caName" -Subject "CN=$caName" -TextExtension @("2.5.29.19={text}ca=1&pathlength=1")

# Generate cert signed by CA
$ldapsCert = New-SelfSignedCertificate -DnsName $certDomain -CertStoreLocation Cert:\LocalMachine\My -Signer $caCert -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears($certValidYears)

$thumbprint = $ldapsCert.Thumbprint

# test thumbprint and compare against current certificate installed
If(!(Test-Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Services\NTDS\SystemCertificates\My\Certificates")) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Services\NTDS\SystemCertificates\My\Certificates" -Force
} else {
    $currentCerts = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Services\NTDS\SystemCertificates\My\Certificates" -Recurse
    ForEach($currentCert in $currentCerts) {
        If($thumbprint -eq $currentCert.PSChildName) {
            Break
        } else {
            Remove-Item -Path $currentCert -Force
        }
    }
}

# Copy LDAPS cert to NTDS store for use with LDAPS.
$copyParameters = @{
    'Path' = "HKLM:\Software\Microsoft\SystemCertificates\MY\Certificates\$thumbprint"
    'Destination' = "HKLM:\SOFTWARE\Microsoft\Cryptography\Services\NTDS\SystemCertificates\My\Certificates\$thumbprint"
    'Recurse' = $true
}
Copy-Item @copyParameters

# Apply LDAPS cert.
"dn:
changetype: modify
add: renewServerCertificate
renewServerCertificate: 1
-" | Out-File -FilePath $env:TEMP\ldap-reload.txt

Start-Process ldifde -ArgumentList "-i -f $env:Temp\ldap-reload.txt"

# Export certificates if specified.
if($exportCerts) {
    $caCertExport = @(
        '-----BEGIN CERTIFICATE-----'
        [System.Convert]::ToBase64String($caCert.RawData, 'InsertLineBreaks')
        '-----END CERTIFICATE-----'
    )

    $cacertExport | Out-File -FilePath "$exportPath\caCert.crt" -Encoding ascii

    $ldapsCertExport = @(
        '-----BEGIN CERTIFICATE-----'
        [System.Convert]::ToBase64String($ldapsCert.RawData, 'InsertLineBreaks')
        '-----END CERTIFICATE-----'
    )

    $ldapsCertExport | Out-File -FilePath "$exportPath\ldapsCert.crt" -Encoding ascii
}