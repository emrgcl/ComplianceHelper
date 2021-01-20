<#
.SYNOPSIS
    Script to help analyizing compliance of the data collected.
.DESCRIPTION
    Script to help analyizing compliance of the data collected.
.EXAMPLE
    .\Report-LAMetadata.ps1 -ExportPath C:\Temp\LASchema -Verbose -TenantId xxxx -AppId yyyyy -logAnalyticsWorkspaceId zzzzzz -AppSecret GZxxx -SampleCount 10
    
    VERBOSE: [1/17/2021 4:09:16 PM] Script Started.
    WARNING: TenantId '72f988bf-86f1-41af-91ab-2d7cd011db47' contains more than one active subscription. First one will be selected for further use. To select another subscription, use Set-AzContext.
    WARNING: Unable to acquire token for tenant '11da1590-20b4-4904-9318-a727a2a59a24'
    VERBOSE: POST https://login.microsoftonline.com/72f988bf-86f1-41af-91ab-2d7cd011db47/oauth2/token with -1-byte payload
    VERBOSE: received 1418-byte response of content type application/json; charset=utf-8
    VERBOSE: GET https://api.loganalytics.io/v1/workspaces/4d7a58f4-dea3-4478-bc0d-c33542a77425/metadata with 0-byte payload
    VERBOSE: received 418084-byte response of content type application/json; charset=utf-8
    VERBOSE: Started Working on oms/ChangeTracking with 2 tables which will be saved into 'C:\Temp\LASchema\Change Tracking.xlsx'
    VERBOSE: Querying metadata and sampledata for table ConfigurationChange with ID t/ConfigurationChange
    VERBOSE: Invoking query: 'ConfigurationChange | take 100'
    VERBOSE: Querying metadata and sampledata for table ConfigurationData with ID t/ConfigurationData
    VERBOSE: Invoking query: 'ConfigurationData | take 100'
    .
    .
    .
    .
    VERBOSE: Querying metadata and sampledata for table VMProcess with ID t/VMProcess
    VERBOSE: Invoking query: 'VMProcess | take 100'
    VERBOSE: Ended Working on oms/VMInsights.
    VERBOSE: [1/17/2021 4:21:10 PM] Script Ended.Duration: 714 seconds.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]    
    [string]$TenantId,
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    [Parameter(Mandatory=$true)]
    [string]$AppSecret,
    [Parameter(Mandatory=$true)]
    [string]$logAnalyticsWorkspaceId,
    [ValidateScript({Test-Path $_})]
    [Parameter(Mandatory=$true)]
    [string]$ExportPath,
    [int32]$SampleCount=10

)
function Export-MultipleExcelSheets {
    <#
        .Synopsis
        Takes a hash table of scriptblocks and exports each as a sheet in an Excel file    

        .Example
$p = Get-Process

$InfoMap = @{
    PM                 = { $p | Select-Object company, pm }
    Handles            = { $p | Select-Object company, handles }
    Services           = { Get-Service }
}

Export-MultipleExcelSheets -Path $xlfile -InfoMap $InfoMap -Show -AutoSize        
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Path,
        [Parameter(Mandatory = $true)]
        [hashtable]$InfoMap,
        [Switch]$Show,
        [Switch]$AutoSize
    )

    $parameters = @{ } + $PSBoundParameters
    $parameters.Remove("InfoMap")
    $parameters.Remove("Show")

    $parameters.Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    foreach ($entry in $InfoMap.GetEnumerator()) {
        if ($entry.Value -is [scriptblock]) {
            Write-Progress -Activity "Exporting" -Status "$($entry.Key)"
            $parameters.WorkSheetname = $entry.Key

            & $entry.Value | Export-Excel @parameters
        }
        else {
            Write-Warning "$($entry.Key) not exported, needs to be a scriptblock"
        }
    }

    if ($Show) { Invoke-Item $Path }
}
Function Get-LAMetadata {
    [CmdletBinding()]
    Param(
        [string]$TenantId,
        [string]$AppId,
        [string]$AppSecret,
        [string]$logAnalyticsWorkspaceId
    )
        $loginURL = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        $resource = "https://api.loganalytics.io"
    
    $authbody = @{
        grant_type = "client_credentials"
        resource = $resource
        client_id = $AppId
        client_secret = $AppSecret 
    }
    
    $oauth = Invoke-RestMethod -Method Post -Uri $loginURL -Body $authbody
    $headerParams = @{'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }
    $logAnalyticsBaseURI = "https://api.loganalytics.io/v1/workspaces"
    invoke-RestMethod -method Get -uri "$($logAnalyticsBaseURI)/$($logAnalyticsWorkspaceId)/metadata" -Headers $headerParams
}
Function Get-TableMetadata {
    [CmdletBinding()]
    Param(
        $Metadata,
        $TableID
    )
    $Metadata.Tables.where({$_.ID -eq $TableID}).Columns | Select-Object -Property Name,Type,Description
}
Function Get-TableSampleData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$TableName,
        [Parameter(Mandatory=$true)]
        [int32]$SampleCount
    )
    $Query = "$TableName | take $SampleCount"
    Write-Verbose "Invoking query: '$Query'"
    (Invoke-AzOperationalInsightsQuery -WorkspaceId $logAnalyticsWorkspaceId -Query $Query).Results
}
Function Truncate-String {

    Param(
        [string]$String,
        [int32]$Length 

    )

    If ($String.Length -gt $Length) {
        $string.Substring(0,$Length)
    } else {$string}
}


# Script Main Starts Here
$ScriptStart = Get-Date
Write-Verbose "[$(Get-Date -Format G)] Script Started."

#Requires -Module @{ModuleName='Az.Accounts';ModuleVersion ='2.2.3'},@{ModuleName='Az.OperationalInsights';ModuleVersion ='2.1.0'},@{ModuleName='ImportExcel';ModuleVersion ='7.1.1'}
Connect-AzAccount | Out-Null
$Metadata = Get-LAMetadata -TenantId $TenantId -AppId $AppId -logAnalyticsWorkspaceId $logAnalyticsWorkspaceId -AppSecret $AppSecret

Foreach ($TableGroup in $Metadata.tableGroups) {
    # SomeGroups dont have displayname use name instead
    if($TableGroup.Displayname) {

        $FileName = $TableGroup.displayName

    } else {
        $FileName = $TableGroup.name
    }
    
    $TableIDs = $TableGroup.Tables
    $Path = "$ExportPath\$FileName.xlsx"
    Write-verbose "Started Working on $($TableGroup.id) with $($TableGroup.Tables.Count) tables which will be saved into '$Path'"

    Foreach ($TableID in $TableIDs) {
        
        $TableName = $Metadata.tables.Where({$_.Id -eq $TableID}).Name
        # Setting the sheetprefix so that sheetname cannot be greater than excels limit for a sheetname
        $SheetPrefix = Truncate-String -String $TableName -Length 24
        Write-Verbose "Querying metadata and sampledata for table $TableName with ID $TableID"
        $DataToExort = @{

            "$($SheetPrefix)_Schema" = {Get-TableMetadata -Metadata $Metadata -TableId $TableID}
            "$($SheetPrefix)_Data" = {Get-TableSampleData -TableName $TableName -SampleCount 100}
        }
        Export-MultipleExcelSheets -AutoSize $Path $DataToExort
    }
    Write-verbose "Ended Working on $($TableGroup.id)."
}
Write-Verbose "[$(Get-Date -Format G)] Script Ended.Duration: $([Math]::Round(((Get-date)-$ScriptStart).TotalSeconds)) seconds."