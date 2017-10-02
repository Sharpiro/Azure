$location = "East US"
# $vmResourceGroupName = "sharpiroVMResourceGroup1"
$vmResourceGroupName = "azTestGroup"
# $vmName = "AppServer1"
$vmName = "testvm1"
$vmSizes = (
    @{Id = 1; Name = "Standard_B1s"; Price = 4.46; Cpus = 1; RAM = 2},
    @{Id = 2; Name = "Standard_B1ms"; Price = 8.93; Cpus = 1; RAM = 4},
    @{Id = 3; Name = "Standard_B2s"; Price = 17.86; Cpus = 2; RAM = 4},
    @{Id = 4; Name = "Standard_B2ms"; Price = 34.97; Cpus = 2; RAM = 8},
    @{Id = 5; Name = "Standard_B4ms"; Price = 69.94; Cpus = 4; RAM = 16},
    @{Id = 6; Name = "Standard_B8ms"; Price = 139.87; Cpus = 8; RAM = 32}
)
$images = (
    @{Id = 1; DisplayName = "2016_DataCenter_SmallDisc"; Urn = "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-smalldisk:2016.127.20170822"},
    @{Id = 2; DisplayName = "2016_DataCenter_SmallDisc_Core"; Urn = "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core-smalldisk:2016.127.20170822"},
    @{Id = 3; DisplayName = "2016_Nano"; Urn = "MicrosoftWindowsServer:WindowsServer:2016-Nano-Server:2016.0.20170927"}
)

$inputVmName = Read-Host "Enter VM name (testvm1)"
$vmName = if (![string]::IsNullOrEmpty($inputVmName)) {$inputVmName} else {$vmName};

$vmSizes.ForEach( {[PSCustomObject]$_}) | Format-Table -AutoSize
$sizeId = [int]::Parse((Read-Host "Choose Size by Id (1-$($vmSizes.Length))"))
if ($sizeId -lt 1 -or $sizeId -gt $vmSizes.Length) {throw "must provide a value 1-$($vmSizes.Length)"}
$vmSize = $vmSizes[$sizeId - 1];
"selected size '$($vmSize.Name)'"

$images.ForEach( {[PSCustomObject]$_}) | Format-Table -AutoSize
$imageId = [int]::Parse((Read-Host "Choose image by Id (1-$($images.Length))"))
if ($imageId -lt 1 -or $imageId -gt $($images.Length)) {throw "must provide a value 1-$($images.Length)"}
$vmImage = $images[$imageId - 1];
"selected image '$($vmImage.DisplayName)'"

# get password
$password = Read-Host "enter password"
if (!$password) {throw "must supply a pasword value"}
$confirmPassword = Read-Host "confirm password"
if ($password -ne $confirmPassword) {throw "the passwords did not match"}

write-warning "name: '$vmName', group: '$vmResourceGroupName', size: '$($vmSize.Id)-$($vmSize.Name)', image: '$($vmImage.DisplayName)'"
$createConfirmation = Read-Host "Confirm: Do you want to create this vm? (y/n)"
if ($createConfirmation -ne 'y') {return; }

$vmRaw = az vm show -n $vmName -g $vmResourceGroupName
if ($vmRaw) {
    $confirmation = Read-Host "vm '$vmName' already exists on group '$vmResourceGroupName', do you want to delete it? (y/n)"
    if ($confirmation -ne 'y') {return; }
    "deleting vm '$vmName'"
    az vm delete -n $vmName -g $vmResourceGroupName -y
}

$vmResourceGroupRaw = az group show --name $vmResourceGroupName
if (!$vmResourceGroupRaw) {
    "creating new resource group '$vmResourceGroupName'"
    $vmResourceGroupRaw = az group create --n $vmResourceGroupName --l $location
}

if (!$vmResourceGroupRaw) {throw "An error occurred while creating resourcegroup $vmResourceGroupName"}

# convert from object array to string, converto from json string to jObject
# $vmResourceGroupJson = -join $vmResourceGroupRaw;
# $vmResourceGroupJObject = ConvertFrom-Json $vmResourceGroupJson

"creating new vm '$vmName'"
az vm create -n $vmName -g $vmResourceGroupName --image $vmImage.Urn --size $vmSize.Name --admin-password $password

# az group delete -n "azTestGroup" -y
# az vm delete -n "testvm1" -g "azTestGroup" -y