Param(
 [Parameter(Mandatory=$true)]
 [string]$SiteUrl,
 [Parameter(Mandatory=$false)]
 [string]$XMLTermsFileName = "_ListSchema.xml"
 )
 
 
 Set-Location $PSScriptRoot

 function LoadAndConnectToSharePoint($url)
 {
	
  ##Using PnP library
  Connect-PnPOnline -Url $SiteUrl -Credentials (Get-Credential) #-UseWebLogin
  #Connect-SPOnline -Url $SiteUrl -CurrentCredentials
  #$spContext =  Get-SPOContext
  $spContext =  Get-PnPContext
  return $spContext
}

$Context = LoadAndConnectToSharePoint  $SiteUrl


$ESRALists = "Countries",
"Application Configuration",
"Mobile Device Plan Configuration",
"Email Templates",
"Policy Configuration",
"Stipend Request",
"Payroll Reports"

#Get the List schema as Template and export to a File
$Templates = Get-PnPProvisioningTemplate -OutputInstance -Handlers Lists -ListsToExtract $ESRALists
#$ListTemplate = $Templates.Lists | Where-Object {$ListsToExport -contains $_.Title}
$ListTemplates = $Templates.Lists
 
Save-PnPProvisioningTemplate -InputInstance $Templates -Out $XMLTermsFileName

Add-PnPDataRowsToProvisioningTemplate -Path $XMLTermsFileName -List 'Countries' -Query '<View></View>' -Fields 'Title','Currency','Active','CountryName' -IncludeSecurity
Add-PnPDataRowsToProvisioningTemplate -Path $XMLTermsFileName -List 'Application Configuration' -Query '<View></View>' -Fields 'Key','Value','Country','Role','ConfigType','Description' -IncludeSecurity
Add-PnPDataRowsToProvisioningTemplate -Path $XMLTermsFileName -List 'Mobile Device Plan Configuration' -Query '<View></View>' -Fields 'StipendCategory','StipendDescription','MonthlyAmount','Country','Active' -IncludeSecurity
Add-PnPDataRowsToProvisioningTemplate -Path $XMLTermsFileName -List 'Email Templates' -Query '<View></View>' -Fields 'EmailSubject','EmailBody','NotificationType','CC','To','Description','ToBeSent','Title' -IncludeSecurity
Add-PnPDataRowsToProvisioningTemplate -Path $XMLTermsFileName -List 'Policy Configuration' -Query '<View></View>' -Fields 'PolicyDocumentUrl','Active','PolicyType','Role','To','Country','TnCPolicyContent' -IncludeSecurity










