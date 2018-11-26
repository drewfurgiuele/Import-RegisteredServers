<#
    There should be a longer help file here.
#>

[cmdletbinding()]
param(
    [Parameter(Mandatory=$false)] [string] $PathToSettingsFile = $null,
    [Parameter(Mandatory=$false)] [string] $SaveTo = $null
)

begin {
    if (!$PathToSettingsFile) {
        Write-Verbose "No path specified, defaulting to current APPDATA environment variable..."
        $PathToSettingsFile = ($env:APPDATA + "\sqlops\user\settings.json") 
        Write-Verbose "Backing up existing settings file..."
        Copy-Item -Path $PathToSettingsFile -Destination ($PathToSettingsFile + ".old")
        Write-Verbose "Path to settings = $PathToSettingsFile"
    }

    Write-Verbose "Reading current settings file..."
    $UserSettings = (get-content -Path $PathToSettingsFile -Raw | ConvertFrom-Json)
}

process {
    Import-Module SqlServer -DisableNameChecking
    $RegisteredServers = Get-ChildItem SQLSERVER:\SQLRegistration -Recurse | Where-Object {$_.ServerType -eq "DatabaseEngine"}
    $RegisteredServers.Refresh()
    $ServerGroups = $RegisteredServers | Where-Object {$_.ServerName -eq $null}
    $Servers = $RegisteredServers | Where-Object {$_.ServerName -ne $null}
    $RootConnectionGroup = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq "ROOT"}

    Write-Verbose "Getting server groups..."
    if (($UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq "ROOT"}) -eq $null) {
        Write-Warning "No root level group detected. Let's fix that, shall we?"
        $rootLevel = @()
        $rootLevel += [pscustomobject] @{
            name = "ROOT"
            id = ([guid]::NewGuid()).ToString()
        }
        $UserSettings | Add-Member -Name 'datasource.connectionGroups' -MemberType NoteProperty -Value $rootLevel | Out-Null
    }

    $RootConnectionGroup = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq "ROOT"}
    ForEach ($sg in $ServerGroups) {
        $ParentID = $RootConnectionGroup.id
        $ExistingParent = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq $sg.parent.displayname}
        if ($ExistingParent -ne $null) { 
            $ParentID = $ExistingParent.id 
        }
        $ExistingGroup = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq $sg.DisplayName}
        if ($ExistingGroup -eq $null) {
            Write-Verbose "Adding group to $parentID..."
            $ConnectionGroup = [PSCustomObject] @{
                name = $sg.DisplayName
                id = ([guid]::NewGuid()).ToString()
                parentId = $ParentID
                color = "#515151"
                description = "Imported from SSMS"
            }
            $UserSettings."datasource.connectionGroups" += $ConnectionGroup
        } else {
            $GroupName = $sg.DisplayName
            Write-Verbose "Ignoring group $GroupName because it already exists"
        }
    }

    Write-Verbose "Getting servers..."    
    if ($UserSettings."datasource.connections" -eq $null) {
        Write-Warning "No connections defined in settings file. Let's fix that, shall we?"
        $UserSettings | Add-Member -Name 'datasource.connections' -MemberType NoteProperty -Value @() | Out-Null
    }    
    ForEach ($s in $Servers) {
        $ParentID = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq $s.parent.displayname}
        Write-Output $s.name
        
        if (($UserSettings."datasource.connections" | Where-Object {$_.options.server -eq $s.ServerName -and $_.groupID -eq $ParentID.id}) -eq $null) {
            $dbUser = "";
            $dbPassword = "";
            $AuthenticationType = "Integrated"
            if ($s.authenticationType -eq 1)    
            {
                $ConnectionString = $s.ConnectionString
                $dbUser = $ConnectionString.replace(" ","").split(";")[1].split("=")[1]
                $dbPassword = $ConnectionString.replace(" ","").split(";")[2].split("=")[1]
                $AuthenticationType = "SqlLogin"
            }
            $Connection = [PSCustomObject] @{
                options = [PSCustomObject] @{
                    connectionName=$s.name
                    server=$s.ServerName
                    database="master"
                    authenticationType=$AuthenticationType
                    user=$dbUser
                    password=$dbPassword
                    applicationName="sqlops"
                    databaseDisplayName="master"
                }
                groupId = $ParentID.id
                providerName = "MSSQL"
                savePassword = $true
                id = ([guid]::NewGuid()).ToString()
            }
            $UserSettings."datasource.connections" += $Connection
        } else {
            $ServerName = $s.ServerName
            $GroupName = ($UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq $s.parent.displayname}).Name
            Write-Verbose "Already a connection to $ServerName in $GroupName, skipping..."
        }
    }
}

end {
    if (!$SaveTo) {
        $UserSettings | ConvertTo-Json -Depth 99 | Out-File -FilePath $PathToSettingsFile -Encoding "UTF8"
    } else {
        $UserSettings | ConvertTo-Json -Depth 99 | Out-File -FilePath $SaveTo -Encoding "UTF8"
    }
}