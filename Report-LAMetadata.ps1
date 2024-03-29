<#
.SYNOPSIS
    Script to help analyizing compliance of the data collected.
.DESCRIPTION
    Script to help analyizing compliance of the data collected.
.EXAMPLE
    .\Report-LAMetadata.ps1 -ExportPath C:\Temp\LASchema -Verbose -TenantId xxxx -SubscriptionID yyyyy -logAnalyticsWorkspaceId ttttttt -SampleCount 10
    
    VERBOSE: [1/17/2021 4:09:16 PM] Script Started.
    VERBOSE: Started Working on oms/ChangeTracking with 2 tables which will be saved into 'C:\Temp\LASchema\Change Tracking.xlsx'
    VERBOSE: Querying metadata and sampledata for table ConfigurationChange with ID t/ConfigurationChange
    VERBOSE: Invoking query: 'ConfigurationChange | take 10'
    VERBOSE: Querying metadata and sampledata for table ConfigurationData with ID t/ConfigurationData
    VERBOSE: Invoking query: 'ConfigurationData | take 10'
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
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionID,
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
        [string]$logAnalyticsWorkspaceId
    )

$headers = @{
    'Authorization' = "Bearer $LogAnalyticsToken"
    'Content-Type' = 'application/json'
}
    $logAnalyticsBaseURI = "https://api.loganalytics.io/v1/workspaces"
    invoke-RestMethod -method Get -uri "$($logAnalyticsBaseURI)/$($logAnalyticsWorkspaceId)/metadata" -Headers $headers
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
Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionID | Out-Null
$Metadata = Get-LAMetadata -TenantId $TenantId -logAnalyticsWorkspaceId $logAnalyticsWorkspaceId

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
            "$($SheetPrefix)_Data" = {Get-TableSampleData -TableName $TableName -SampleCount $SampleCount }
        }
        Export-MultipleExcelSheets -AutoSize $Path $DataToExort
    }
    Write-verbose "Ended Working on $($TableGroup.id)."
}
Write-Verbose "[$(Get-Date -Format G)] Script Ended.Duration: $([Math]::Round(((Get-date)-$ScriptStart).TotalSeconds)) seconds."