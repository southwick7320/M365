Start-Transcript 

$adcred = Get-Credential -Message "Enter Local AD Credential for dp-adfs01"
$msolcred = Get-Credential -Message "Enter MSOL Admin Credential"
$ADFSPrimary = Read-host "Enter Primary ADFS server FQDN"

Try{
    
    Connect-MsolService -ErrorAction Stop

} Catch {

    Write-Error $Error[0]
    Exit

}

Try{

    $claims_pre_change = Invoke-Command -ComputerName $ADFSPrimary -ScriptBlock {get-adfsrelyingpartytrust -Identifier "https://login.microsoftonline.com/extSTS.srf"} -Credential $adcred -ErrorAction Stop

} Catch {

    Write-Error "failed to connect to ad session, exiting"
    Exit

}
Write-host "Claims Before Change (we are interested in the third rule ):`n" -ForegroundColor Green
$claims_pre_change.IssuanceTransformRules


Write-host "===========================================`n" -ForegroundColor Green

$domain=  read-host "Enter New Child Domain (enter (E)xit to Exit script)"

if($domain -like "Exit" -or $domain -like "E"){
    write-host "Exiting Script" -ForegroundColor Yellow
    Exit

}
try{
                                      
    Set-MsolADFSContext -Computer $ADFSPrimary -ErrorAction Stop -Verbose

} Catch {

    Write-Error "failed to set-msoladfscontext" 
    exit

}

$continue1 = Read-host "Child domain is $domain, continue? (Y)es or (E)xit."

if($continue1 -like "Y" -or $continue1 -like "Yes"){

} elseif ($continue1 -like "E" -or $continue1 -like "Exit") {
    
    Write-host "Exiting Script"
    Exit

} else {
    
    Write-host "Invalid Input, Exiting"
    Exit

}
Try{

   New-MsolFederatedDomain -DomainName $domain -SupportMultipleDomain -Verbose  -ErrorAction Stop
   } Catch {

   Write-Error "failed to set federated domain"
   exit

   }


$claims_post_change = Invoke-Command -ComputerName $ADFSPrimary -ScriptBlock {get-adfsrelyingpartytrust -Identifier "https://login.microsoftonline.com/extSTS.srf"} -Credential $adcred

Write-host "Claims After Change (we are interested in the third rule ):`n" -ForegroundColor Cyan

$claims_post_change.IssuanceTransformRules


Write-host "===========================================`n" -ForegroundColor Cyan

Write-host "If changed Do the following: `n`t1. Log into $ADFSPrimary`n`t2. Open ADFS Management`n`t3. Navigate to AD FS > Trust Relationships > Relying Party Trusts > Microsoft Office 365 Identity Platform.`n`t4. Click on Edit Claim Rule > Issuance Transform Rules > See Claim Rule. 5. Paste in pre change claim rule" -ForegroundColor Yellow

Stop-Transcript
