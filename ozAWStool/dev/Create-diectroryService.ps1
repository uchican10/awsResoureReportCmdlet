<#
.SYNOPSIS
    directry service (MicrosoftAD)を作成する
.DESCRIPTION
    directry service (MicrosoftAD)を作成する
.PARAMETER gvCode
    自治体コード（5桁）
.PARAMETER adminPW  
    domainユーザadmin　のパスワード
.EXAMPLE
    Create-directoryService -gvCode 23236 -adminPW Miyoshishi23236
.NOTES
    date: 2025/07/09
    author:ozaki
#>

param(  
    [Parameter(Mandatory = $true)][string]$gvCode , 
    [Parameter(Mandatory = $true)][string]$adminPW
 
)  
  
# 1. サブネット名の設定  
$subnetName1 = "${gvCode}-subnet-workspaces-1a"  
$subnetName2 = "${gvCode}-subnet-workspaces-1c"  
  
# 2. サブネットIDを取得する関数定義  
function Get-SubnetIdByName {  
    param (  
        [string]$SubnetName  
    )  
    $subnetJson = aws ec2 describe-subnets --filters "Name=tag:Name,Values=$SubnetName" | ConvertFrom-Json  
    if ($subnetJson.Subnets.Count -eq 0) {  
        Write-Error "Subnet named '$SubnetName' not found."  
        exit 1  
    }  
    return $subnetJson.Subnets[0].SubnetId  
}  


# 2.5 
$DomainName = "${gvCode}kh.local"

# 3. サブネットIDの取得  
$subnetId1 = Get-SubnetIdByName -SubnetName $subnetName1  
$subnetId2 = Get-SubnetIdByName -SubnetName $subnetName2  
  
# 4. VPC IDの取得とサブネット間のVPC一致チェック  
$subnetJson1 = aws ec2 describe-subnets --subnet-ids $subnetId1 | ConvertFrom-Json  
$subnetJson2 = aws ec2 describe-subnets --subnet-ids $subnetId2 | ConvertFrom-Json  
$vpcId1 = $subnetJson1.Subnets[0].VpcId  
$vpcId2 = $subnetJson2.Subnets[0].VpcId  
  
if ($vpcId1 -ne $vpcId2) {  
    Write-Error "Subnets belong to different VPCs."  
    exit 1  
}  
  
# 5. short-name をドメイン名の最初の部分で設定（例: domain.example.com -> DOMAIN）  
$shortName = ($DomainName.Split('.')[0]).ToUpper()  
  
# 6. VPC設定用JSONを作成し一時ファイルに書き込み  
$vpcSettings = @{  
    "SubnetIds" = @($subnetId1, $subnetId2)  
    "VpcId"     = $vpcId1  
} | ConvertTo-Json -Depth 3  
  
$tempFile = [System.IO.Path]::GetTempFileName()  
Set-Content -Path $tempFile -Value $vpcSettings -Encoding UTF8  
  
# 7. Microsoft AD ディレクトリの作成コマンド実行  
aws ds create-microsoft-ad `
    --name $DomainName `
    --short-name $shortName `
    --edition Standard `
    --password $adminPW `
    --vpc-settings file://$tempFile  
  
# 8. 一時ファイルの削除  
Remove-Item $tempFile  