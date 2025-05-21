Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#region Variable/Constants 
$ProgressPreference = "SilentlyContinue"  
$O365SiteUrl = "https://gileadconnect.sharepoint.com/sites/GAppsTest-ESRA"
$username = "ESRAScheduledJob-Staging@na.gilead.com"
$password = 'Q2gg!3Ud@123' 
$StipendListName = "Stipend Request" 
$EmailListName = "Email Templates" 
$error_msg = '' 
$ConfigListName = 'Application Configuration' 
$EmailFrom = "noreply@gilead.com" 
$MailUserName = "ESRAScheduledJob-Sta" 
$MailPassword = 'Q2gg!3Ud@123' 
$EMailTobesent = ""    
$msg = ""
$EmailFromText = '';
$Attachmenturl = '';
$ExpirationMonths = $null;
$ExpiredUserComments = '';
#Get the current date
$LogDate = (Get-Date).tostring("yyyyMMdd")
$REEnrollmentpageurl = ""
#endregion

#region  function  
# handle null string and return "" if it is null
function getStringValue {  
    param ( [string]$str
    )

    if ([string]::IsNullOrEmpty($str)) {
        return ""
    }
    else {
        return $str
    }
}

#decode html entitie
function get_DecodeHtml() {
    param
    (
        [Parameter(Mandatory = $true)] [string] $StringValue
    )
    $str = [System.Web.HttpUtility]::HtmlDecode($StringValue)
    return  $str
}
#create log file and add logs 
function LogMessage() {
    param
    (
        [Parameter(Mandatory = $true)] [string] $Message
    )

    Try {
   
        #Get the Location of the script
        If ($psise) {
            $CurrentDir = Split-Path $psise.CurrentFile.FullPath
        }
        Else {
            $CurrentDir = $Global:PSScriptRoot
        }
        #Frame Log File with Current Directory and date
        $LogFile = $CurrentDir + "\ADUser_" + $LogDate + ".log"
        #Add Content to the Log File
        $TimeStamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss:fff tt")
        $Line = "$TimeStamp - $Message"
        Add-content -Path $Logfile -Value $Line

        #Write-host "Message: '$Message' Has been Logged to File: $LogFile"
    }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message 
    }
}

#send email with attachement 
function Send-Email {
    param (      
        [string]$EmailTo  ,
        [string] $Subject ,
        [string] $body ,
        $attachment
    )
    Try {                 
        #region send email 
        $message = new-object System.Net.Mail.MailMessage
        $frommail = new-object System.Net.Mail.MailAddress($EmailFrom , $EmailFromText)
        $message.From = $frommail
        $message.To.Add($EmailTo)
        $message.IsBodyHtml = $True
        $message.Subject = $Subject
        if ($attachment -and $attachment -ne '') {
            foreach ($mailfile in $attachment) {
                $attach = new-object Net.Mail.Attachment($mailfile)
                $message.Attachments.Add($attach)
            }
        }
        $message.body = $body
        $smtp = new-object Net.Mail.SmtpClient($smtpserver, 587)
        #  $smtp.EnableSsl = $true
        $smtp.Credentials = New-Object System.Net.NetworkCredential($MailUserName, $MailPassword);
       # $smtp.Send($message)
        #endregion  
    }
    Catch {
        Write-Output $_.Exception.Message
        LogMessage  $_.Exception.Message
    }
} 
 
