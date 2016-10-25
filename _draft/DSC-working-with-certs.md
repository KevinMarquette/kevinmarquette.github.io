
DSC working with certs

    xCertificateImport MGAM_Root
    {
        Thumbprint = '281C7A4A883C7D25B083BA11C8DC4A1F2664DD44'
        Store      = 'Root'
        Location   = 'LocalMachine'
        Path       = "myCert.CER"
    }

    xPfxImport IISCert
    {
        Thumbprint = '23DB2C917236C2E99ADD2B7F73FE03BD88BCBD26'
        Path       = "mycert.pfx"
        Store      = 'WebHosting'
        Credential = New-Credential 'Password1'
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
                CertificateThumbprint = '23DB2C917236C2E99ADD2B7F73FE03BD88BCBD26'
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