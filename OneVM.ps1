$testName = "mvaiaasv2onevm"

$resourceGroupName = $testName
$location = "West US"

$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$sku = "2012-R2-Datacenter"
$version = "latest"

$subnetName = "Subnet-1"

New-AzureRMResourceGroup -Name $resourceGroupName -Location $location

New-AzureRMStorageAccount -ResourceGroupName $resourceGroupName `
   -Name $testName -Location $location -Type Standard_LRS

$subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName `
   -AddressPrefix "10.0.64.0/24"

$vnet = New-AzureRMVirtualNetwork -Name "VNET" `
   -ResourceGroupName $resourceGroupName `
   -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet

$subnet = Get-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

$pip = New-AzureRMPublicIpAddress -ResourceGroupName $resourceGroupName -Name "vip1" `
   -Location $location -AllocationMethod Dynamic -DomainNameLabel $testName

$nic = New-AzureRMNetworkInterface -ResourceGroupName $resourceGroupName `
   -Name "nic1" -Subnet $subnet -Location $location -PublicIpAddress $pip -PrivateIpAddress "10.0.64.4" 

New-AzureRMAvailabilitySet -ResourceGroupName $resourceGroupName `
   -Name "AVSet" -Location $location

$avset = Get-AzureRMAvailabilitySet -ResourceGroupName $resourceGroupName -Name "AVSet"

$cred = Get-Credential

$vmConfig = New-AzureRMVMConfig -VMName "$testName-w1" -VMSize "Standard_A1" `
   -AvailabilitySetId $avSet.Id | 

    Set-AzureRMVMOperatingSystem -Windows -ComputerName "contoso-w1" `
       -Credential $cred -ProvisionVMAgent -EnableAutoUpdate  | 

    Set-AzureRMVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku `
       -Version $version | 

    Set-AzureRMVMOSDisk -Name "$testName-w1" -VhdUri "https://$testName.blob.core.windows.net/vhds/$testName-w1-os.vhd" `
       -Caching ReadWrite -CreateOption fromImage  | 

    Add-AzureRMVMNetworkInterface -Id $nic.Id

New-AzureRMVM -ResourceGroupName $resourceGroupName -Location $location `
   -VM $vmConfig 

(Get-AzureRMPublicIpAddress -ResourceGroupName $resourceGroupName).IpAddress
