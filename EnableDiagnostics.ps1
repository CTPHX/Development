#Phoenix Software 2020

#Please install the Az.Compute & AZ.Resources Module into your Azure Automation account.

$conn = Get-AutomationConnection -Name AzureRunAsConnection
Add-AzAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint

#Diagnostic Variables
$storageName = "phxmbwvd"
$storageKey = "eTRp3sW9v6v5iVXEJ15qdJ3f1wmE3e4MFiL1mphA8VXEJ+ABYC1FEjBzz/vZi+jRCAK8kXQKFKVDhgd5WxIrMA=="
#Set-AzContext -SubscriptionId "1fc369f4-d003-43ba-a25e-339ef3b5b968"

#Function
function Enable-WindowsDiagnosticsExtension($rsgName,$rsgLocation,$vmId,$vmName){
    $extensionName = "IaaSDiagnostics"
    $extensionType = "IaaSDiagnostics"
    $vmLocation = $rsgLocation
   
    $extension = Get-AzVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName | Where-Object -Property ExtensionType -eq $extensionType
    if($extension -and $extension.ProvisioningState -eq 'Succeeded'){
        Write-Host "just skip,due to diagnostics extension had been installed in VM: "$vmName " before,you can update the diagnostics settings via portal or powershell cmdlets by yourself"
        return
    }
    Write-Host "start to install the diagnostics extension for windows VM"

       
        Write-Host "storageName:" $storageName
        $storageAccount = $storageName
        $storageKeys = $storageKey;
                Write-Host "storageKey:" $storageKey  

        $vmLocation = $rsgLocation

        
      New-AzResourceGroupDeployment -ResourceGroupName $rsgName  -TemplateUri 'https://raw.githubusercontent.com/CTPHX/AzureEssentials/main/extensionTemplateForWindows.json?token=AS3Y56MWBOHIS3EYHIOVIUDAFPBMK'
}

$storageType = "Standard_LRS"
$storageNamePrefix = "autoname"
$deployExtensionLogDir = 'Null'

#Gets List of VM's
$vmList = $null
if($targetVmName -and $targetRsgName){
    Write-Host "you have input the rsg name:" $targetRsgName " vm's name:" $targetVmName
    $vmList = Get-azVM -Name $targetVmName -ResourceGroupName $targetRsgName
} else {
    Write-Host "you have not input the target vm's name and will retrieve all vms"
    $vmList = Get-AzVM 
}


#Installs AZ Diagnostic if VM is powered on.
if($vmList){
    foreach($vm in $vmList){
        $status=$vm | Get-AzVM -Status 
        if ($status.Statuses[1].DisplayStatus -ne "VM running")
        {
            Write-Host $vm.Name" is not running. Skip."
            continue 
        }
        $rsgName = $vm.ResourceGroupName;
        $rsg = Get-AzResourceGroup -Name $rsgName
        $rsgLocation = $vm.Location;

        $vmId = $vm.Id
        $vmName = $vm.Name
        Write-Host "vmId:" $vmId
        Write-Host "vmName:" $vmName

        $osType = $vm.StorageProfile.OsDisk.OsType
        Write-Host "OsType:" $osType

        if($osType -eq 0){
            Write-Host "this vm type is windows"
            Enable-WindowsDiagnosticsExtension -rsgName $rsgName -rsgLocation $rsgLocation -vmId $vmId -vmName $vmName
        } else {
            Write-Host "this vm type is linux"
            #Enable-LinuxDiagnosticsExtension -rsgName $rsgName -rsgLocation $rsgLocation -vmId $vmId -vmName $vmName
        }
    }
    }
