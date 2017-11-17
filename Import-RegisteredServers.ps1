[cmdletbinding()]
param(
    [Parameter(Mandatory=$false)] [string] $PathToSettingsFile = $null,
    [Parameter(Mandatory=$false)] [string] $SaveTo = $null
)

begin {
    if ($PathToSettingsFile -eq $null) {
        Write-Verbose "No path specified, defaulting to current APPDATA environment variable..."
        $PathToSettingsFile = ($env:APPDATA + "\sqlops\user\settings.json") 
        Write-Verbose "Backing up existing settings file..."
        Copy-Item -Path $PathToSettingsFile -Destination ($PathToSettingsFile + ".old")
    }
}

process {
    Write-Verbose "Reading current settings file..."
    $UserSettings = get-content -Path $PathToSettingsFile -Raw | ConvertFrom-Json


    $RegisteredServers = Get-ChildItem SQLSERVER:\SQLRegistration -Recurse | Where-Object {$_.ServerType -eq "DatabaseEngine"}
    $RegisteredServers.Refresh()
    $ServerGroups = $RegisteredServers | Where-Object {$_.ServerName -eq $null}
    $Servers = $RegisteredServers | Where-Object {$_.ServerName -ne $null}
    
    $RootConnectionGroup = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq "ROOT"}

    Write-Verbose "Getting server groups..."
    ForEach ($sg in $ServerGroups) {
        $ParentID = $RootConnectionGroup.id
        $ExistingParent = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq $sg.parent.displayname}
        if ($ExistingParent -ne $null) { 
            $ParentID = $ExistingParent.id 
        }
        $ConnectionGroup = [PSCustomObject] @{
            name = $sg.DisplayName
            id = ([guid]::NewGuid()).ToString()
            parentId = $ParentID
            color = "#ededed"
            description = "Imported from SSMS"
        }
        $UserSettings."datasource.connectionGroups" += $ConnectionGroup
    }

    Write-Verbose "Getting servers..."    
    ForEach ($s in $Servers) {
        $ParentID = $UserSettings."datasource.connectionGroups" | Where-Object {$_.Name -eq $s.parent.displayname}        
        $Connection = [PSCustomObject] @{
            options = [PSCustomObject] @{
                server=$s.ServerName
                database="master"
                authenticationType="Integrated"
                user=""
                password=""
                applicationName="sqlops"
                databaseDisplayName="master"
            }
            groupId = $ParentID.id
            providerName = "MSSQL"
            savePassword = $true
            id = ([guid]::NewGuid()).ToString()
        }
        $UserSettings."datasource.connections" += $Connection
    }
}

end {
    if ($SaveTo -eq $null) {
        $UserSettings | ConvertTo-Json -Depth 99 | Out-File -FilePath $PathToSettingsFile -Encoding "UTF8"
    } else {
        $UserSettings | ConvertTo-Json -Depth 99 | Out-File -FilePath $SaveTo -Encoding "UTF8"
    }
}