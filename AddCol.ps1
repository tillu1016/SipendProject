//Script to add collaborators on box folder
param (
    [string]$folderId,
    [string]$email
)

# Box API endpoint for adding collaborators
$boxApiUrl = "https://api.box.com/2.0/folders/$folderId/collaborations"

# Box API access token
$boxAccessToken = "YOUR_BOX_ACCESS_TOKEN"

# Create the collaboration request body
$collaborationBody = @{
    email = $email
    role = "editor"
} | ConvertTo-Json

# Send the API request to add the collaborator
$response = Invoke-RestMethod -Uri $boxApiUrl -Method Post -Headers @{
    "Authorization" = "Bearer $boxAccessToken"
    "Content-Type" = "application/json"
} -Body $collaborationBody

# Output the response
$response