#send disabled email from email template list
function Send-DisabledEmail {
    param (
        [string]$Notificationtype  ,
        [string]$MailMsg ,
        [string]$attachment,
        [string]$country
        
    )
    Try {
       
        $message = new-object System.Net.Mail.MailMessage
        if ($attachment -and $attachment -ne '') {
            $attach = new-object Net.Mail.Attachment($attachment)
            $attach.ContentDisposition.FileName = $EmailFile
            $message.Attachments.Add($attach)
        }
        $message.IsBodyHtml = $True
        if ($country -and $country -ne "") {
            $query = "<View><Query><Where>
            <And>
                <Eq><FieldRef Name='NotificationType'/><Value Type='Text'>"+ $Notificationtype + "</Value></Eq>
                <Eq><FieldRef Name='Country'/><Value Type='Lookup'>"+ $country + "</Value></Eq>
            </And>
                </Where></Query></View>"
        }
        else {
            $query = "<View><Query><Where><Eq><FieldRef Name='NotificationType'/><Value Type='Text'>" + $Notificationtype + "</Value></Eq></Where></Query></View>"
        }

        $emailitems = Get-PnPListItem -List $EmailListName -Query $query -ErrorAction Stop
        $mailsent = $false
        Foreach ($emailitem in $emailitems) {
            #to stop multiple email in case any exception
            if (!$mailsent) { 
                $EMailTobesent = $emailitem["ToBeSent"]
                if ($EMailTobesent -eq "Yes") {     
                    $EmailTO = $emailitem["To"]
                    $EmailTO = getStringValue -str $EmailTO
                    $EmailTOArray = $EmailTO.Split(",")
                    foreach ($email in $EmailTOArray) {
                        $EmailTO = $email
                        if ($EmailTO.Contains('@')) {
                            $message.To.Add($EmailTo)
                        }
                        else {
                            try {
                                if ($EmailTO -ne '') {
                                    $usersColl = Get-PnPGroup  -Identity $EmailTO | Select-Object Users 
                                    foreach ($usr in $usersColl.users) {
                                        try {
                                            $message.To.Add($usr.Email)                                  
                                        }
                                        catch {
                                            LogMessage $_.Exception.ToString() 
                                        } 
                                    }                                 
                                }
                            }
                            catch {
                                LogMessage $_.Exception.ToString() 
                            }
                        }
                    } 
                    $CC = $emailitem["CC"]
                    $CC = getStringValue -str $CC
                    $CCArray = $CC.Split(",")
                    foreach ($ccemail in $CCArray) {
                        $CC = $ccemail
                        if ($CC.Contains('@')) {
                            $message.CC.Add($CC)
                        }
                        else {
                            try {
                                if ($CC -ne '') {
                                    $users = Get-PnPGroup  -Identity $CC | Select-Object Users 
                                
                                    foreach ($usr in $users.users) {
                                        try {
                                            $message.CC.Add($usr.Email)                                  
                                        }
                                        catch {
                                            LogMessage $_.Exception.ToString() 
                                        } 
                                    } 
                                }
                            }
                            catch {
                                LogMessage $_.Exception.ToString() 
                            }
                        } 
                    }
                    $EmailBody = $emailitem["EmailBody"]
                    $EmailSubject = $emailitem["EmailSubject"]
                    $EmailBody = [System.Web.HttpUtility]::HtmlDecode($EmailBody)
                    $EmailSubject = [System.Web.HttpUtility]::HtmlDecode($EmailSubject) 
                    $EmailBody = $EmailBody.Replace('ERRORDETAILS', $MailMsg )
                    $EmailBody = $EmailBody.Replace('ERRORMESSAGE', $MailMsg )
                    $EmailBody = $EmailBody.Replace('MONTHYEAR', $MailMsg ) 
                    $EmailBody = $EmailBody.Replace('USERDATA', $MailMsg )  

                    $frommail = new-object System.Net.Mail.MailAddress($EmailFrom , $EmailFromText)
                    $message.From = $frommail

                    $message.Subject = $EmailSubject
                    $message.body = $EmailBody
                    $smtp = new-object Net.Mail.SmtpClient($smtpserver, 587)
                    #$smtp.EnableSsl = $true
                    $smtp.Credentials = New-Object System.Net.NetworkCredential($MailUserName, $MailPassword);
                    $smtp.Send($message)
                    LogMessage "Mail sent for notification type $Notificationtype"  
                    $mailsent = $true
                }   
            }         
        }
    }
    Catch {
        LogMessage "Mail may not been sent. Please review following error"
        LogMessage $_.Exception.ToString() 
    }
}


