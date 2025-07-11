function Add-SecurityGroup-to-EC2 {
    <#
.SYNOPSIS
    ルートテーブルに対して、宛先0.0.0.0/0をTransit Gatewayに向ける
.DESCRIPTION
    Subnet IDを指定し、そのSubnetに関連付けられているルートテーブルに対して、宛先0.0.0.0/0をTransit Gatewayに向けるルートを追加する 
.PARAMETER SubnetId
    対象のサブネットId
.PARAMETER TransitGatewayId  
    対象のTransit Gateway ID
.EXAMPLE
    Add-Route-to-TGW -SubnetId subnet-0abc123def456ghij -TransitGatewayId tgw-0a1b2c3d4e5f6g7h8  

.NOTES
    date: 2025/06/25
    author:ozaki
    

    
    
    
    #>
    [CmdletBinding()]
param(  
    [Parameter(Mandatory=$true)]  
    [string]$InstanceName,  
  
    [Parameter(Mandatory=$true)]  
    [string]$SecurityGroupName  
)  
  
# 1. 対象EC2インスタンスのIDをNameタグで取得  
$instanceId = aws ec2 describe-instances `
    --filters "Name=tag:Name,Values=$InstanceName" "Name=instance-state-name,Values=running,pending,stopped,stopping" `
    --query "Reservations[].Instances[].InstanceId" `
    --output text  
  
if ([string]::IsNullOrEmpty($instanceId)) {  
    Write-Error "指定したインスタンス名 '$InstanceName' を持つインスタンスが見つかりません。"  
    exit 1  
}  
  
Write-Host "対象のインスタンスID: $instanceId"  
  
# 2. インスタンスの現在のセキュリティグループID一覧を取得  
$currentSgIds = aws ec2 describe-instances `
    --instance-ids $instanceId `
    --query "Reservations[0].Instances[0].SecurityGroups[].GroupId" `
    --output text  
  
if ([string]::IsNullOrEmpty($currentSgIds)) {  
    Write-Error "インスタンス $instanceId のセキュリティグループが取得できませんでした。"  
    exit 1  
}  
  
Write-Host "現在のセキュリティグループID: $currentSgIds"  
  
# 3. 追加したいセキュリティグループのIDを名前から取得  
$newSgId = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=$SecurityGroupName" `
    --query "SecurityGroups[0].GroupId" `
    --output text  
  
if ([string]::IsNullOrEmpty($newSgId)) {  
    Write-Error "セキュリティグループ名 '$SecurityGroupName' が見つかりません。"  
    exit 1  
}  
  
Write-Host "追加するセキュリティグループID: $newSgId"  
  
# 4. すでにセキュリティグループに存在しているか確認  
if ($currentSgIds -split '\s+' | Where-Object { $_ -eq $newSgId }) {  
    Write-Host "インスタンスには既にセキュリティグループ '$SecurityGroupName' が設定されています。"  
    exit 0  
}  
  
# 5. 既存のセキュリティグループIDに新規グループIDを追加  
$updatedSgIds = $currentSgIds + " " + $newSgId  
  
# 6. セキュリティグループの付け替え（replace operation）  
aws ec2 modify-instance-attribute --instance-id $instanceId --groups $updatedSgIds  
  
if ($LASTEXITCODE -eq 0) {  
    Write-Host "セキュリティグループ '$SecurityGroupName' をインスタンス '$InstanceName' に追加しました。"  
} else {  
    Write-Error "セキュリティグループの追加に失敗しました。"  
    exit 1  
}  


}