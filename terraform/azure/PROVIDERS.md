# Providers

Ensure that for each subscription used for the deployment that the following providers are enabled for that subscription:

```
Microsoft.AppConfiguration
Microsoft.DBforMariaDB
Microsoft.Management
Microsoft.MixedReality
Microsoft.Devices
Microsoft.DevTestLab
Microsoft.Search
Microsoft.DataFactory
Microsoft.MachineLearningServices
Microsoft.Kusto
Microsoft.DBforPostgreSQL
Microsoft.Cache
Microsoft.ResourceHealth
Microsoft.ManagedIdentity
Microsoft.ContainerRegistry
Microsoft.DocumentDB
Microsoft.DataLakeStore
Microsoft.PowerBIDedicated
Microsoft.ContainerService
Microsoft.HealthcareApis
Microsoft.CustomProviders
Microsoft.Cdn
Microsoft.ServiceBus
Microsoft.NotificationHubs
Microsoft.AppPlatform
Microsoft.OperationalInsights
Microsoft.Maps
Microsoft.TimeSeriesInsights
Microsoft.Media
microsoft.insights
Microsoft.Automation
Microsoft.Security
Microsoft.Logic
Microsoft.AVS
Microsoft.DataProtection
Microsoft.StreamAnalytics
Microsoft.Maintenance
Microsoft.PolicyInsights
Microsoft.Relay
Microsoft.Blueprint
Microsoft.SignalRService
Microsoft.DataMigration
Microsoft.EventGrid
Microsoft.GuestConfiguration
Microsoft.KeyVault
Microsoft.BotService
Microsoft.SecurityInsights
Microsoft.DataLakeAnalytics
Microsoft.ManagedServices
Microsoft.ContainerInstance
Microsoft.OperationsManagement
Microsoft.DesktopVirtualization
Microsoft.EventHub
Microsoft.Databricks
Microsoft.RecoveryServices
Microsoft.CognitiveServices
Microsoft.ServiceFabric
Microsoft.Storage
Microsoft.Web
Microsoft.HDInsight
Microsoft.Compute
Microsoft.ApiManagement
Microsoft.Network
Microsoft.Sql
Microsoft.DBforMySQL
Microsoft.Advisor
Microsoft.CloudShell
Microsoft.App
Microsoft.ADHybridHealthService
Microsoft.Authorization
Microsoft.Billing
Microsoft.ClassicSubscription
Microsoft.Commerce
Microsoft.Consumption
Microsoft.CostManagement
Microsoft.Features
Microsoft.MarketplaceOrdering
Microsoft.Portal
Microsoft.ResourceGraph
Microsoft.ResourceNotifications
Microsoft.Resources
Microsoft.SerialConsole
microsoft.support
```

In the case these providers are not registered the following error and resolution applies: 
https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider?tabs=azure-cli#code-try-3.

Scripting for multiple subscription can be done via the az cloudshell as follows, where `providers.txt` contains the providers listed above:
```
for s in $(echo subscriptionName1 subscriptionName2); do echo "setting subscription: $s"; az account set --subscription $s; for p in $(cat providers.txt); do echo "enabling provider $p"; az provider register --namespace $p; done; done
```

