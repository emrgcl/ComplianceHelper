# Log Analytics Compliance Helper

The script is developed to help analyzing the collected data compliance. The script runs for the desired worksapce, pulls the table schema for each solution (Table Groups) along with sample data and exports the results int o excel sheets per Solution.

Every Table has two sheets,

1. **Schema:** This sheet includes the column information, including name, type and description.
    ![Schema Sheet](/images/schemasheet.png)
1. **Data:** Sample data to help better analyizing compliancy. 
    ![Data Sheet](/images/datasheet.png)

# Important Note & disclaimer
This script is just a helper, the data might be missing or incomplete and does not intend to meet any regulatory but is a tool to help understanding what the collected data is.

# How to Run the script

 ## Parameters Explained
|Parameter| Notes|
|-----|----|
|TenantID|Pretty self explanatory. The ID of the Tenant|
|SubscriptionID|Pretty self explanatory. The ID of the Subscription|
|logAnalyticsWorkspaceId|Pretty self explanatory. The ID of the Workspace|
|Exportpath| Where to export the files?. IT should be better to specify an empty folder|
|SampleCount| defaults to 100, specify if more or less number of rows needed|  

## Sample Execution
A sample execution is as below. Script has verbose logging option which allows quick troubleshooting.



```
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
```



# Requirements

## Rbac
You need to be a log analytics contributor

## Required Modules

The script requires the following modules. Please install them if not already installed before running the script.
- Powershell 7 and above
- Az.accounts (2.2.3 and above)
- Az.OperationalInsights (2.1.0 and above)
- ImportExcel (7.1.1 and above)