#get Domain controller name to search the User in AD
function get-ServerName() {
    param ([string]$ADPath     )

    $dcAray = $ADPath.Split(',');
    $searchstring = ""
    foreach ($tmpitem in $dcAray) {
        if ($tmpitem.Substring(0, 3) -eq "DC=") {
            if ($searchstring -eq "") {
                $searchstring = $tmpitem.Split('=')[1]            
            }
            else {
                $searchstring = $searchstring + "." + $tmpitem.Split('=')[1]
            }      
        }
    }
    return  $searchstring 
}

 
function Get-UserslistToAddIntoAD {
    param(
        $ListItemAll
    )
    Try {
        $SecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential($username, $SecurePassword)
        Connect-PnPOnline -Url $O365SiteUrl -Credentials $credentials -WarningAction Ignore  
        #region get emailtemplate 
        $query = "<View><Query><Where>
                            <Eq><FieldRef Name='NotificationType'/><Value Type='Text'>ADUserAddSuccess</Value></Eq>
                        </Where></Query></View>"
        $emailitems = Get-PnPListItem -List $EmailListName -Query $query
        Foreach ($emailitem in $emailitems) { 
            $emailbody = $emailitem["EmailBody"]         
            $emailSubject = $emailitem["EmailSubject"]
            $EMailTobesent = $emailitem["ToBeSent"]
        } 
        #endregion

        <#commening the email code as it will move to seperate job ADDRemoveSendEmail.ps1 #>
        <#
        #region get attachment file
        try {
            if ($Attachmenturl) {
                try {
                    LogMessage "Getting Attachments "
                    #connect ot url to get the instruction files
                    Connect-PnPOnline -Url $MobileDocumentsUrl -Credentials $credentials -WarningAction Ignore  
                    $AttachmenturlAry = $Attachmenturl.Split(',')
                    If ($psise) {
                        $CurrentDir = Split-Path $psise.CurrentFile.FullPath
                    }
                    Else {
                        $CurrentDir = $Global:PSScriptRoot
                    }
                    $fileurlary = [System.Collections.ArrayList]@()
                      
                    foreach ($fileurl in $AttachmenturlAry) {
                        $Downloadedfilename = Split-Path $fileurl -leaf
                        Get-PnPFile -ServerRelativeUrl  $fileurl -Path  $CurrentDir -FileName $Downloadedfilename -AsFile -Force
                        $filegenerated = $true
                        if ($filegenerated) {
                            $msg = 'Info: Get-UserslistToAddIntoAD,  Attchment retrived : ' + $CurrentDir 
                            LogMessage  $msg
                            #attachment file url 
                            $fileurl = $CurrentDir + "\" + $Downloadedfilename 
                            $fileurlary.Add($fileurl)
                        }
                        else {
                            $msg = 'Error: Get-UserslistToAddIntoAD,  Attchment not retrived : ' + $CurrentDir 
                            LogMessage  $msg                       
                        }
                    }                       
                }
                catch {
                    $filegenerated = $false
                    LogMessage $_.Exception.Message                       
                }                     
            }
            else {
                LogMessage   "URL not correct for Stipend Instructions"
            }  
        }
        catch {
            LogMessage   $_.Exception.Message
        }
        #endregion
  
        #region get approved users from Stipend list
        #conect is required. or else it will take the current session which is connected to "https://gileadconnect.sharepoint.com/sites/MWPT" 
        Connect-PnPOnline -Url $O365SiteUrl -Credentials $credentials -WarningAction Ignore 
#>

        # $userquery = "<View><Query><Where>
        # <Or>
        #     <Eq><FieldRef Name='Status'/><Value Type='Text'>Approved</Value></Eq>
        #     <Eq><FieldRef Name='Status'/><Value Type='Text'>Auto-Approved</Value></Eq>
        # </Or></Where></Query></View>"
        # $listitems = Get-PnPListItem -List $StipendListName -Query $userquery    

        $listitems = $ListItemAll | Where { ($_["Status"] -eq "Approved" -or $_["Status"] -eq "Auto-Approved") -and ($_["ApprovalEmailSent"] -eq "" -or $_["ApprovalEmailSent"] -eq $null)}
 
        
        if ($listitems -and $listitems.length -gt 0) {
            Foreach ($listitem in $listitems) {
                $mailsentflag = $false;
                try {                
                    $UserData = "";             
                    $UserData = $listitem["Beneficiary"].Email;
                    $ADPath = $listitem["AD_Path"]
                    $mailsentflag = $listitem["ApprovalEmailSent"];
                    $id = $listitem["ID"];
                    if ($ADPath -and $ADPath -ne '') {
                        try {
                            $DCname = get-ServerName -ADPath $ADPath
                            $userTobeAdded = Get-ADUser -Identity $ADPath -Server $DCname 
                            $members = Get-ADGroupMember -Identity $ADDgroupName -Recursive | Select -ExpandProperty SamAccountName
                            If ($members -notcontains $userTobeAdded.SamAccountName) {
                                Add-ADGroupMember -members $userTobeAdded  -identity $ADDgroupName -ErrorAction Stop     
                                $msg = 'User ' + $listitem["Beneficiary"].LookupValue + ' added on  ' + (get-date)
                                LogMessage $msg
                                <#commenting this code as this will move to other job file#>
                                <#
                                #region Send mail
                                if ($EMailTobesent -eq "Yes") {
                                    $useremail = $emailbody 
                                    $useremail = $useremail.Replace("BENEFICIARY", $listitem["Beneficiary"].LookupValue)
                                    # $useremail = $useremail.Replace("SITEURL",$Enrollmentpageurl)
                                    $Sitelink = "<a href=$MobileDeviceUrl>Mobile Device Project website</a>"
                                    $Androidlink = "<a href=$AndroidUrl>Installation for Android devices</a>"
                                    $IOSlink = "<a href=$IOSUrl>Installation for iOS devices</a>"
                                    $FAQlink = "<a href=$FAQUrl>FAQs.</a>"
                                    $useremail = $useremail.Replace("INSTRUCITONSURLFORANDROID", $Androidlink)
                                    $useremail = $useremail.Replace("INSTRUCITONSURLFORIOS", $IOSlink)
                                    $useremail = $useremail.Replace("FAQ", $FAQlink)
                                    $useremail = $useremail.Replace("SITEURL", $Sitelink)
                                    Send-Email  -EmailTo $UserData  -body  $useremail -subject $emailSubject -attachment $fileurlary
                                     
                                }
                                else {
                                    LogMessage "Mail not sent. "
                                }
                                 #endregion Send mail 
                                 #>
                                                     
                            }

                            #remove user from Retired group
                            $members = Get-ADGroupMember -Identity $RemovedgroupName -Recursive | Select -ExpandProperty SamAccountName
                            If ($members -contains $userTobeAdded.SamAccountName) {
                                Remove-ADGroupMember -members $userTobeAdded  -identity $RemovedgroupName -Confirm:$false -ErrorAction Stop     
                                $msg = 'User ' + $listitem["Beneficiary"].LookupValue + ' removed on ' + $RemovedgroupName + ' ' + (get-date)
                                LogMessage $msg
                            }
                            #set email send flag to No/0 this will allow AddRemovesSendEmail to pick this record to send email
                            Set-PnPListItem -List $StipendListName -Identity $id  -Values @{"ApprovalEmailSent" = "No" } -SystemUpdate:$true
                        }
                        catch {
                            $msg = 'Error: Get-UserslistToAddIntoAD,  User: ' + $listitem["Beneficiary"].LookupValue 
                            LogMessage   $msg                      
                            LogMessage $_.Exception.Message   
                        }                  
                    }
                    else {
                        $msg = 'AD Path not returned from Stipend List for user  ' + $listitem["Beneficiary"].LookupValue 
                        LogMessage $msg                   
                    }

                }
                catch {
                    LogMessage $_.Exception.Message
                }
            }
        }
        else {
            LogMessage  'No approved item returned from stipend list.'
              
        }
        #endregion 
        Disconnect-PnPOnline
        # LogMessage  $error_msg 
    }
    Catch {
 
        LogMessage   $_.Exception.Message
    }
}
 
