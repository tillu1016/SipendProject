#Install-Module SharePointPnPPowerShellOnline
#$url1=Read-Host -Prompt 'Site Url' 
#Connect to PnP Online
$cred=Get-Credential
Connect-PnPOnline -Url https://winwireinc.sharepoint.com/sites/SPReadiness -Credentials $cred

#Creating Countries list 
New-PnPList -Title "Countries" -Template GenericList 
#Countries list Created

#Reterving the lookup list id
$LookUpList="Countries"
$LookupListID = (Get-PnPList -Identity $LookUpList).ID
$FieldXMLCountry= "<Field Type='Lookup' Name='Country' ID='$([GUID]::NewGuid())' DisplayName='Country' List='$LookupListID' ShowField='Title'></Field>"
 
#Creating the Application Configuration List with Fields
New-PnPList -Title "ApplicationConfiguration" -Template GenericList

 write-host "ApplicationConfiguration List  created " -f Green

 Add-PnPField -List "ApplicationConfiguration" -Type Text -DisplayName "Key" -InternalName "Key" -Required -AddToDefaultView
 Add-PnPField -List "ApplicationConfiguration" -Type Note -DisplayName "Value" -InternalName "Value" -Required -AddToDefaultView
 Add-PnPField -List "ApplicationConfiguration" -Type Text -DisplayName "Type" -InternalName "Type" -AddToDefaultView
 Add-PnPFieldFromXml -FieldXml $FieldXMLCountry -List "ApplicationConfiguration" 
 Add-PnPField -List "ApplicationConfiguration" -Type Text -DisplayName "links" -InternalName "links" -AddToDefaultView 
 Add-PnPField -List "ApplicationConfiguration" -Type Text -DisplayName "ImageUrl" -InternalName "Imageurl" -AddToDefaultView
 Add-PnPField -List "ApplicationConfiguration" -Type MultiChoice -DisplayName "Role" -InternalName "Role" -Choices "Beneficiary","Manager","Reviewer", "Poweruser" -AddToDefaultView

 write-host "ApplicationConfiguration List fields created " -f Green
 #Application Configuration List with Fields created

 #Creating the PolicyConfiguration List with Fields
 New-PnPList -Title "PolicyConfiguration" -Template GenericList

 write-host "PolicyConfiguration List  created " -f Green

 Add-PnPField -List "PolicyConfiguration" -Type URL -DisplayName "PolicyDocumentUrl" -InternalName "PolicyDocUrl" -Required -AddToDefaultView
 Add-PnPField -List "PolicyConfiguration" -Type boolean -DisplayName "Active" -InternalName "Active" -Required -AddToDefaultView
 Add-PnPFieldFromXml -FieldXml $FieldXMLCountry -List "PolicyConfiguration"
 Add-PnPField -List "PolicyConfiguration" -Type Choice -DisplayName "Type" -InternalName "Type" -Required -Choices "Enrollement","Cancel" -AddToDefaultView 
 Add-PnPField -List "PolicyConfiguration" -Type MultiChoice -DisplayName "Role" -InternalName "Role" -Choices "Beneficiary","Manager","Reviewer", "Poweruser" -AddToDefaultView

 write-host "PolicyConfiguration List and fields created " -f Green
 #PolicyConfiguration List with Fields created

 #Creating the MobileDevicePlan Configuration  List with Fields
 New-PnPList -Title "MobileDevicePlanConfiguration" -Template GenericList

 write-host "MobileDevicePlan Configuration  List  created " -f Green

 Add-PnPField -List "MobileDevicePlanConfiguration" -Type Text -DisplayName "Stipend Category" -InternalName "StipendCat" -Required -AddToDefaultView
 Add-PnPField -List "MobileDevicePlanConfiguration" -Type Note -DisplayName "Stipend Description" -InternalName "StipendDes" -Required -AddToDefaultView
 Add-PnPField -List "MobileDevicePlanConfiguration" -Type Text -DisplayName "Monthly Amount" -InternalName "MonthlyAmt" -Required -AddToDefaultView 
 Add-PnPFieldFromXml -FieldXml $FieldXMLCountry -List "MobileDevicePlanConfiguration"
 Add-PnPField -List "MobileDevicePlanConfiguration" -Type boolean -DisplayName "Active" -InternalName "Active" -Required -AddToDefaultView
 write-host "MobileDevicePlan Configuration  List and fields created " -f Green
 #PolicyConfiguration List with Fields created

  #Creating the Email Templates List with Fields
 New-PnPList -Title "EmailTemplates" -Template GenericList

 write-host " Email Templates  List  created " -f Green

 Add-PnPField -List "EmailTemplates" -Type Text -DisplayName "EmailSubject" -InternalName "Emailsub" -Required -AddToDefaultView
 Add-PnPField -List "EmailTemplates" -Type Note -DisplayName "EmailBody" -InternalName "Emailbody" -Required -AddToDefaultView
 Add-PnPField -List "EmailTemplates" -Type Text -DisplayName "NotificationType" -InternalName "NotificationType" -Required -AddToDefaultView 
  Add-PnPField -List "EmailTemplates" -Type Text -DisplayName "To" -InternalName "To" -Required -AddToDefaultView
 Add-PnPField -List "EmailTemplates" -Type Text -DisplayName "CC" -InternalName "CC" -AddToDefaultView
 write-host  "Email Templates  List and fields created " -f Green
 # Email Templates List with Fields created

  #Creating the Email Templates List with Fields
 New-PnPList -Title "StipendRequest" -Template GenericList

 $FieldXMLBeneficiary= "<Field Type='User' Name='Beneficiary' ID='$([GUID]::NewGuid())' DisplayName='Beneficiary' Required ='TRUE' UserSelectionMode='PeopleOnly'></Field>"
 $FieldXMLReviewer= "<Field Type='User' Name='Reviewer' ID='$([GUID]::NewGuid())' DisplayName='Reviewer' UserSelectionMode='PeopleOnly'></Field>"
 $FieldXMLManager= "<Field Type='User' Name='Manager' ID='$([GUID]::NewGuid())' DisplayName='Manager' UserSelectionMode='PeopleOnly'></Field>"
 $FieldXMLHomeCountry= "<Field Type='Lookup' Name='HomeCountry' ID='$([GUID]::NewGuid())' DisplayName='Beneficiary Home Country' List='$LookupListID' ShowField='Title'></Field>"
 $FieldXMLCurrentCountry= "<Field Type='Lookup' Name='CurrentCountry' ID='$([GUID]::NewGuid())' DisplayName='Beneficiary Current Country' List='$LookupListID' ShowField='Title'></Field>"
 
 write-host " StipendRequest  List  created " -f Green
 Add-PnPFieldFromXml -List "StipendRequest" -FieldXml $FieldXMLBeneficiary
 Add-PnPField -List "StipendRequest" -Type Choice -DisplayName "Beneficiary Type" -InternalName "BeneficiaryType" -Required -Choices "Sales","Marketing","Purchase", "IT", "HR" -AddToDefaultView
 Add-PnPField -List "StipendRequest" -Type Text -DisplayName "Beneficiary Job Grade" -InternalName "BeneficiaryJobgd" -Required -AddToDefaultView
 Add-PnPField -List "StipendRequest" -Type Text -DisplayName "Beneficiary Department" -InternalName "BeneficiaryDept" -Required -AddToDefaultView 
 Add-PnPFieldFromXml -FieldXml $FieldXMLHomeCountry -List "StipendRequest" 
 Add-PnPFieldFromXml -FieldXml $FieldXMLCurrentCountry -List "StipendRequest"
  Add-PnPField -List "StipendRequest" -Type Text -DisplayName "Stipend Category" -InternalName "StipendCat" -Required -AddToDefaultView
 Add-PnPField -List "StipendRequest" -Type Number -DisplayName "Stipend Amount" -InternalName "StipendAmt" -Required -AddToDefaultView
 Add-PnPField -List "StipendRequest" -Type boolean -DisplayName "Agreement Accepted" -InternalName "AgreementAccepted" -Required -AddToDefaultView 
  Add-PnPField -List "StipendRequest" -Type Date -DisplayName "Request Date" -InternalName "RequestDt" -Required -AddToDefaultView
 Add-PnPField -List "StipendRequest" -Type Choice -DisplayName "Request Type" -InternalName "RequestType" -Required -Choices "Enroll","Update","Cancel" -AddToDefaultView
 Add-PnPField -List "StipendRequest" -Type Choice -DisplayName "Status" -InternalName "Status" -Required -Choices "In Progress","Approved","Rejected","Cancelled","Auto-Approve" -AddToDefaultView
 Add-PnPField -List "StipendRequest" -Type boolean -DisplayName "IsActive" -InternalName "IsActive" -Required -AddToDefaultView 
 Add-PnPField -List "StipendRequest" -Type Date -DisplayName "Approval Reject Date" -InternalName "ApproveRejectDt" -AddToDefaultView 
Add-PnPFieldFromXml -List "StipendRequest" -FieldXml $FieldXMLReviewer
Add-PnPFieldFromXml -List "StipendRequest" -FieldXml $FieldXMLManager
Add-PnPField -List "StipendRequest" -Type Note -DisplayName "PolicyDocumentUrl" -InternalName "PolicyDocUrl"  -AddToDefaultView 
Add-PnPField -List "StipendRequest" -Type Note -DisplayName "Comments" -InternalName "Comments"  -AddToDefaultView 
 write-host  "StipendRequest  List and fields created " -f Green
 # Stipend Request List with Fields created









    


