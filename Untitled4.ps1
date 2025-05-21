# Declare and Initialize Variables   
$CurrentDirectory =  Split-Path -parent $MyInvocation.MyCommand.Definition  
$Sites= Get-content "$CurrentDirectory\Sites.txt"  
$appPath="$CurrentDirectory\site-redirection.sppkg"  
$currentTime= $(get-date).ToString("yyyyMMddHHmmss")  
$logFile = "$CurrentDirectory\$currentTime LogReport.csv"  
add-content $logFile "URL,Status,exception"  
$credentials=Get-Credential  
  
# Add App   
function AddApp  
{  
      foreach ($site in $Sites)   
      {  
        try  
        {  
            Connect-PnPOnline -URL $site -Credentials $credentials   
            # Add the app to the app catalog and publish it             
            Add-PnPApp -Path $appPath -Scope Site -Publish                                 
            Disconnect-PnPOnline  
        }  
        Catch  
        {   
            add-content $logFile  "$($site),No , $($_.Exception.Message)"   
            Continue;  
        }  
      }  
}  
 
# Install App   
function InstallApp  
{  
      foreach ($site in $Sites)   
      {  
        try  
        {  
            Connect-PnPOnline -URL $site -Credentials $credentials  
            # Get the app which is published in the site collection app catalog  
            $app=Get-PnPApp -Scope Site | Where Title -EQ "site-redirection-client-side-solution"  
            # Install the app at the root site  
            Install-PnpApp -Identity $app.Id -scope site       
             
            # Get all the subsites and install the app    
            $webColl=Get-PnPSubWebs -Recurse  
            foreach($web in $webColl)  
            {                    
                  $connection= Connect-PnPOnline -URL $web.URL -Credentials $credentials                   
                  Install-PnpApp -Identity $app.Id -scope site -Connection $connection  
                  Disconnect-PnPOnline  
            }        
            Disconnect-PnPOnline  
        }  
        Catch  
        {   
            add-content $logFile  "$($site),No , $($_.Exception.Message)"   
            Continue;  
        }  
      }  
}    
   
# Call the functions    
AddApp   
InstallApp   