function Get-UserslistToRemoveFromAD {
    param(
        $ListItemAll
    )
    $emailbody = ""       
    $emailSubject = ""
    $EMailTobesent = ""
    Try {
        $SecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential($username, $SecurePassword)
        Connect-PnPOnline -Url $O365SiteUrl -Credentials $credentials -WarningAction Ignore  
  
        #region get emailtemplate 
        $query = "<View><Query><Where>
            <Eq><FieldRef Name='NotificationType'/><Value Type='Text'>ADUserRemove</Value></Eq>
            </Where></Query></View>"
        $emailitems = Get-PnPListItem -List $EmailListName -Query $query
        Foreach ($emailitem in $emailitems) { 
            $emailbody = $emailitem["EmailBody"]         
            $emailSubject = $emailitem["EmailSubject"]
            $EMailTobesent = $emailitem["ToBeSent"]
        } 
        #endregion
        #region Get users to remove from group 
       
        # LogMessage  "Getting Records from Stipend List for Get-UserslistToRemoveFromAD"
        # $RemovedUsersquery = "<View><Query><Where>
        # <Or>
        #     <Or>
        #         <Contains><FieldRef Name='Status'/><Value Type='Text'>Rejected</Value></Contains>
        #         <Contains><FieldRef Name='Status'/><Value Type='Text'>Cancel</Value></Contains>
        #     </Or>
        #     <Contains><FieldRef Name='Status'/><Value Type='Text'>Expired</Value></Contains>
        # </Or>
        # </Where></Query></View>"

        # $listitems = Get-PnPListItem -List $StipendListName -Query  $RemovedUsersquery
       
        $listitems = $ListItemAll | Where { $_["Status"] -eq "Cancelled" -or $_["Status"] -eq "Cancel Enrollment" -or $_["Status"] -eq "Rejected" -or $_["Status"] -eq "Expired" }
 
        if ($listitems -and $listitems.length -gt 0) {
            Foreach ($listitem in $listitems) {
                try { 
                    $UserData = "";              
                    $UserData = $listitem["Beneficiary"].Email;
                    $ADPath = $listitem["AD_Path"]   
                    if ($ADPath -ne '') {
                        try {
                            $DCname = get-ServerName -ADPath $ADPath
                            $userTobeRemoved = Get-ADUser -Identity $ADPath  -Server $DCname 
                            $members = Get-ADGroupMember -Identity $ADDgroupName -Recursive | Select -ExpandProperty SamAccountName
                            If ($members -contains $userTobeRemoved.SamAccountName) {
                                Remove-ADGroupMember -members $userTobeRemoved  -identity $ADDgroupName -Confirm:$false -ErrorAction Stop
                                $msg = 'User ' + $listitem["Beneficiary"].LookupValue + ' removed on  ' + (get-date)
                                LogMessage $msg 

                                if ($EMailTobesent -eq "Yes") {
                                    $useremail = $emailbody 
                                    $useremail = $useremail.Replace("BENEFICIARY", $listitem["Beneficiary"].LookupValue)
                                    $useremail = $useremail.Replace("SITEURL", $Enrollmentpageurl)  
                                    
                                    $Byod = "<a href=$EmailByodLink>U.S. BYOD Website</a>";
                                    $Faq= "<a href=$EmailFAQSLink>FAQs</a>";
                                    $useremail = $useremail.Replace("LINKBYOD", $Byod) 
                                    $useremail = $useremail.Replace("FQLINK", $Faq)
                                                              
                                    Send-Email  -EmailTo $UserData  -body  $useremail -subject $emailSubject
                                    #endregion Send mail   
                                }
                            }                        
                            #add user in Retired group
                            $members = Get-ADGroupMember -Identity $RemovedgroupName -Recursive | Select -ExpandProperty SamAccountName
                            If ($members -notcontains $userTobeRemoved.SamAccountName) {
                                Add-ADGroupMember -members $userTobeRemoved  -identity $RemovedgroupName -ErrorAction Stop     
                                $msg = 'User ' + $listitem["Beneficiary"].LookupValue + ' added on ' + $RemovedgroupName + ' ' + (get-date)
                                LogMessage $msg
                            }
                        }
                        catch {
                            $msg = 'Error: Get-UserslistToRemoveFromAD,  User:  ' + $listitem["Beneficiary"].LookupValue
                            LogMessage  $msg
                            LogMessage  $_.Exception.Message
                        } 
                    }
                    else {
                        $msg = 'Error: Get-UserslistToRemoveFromAD, AD Path not returned from Stipend List for user ' + $listitem["Beneficiary"].LookupValue
                        LogMessage  $msg 
                    }
                }
                catch {
                    LogMessage  $_.Exception.Message
                } 
            }
        }
        else {
            LogMessage  'No record returned from stipend list to remove user.'
        }
        #endregion
        Disconnect-PnPOnline
        #  LogMessage  $error_msg 
    }
    Catch {
        //   Write-Output $_.Exception.Message 
        LogMessage  $_.Exception.Message
    }
}




