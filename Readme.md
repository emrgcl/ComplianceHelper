# Log Analytics Compliance Helper

The script is developed to help analyzing the collected data compliance. The script runs for the desired worksapce, pulls the table schema for each solution (Table Groups) along with sample data and exports the results int o excel sheets per Solution.

Every Table has two sheets,

1. **Schema:** This sheet includes the column information, including name, type and description.
    ![Schema Sheet](/Scripts/Report-LAMetaData/images/schemasheet.png)
1. **Data:** Sample data to help better analyizing compliancy. 
    ![Data Sheet](/Scripts/Report-LAMetaData/images/datasheet.png)

# Important Note & disclaimer
This script is just a helper, the data might be missing or incomplete and does not intend to meet any regulatory but is a tool to help understanding what the collected data is.

# How to Run the script

A sample exuection is as below. Script has verbose logging option which allows quick troubleshooting.

```
    .\Report-LAMetadata.ps1 -ExportPath C:\Temp\LASchema -Verbose -TenantId xxxx -AppId yyyyy -logAnalyticsWorkspaceId zzzzzz -AppSecret GZxxx -SampleCount 10
    
    VERBOSE: [1/17/2021 4:09:16 PM] Script Started.
    WARNING: TenantId 'xxxx' contains more than one active subscription. First one will be selected for further use. To select another subscription, use Set-AzContext.
    WARNING: Unable to acquire token for tenant '11da1590-20b4-4904-9318-a727a2a59a24'
    VERBOSE: POST https://login.microsoftonline.com/xxxx/oauth2/token with -1-byte payload
    VERBOSE: received 1418-byte response of content type application/json; charset=utf-8
    VERBOSE: GET https://api.loganalytics.io/v1/workspaces/zzzzzz/metadata with 0-byte payload
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
```

|Parameter| Notes|
|-----|----|
|TenantID|Pretty self explanatory. The ID of the Tenant|
|AppID| the id of the app registeration. Please see App Registeration in Requirements below.|
|AppSecret| the client scret created for the Application. Please see App Registeration in Requirements below.|
|logAnalyticsWorkspaceId|Pretty self explanatory. The ID of the Workspace|
|Exportpath| Where to export the files?. IT should be better to specify an empty folder|
|SampleCount| defaults to 100, specify if more or less number of rows needed|  

# Requirements

## App Registeration
One of the API's in the script utilizes appid and secrets created for the id 
1. Create an appregistration in portal
1. Note the "Application (Client) ID" in Overivew.
1. Create a secret and note the secret (we will use as a paramter to the script.)
    1. Create new client secret under "Certificates & Secrets"
    1. Collect the value immediately. only visible during the creation.
1. In the resource group access control grant Log Analytics Contributor for the created Application  

## Required Modules

The script requires the following modules. Please install them if not already installed before runnign the script.

- Az.accounts
- Az.OperationalInsights
- ImportExcel

