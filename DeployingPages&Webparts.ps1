$siteCollectionURL = "https://winwireinc.sharepoint.com/sites/GileadESRDev"
$credentials =  (Get-Credential)
Connect-PnPOnline -Url $siteCollectionURL -Credentials $credentials

$csvInput = Import-Csv D:\ModernPages\createModernPage.csv 

foreach ($input in $csvInput) {

$pageExisit=Get-PnPClientSidePage $input.PageName
if($pageExisit -and ($input.PageName=$pageExisit.PageTitle))
{


 Add-PnPClientSideWebPart -Page $input.PageName -DefaultWebPartType $input.WebPartName 
 Set-PnPClientSidePage -Identity $input.PageName  -Publish:$true

  }
    else
    {
    Add-PnPClientSidePage -Name $input.PageName -CommentsEnabled:$false     
    Add-PnPClientSidePageSection -Page $input.PageName -SectionTemplate $input.SectionTemplate
    Add-PnPClientSideWebPart -Page $input.PageName -DefaultWebPartType $input.WebPartName 
    $pageExisit.
    }
}
 
 Set-PnPClientSidePage -Identity "Enroll1" - -ClearSubscopes 

 Set-PnPList -
 