#endregion 
 
LogMessage "#######################################################################"
LogMessage "Script Execution Started."
try { 
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    LogMessage "Script Running as:  $CurrentUser "
    if (Get-Module -ListAvailable -Name "SharePointPnPPowerShellOnline") {
        #
    }
    else {

        Import-Module D:\applications\ESRA\InstallationPackages\SharePointPnPPowerShellOnline\3.29.2101.0\SharePointPnPPowerShellOnline.psd1 -DisableNameChecking
    } 
    
    $SecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($username, $SecurePassword)
    Connect-PnPOnline -Url $O365SiteUrl -Credentials $credentials -WarningAction Ignore  
    
     
    #region Set variables 
    $configlistitems = Get-PnPListItem -List $ConfigListName -ErrorAction Stop
    Foreach ($listitem in $configlistitems) {
        if ($listitem["Key"] -eq "IntuneGroupName") {
            $ADDgroupName = get_DecodeHtml -StringValue  $listitem["Value"]  
        }
        if ($listitem["Key"] -eq "IntuneGroupName_Retired") {
            
            $RemovedgroupName = get_DecodeHtml -StringValue $listitem["Value"] 
        }
        if ($listitem["Key"] -eq "SmtpserverInfo") {
            $smtpserver = get_DecodeHtml -StringValue  $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "EnrollScreenUrl") {
            $EnrollScreenUrl = get_DecodeHtml -StringValue  $listitem["Value"]           
        }
     
        if ($listitem["Key"] -eq "InstructionAndroidDeviceURL" -or $listitem["Key"] -eq "InstructionIOSDeviceUrl") {

            #make sure These file urls are from "https://gileadconnect.sharepoint.com/sites/MWPT" and files are uploaded.

            $url = get_DecodeHtml -StringValue  $listitem["Value"]
            $index = $url.IndexOf("/sites")
            $url = $url.Substring($index)
            $url = $url.Replace("%20", " ")
            if ($Attachmenturl) {
                $Attachmenturl = $Attachmenturl + ","
             
                $Attachmenturl = $Attachmenturl + $url
            }
            else {
                $Attachmenturl = $url  
            }         
        } 
        
        if ($listitem["Key"] -eq "EmailFromText") {
            $EmailFromText = get_DecodeHtml -StringValue $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "ApprovedEmailFAQURL") {
            $FAQUrl = get_DecodeHtml -StringValue $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "InstructionAndroidDeviceURL") {
            $AndroidUrl = get_DecodeHtml -StringValue $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "InstructionIOSDeviceUrl") {
            $IOSUrl = get_DecodeHtml -StringValue $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "ApprovedEmailMobileDeviceUrl") {
            $MobileDeviceUrl = get_DecodeHtml -StringValue $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "AccessTokenRequired") {
            $AccessTokenRequired = get_DecodeHtml -StringValue  $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "Proxyurl") {
            $proxyurl = get_DecodeHtml -StringValue  $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "Proxyenabled ") {
            $proxyenabled = get_DecodeHtml -StringValue  $listitem["Value"]           
        } 

        if ($listitem["Key"] -eq "ActiveUserDataApiURL") {
            $_UserDataApiURLconfig = $listitem["Value"]
            $_UserDataApiURLconfig = [System.Web.HttpUtility]::HtmlDecode($_UserDataApiURLconfig)        
        }
        if ($listitem["Key"] -eq "grant_type") {
            $_GrantType = $listitem["Value"]
        }
        if ($listitem["Key"] -eq "client_id") {
            $_ClientId = $listitem["Value"]
        }
        if ($listitem["Key"] -eq "client_secret") {
            $_ClientSecret = $listitem["Value"]
        }
        if ($listitem["Key"] -eq "OauthTokenApiURL") {
            $_OauthTokenApi = $listitem["Value"]
            $_OauthTokenApi = [System.Web.HttpUtility]::HtmlDecode($_OauthTokenApi)
            
        }  
        if ($listitem["Key"] -eq "ExpirationPeriod") {
            $ExpirationMonths = $listitem["Value"]             
        }
        if ($listitem["Key"] -eq "ExpiredUserComments") {
            $ExpiredUserComments = $listitem["Value"]             
        }
        if ($listitem["Key"] -eq "LeftUserComments") {
            $LeftUserComments = $listitem["Value"]             
        }
        if ($listitem["Key"] -eq "MobileDeviceDocumentsURL") {
            $MobileDocumentsUrl = get_DecodeHtml -StringValue $listitem["Value"]           
        }        
        if ($listitem["Key"] -eq "MobileDeviceDocumentsURL") {
            $MobileDocumentsUrl = get_DecodeHtml -StringValue $listitem["Value"]           
        }
        if ($listitem["Key"] -eq "UserDataApiURL") {
            $_UserDataApiURLconfiguration = $listitem["Value"]
            $_UserDataApiURLconfiguration = [System.Web.HttpUtility]::HtmlDecode($_UserDataApiURLconfiguration)
            
        } 
        if ($listitem["Key"] -eq "UpdateSuccessMsg") {
            $_UpdateSuccessMsg = $listitem["Value"]
        }
        if($listitem["Key"] -eq "ApproveRejectUrl")
        {
            $ApproveScreenUrl =get_DecodeHtml -StringValue  $listitem["Value"]           
        }  
         if ($listitem["Key"] -eq "EmailByodLink") {
            $EmailByodLink = get_DecodeHtml -StringValue $listitem["Value"]           
        }
          if ($listitem["Key"] -eq "EmailFAQSLink") {
            $EmailFAQSLink = get_DecodeHtml -StringValue $listitem["Value"]           
        }
        
    } 
    $oauthurl = $_OauthTokenApi + '?grant_type=' + $_GrantType
    $body = [ordered]@{
        client_id     = $_ClientId
        client_secret = $_ClientSecret
    }
    $accessTokenUrl = $oauthurl 
    $Enrollmentpageurl = $O365SiteUrl + $EnrollScreenUrl 
    $REEnrollmentpageurl = $O365SiteUrl + $EnrollScreenUrl+"?ReEnroll=true"
    $Approvepageurl = $O365SiteUrl + $ApproveScreenUrl 
    #endregion

    #get data from stupend list to avoid trip to server in each function 
    LogMessage 'Connecting to Sitpend list'
    $tmplistitems = Get-PnPListItem -List $StipendListName -PageSize 500


    #region Add approved user in AD group  
    try {
        LogMessage 'Get-UserslistToAddIntoAD Started'
        Get-UserslistToAddIntoAD -ListItemAll $tmplistitems  
        LogMessage 'Get-UserslistToAddIntoAD Ended'   
    }
    catch {
        LogMessage  $_.Exception.Message
    }
    #endregion
   
    #region Remove users from ADGroup with status Reject/cancell   
    try {
        LogMessage 'Get-UserslistToRemoveFromAD Started'
        #Get-UserslistToRemoveFromAD -ListItemAll $tmplistitems
        LogMessage 'Get-UserslistToRemoveFromAD Ended'
    }
    catch {
        LogMessage  $_.Exception.Message
    }
    #endregion

   
    
    
    <#
    #########################
    #####To Be Deleted ######'
    #########################
    $mailmessgae= ""
     LogMessage "######################***********************************##################"
    $msg = 'List of member in  ' + $ADDgroupName
    LogMessage $msg
    $mailmessgae =   $msg
    $members = Get-ADGroupMember -Identity $ADDgroupName -Recursive | Select -ExpandProperty SamAccountName
    Foreach ($member in $members) {
        LogMessage $member
        $mailmessgae = $mailmessgae + "\n" + $member  
  }                       
    LogMessage "######################***********************************##################"
     
    $msg = 'List of member in  ' + $RemovedgroupName
    LogMessage $msg
    $mailmessgae = $mailmessgae + "\n" + $msg  
    $members = Get-ADGroupMember -Identity $RemovedgroupName -Recursive | Select -ExpandProperty SamAccountName
    Foreach ($member in $members) {
        LogMessage $member
         $mailmessgae = $mailmessgae + "\n" + $member  
    }          
   LogMessage "######################***********************************##################" 
    LogMessage "List of member done"
    LogMessage "Script Execution Ended"

    #Get the Location of the script
    If ($psise) {
        $CurrentDir = Split-Path $psise.CurrentFile.FullPath
    }
    Else {
        $CurrentDir = $Global:PSScriptRoot
    }
    #Frame Log File with Current Directory and date
    $LogFile = $CurrentDir + "\ADUser_" + $LogDate + ".log"
    $LogFileary = [System.Collections.ArrayList]@()
                
    $LogFileary.Add($LogFile)
     Send-Email -EmailTo "rita.kumari3@gilead.com"  -body  "Log file email from Staging" -subject  "Log file email -Staging" -attachment $LogFileary
     Send-Email -EmailTo "himanshu.sharma4@gilead.com"  -body $mailmessgae -subject  "Logs - Staging"
     LogMessage "######################***********************************##################"
  
    #########################
    #####To Be Deleted######
    #########################  
 	#>

}
catch {
    LogMessage $_.Exception.Message
}