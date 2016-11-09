
DSC working with certs

    xCertificateImport MyRoot
    {
        Thumbprint = '181C7A4A883C1D25B083BA11C8DC4A1F2664DD41'
        Store      = 'Root'
        Location   = 'LocalMachine'
        Path       = "c:\certs\myRootCert.CER"
    }

    xPfxImport IISCert
    {
        Thumbprint = '11DB2C917236C2E19ADD2B1F73FE11B188BCBD21'
        Path       = "c:\certs\myWildCert.pfx"
        Store      = 'WebHosting'
        Credential = $Credential'
        Location   = 'LocalMachine'
    }

    xWebsite DefaultSite
    {
        Ensure = 'Present'
        Name = 'Default Web Site'
        State = 'Started'

        BindingInfo = @(
            MSFT_xWebBindingInformation {
                Protocol              = 'HTTPS'
                Port                  = 443
                CertificateThumbprint = '11DB2C917236C2E19ADD2B1F73FE11B188BCBD21'
                CertificateStoreName  = 'WebHosting'
                IPAddress             = '*'
            };
            MSFT_xWebBindingInformation {
                Protocol  = 'HTTP'
                Port      = 80
                IPAddress = '*'
            };
        )
        DependsOn = '[xPfxImport]IISCert'
    }

    SQL Server: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.x\MSSQLServer\SuperSocketNetLib\Certificate