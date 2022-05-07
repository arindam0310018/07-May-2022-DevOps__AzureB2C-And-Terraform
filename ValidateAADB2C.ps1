$AADExists          = "AlreadyExists"
$AADProvider        = "NotRegistered"
$AADB2CCountryCode  = "CH"
$AADB2CName         = "AMTestb2ctenant005.onmicrosoft.com"
$AADB2CRest         = "https://management.azure.com/subscriptions/210e66cb-55cf-424e-8daa-6cad804ab604/providers/Microsoft.AzureActiveDirectory/checkNameAvailability?api-version=2019-01-01-preview"

$B2CJSON = @{
      countryCode   = "$AADB2CCountryCode"
      name          = "$AADB2CName"
    }
$infile = "B2CDetails.json"
Set-Content -Path $infile -Value ($B2CJSON | ConvertTo-Json)

$i = az rest --method POST --url $AADB2CRest  --body "@B2CDetails.json" --query 'reason' -o tsv

$j = az provider show --namespace "Microsoft.AzureActiveDirectory" --query "registrationState" -o tsv

if ($i -eq "$AADExists" -and $j -eq "$AADProvider") {
Write-Output "Name $AADExists and Provider $AADProvider"
}

ElseIf ($i -eq "$AADExists" -or $j -eq "$AADProvider") {
Write-Output "Either Name $AADExists or Provider $AADProvider"
}

Else {
Write-Output "MOVE TO NEXT STAGE - DEPLOY AZURE AAD B2C"
}