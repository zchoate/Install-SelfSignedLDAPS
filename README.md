# Install-SelfSignedLDAPS
Install LDAPS certificate signed by self-signed CA.

### DESCRIPTION
    Generate self-signed certificate signed by CA and install for use with LDAPS.
    Eliminates need to install AD Certificate Services.
    Can be used to output CA cert and LDAPS cert as base 64 encoded certificates.
### PARAMETER exportCerts
    Export CA and CA-signed certificate upon script completion.
### PARAMETER exportPath
    Defaults to $env:TEMP but path can be specified with this parameter.
    Example: Install-SelfSignedLDAPS.ps1 -exportCerts -exportPath "C:\Certs"
### PARAMETER caValidYears
    Defaults to 1
    Specify validity of CA in years.
### PARAMETER certValidYears
    Defaults to 1
    Specify validity of cert in years.
    Must be less than or equal to CA validity.
### EXAMPLE
```
Install-SelfSignedLDAPS.ps1 -exportCerts -exportPath "C:\Certs" -caValidYears 5 -certValidYears 5
```
### NOTES
    Version:        0.1
    Last updated:   04/14/2020
    Creation date:  04/14/2020
    Author:         Zachary Choate
    URL:            https://raw.githubusercontent.com/zchoate/Install-SelfSignedLDAPS/master/Install-SelfSignedLDAPS.ps1
