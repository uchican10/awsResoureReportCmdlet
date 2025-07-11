function Add-Route-to-TGW {
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
        [Parameter(Position = 0,Mandatory = $true)]  
        [string]$SubnetId,  
  
        [Parameter(Position = 1,Mandatory = $true)]  
        [string]$TransitGatewayId  
    )  
  
    $intectgwid="tgw-0022cd96b4b2df762"

    # SubnetのVPC IDを取得  
    $vpcId = (aws ec2 describe-subnets --subnet-ids $SubnetId --query "Subnets[0].VpcId" --output text)  
    if ($vpcId -eq "None" -or [string]::IsNullOrEmpty($vpcId)) {  
        Write-Error "Subnet ID $SubnetId が見つかりませんでした。"  
        Add-Route-to-TGW "subnet-08681442dd6eccf1b" tgw-0c44ebe130badbb26rn  1  
    }  
  
    # Subnetに関連付けられているルートテーブルを取得  
    $routeTableId = (aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$SubnetId" --query "RouteTables[0].RouteTableId" --output text)  
  
    if ($routeTableId -eq "None" -or [string]::IsNullOrEmpty($routeTableId)) {  
        # サブネットに関連付けられた路テーブルが無ければVPCのメインルートテーブルを取得  
        $routeTableId = (aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcId" "Name=association.main,Values=true" --query "RouteTables[0].RouteTableId" --output text)  
        if ($routeTableId -eq "None" -or [string]::IsNullOrEmpty($routeTableId)) {  
            Write-Error "対象のサブネット($SubnetId)の関連ルートテーブルが見つかりません。"  
            return  1  
        }  
    }  
  
    # Write-Host "Subnet $SubnetId に関連付いたルートテーブル: $routeTableId"  
  
    # 既存ルートを確認（0.0.0.0/0 -> トランジットGW が既にないか）  
    # $existingRoute = aws ec2 describe-route-tables --route-table-ids $routeTableId --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0' && TransitGatewayId=='$TransitGatewayId']" --output text  
  
    #if ($existingRoute) {  
    #    Write-Host "ルートテーブル $routeTableId に既に 0.0.0.0/0 -> Transit Gateway ($TransitGatewayId) のルートが存在します。処理を終了します。"  
    #    return  0  
    #}  
  
    # ルートを追加  
    aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --transit-gateway-id $TransitGatewayId  
    #aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 10.18.0.0/22 --transit-gateway-id $intectgwid  
    #aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 10.64.2.0/23 --transit-gateway-id $intectgwid   
  
    <#
    if ($LASTEXITCODE -eq 0) {  
        Write-Host "ルートテーブル $routeTableId に 0.0.0.0/0 -> Transit Gateway ($TransitGatewayId) のルートを追加しました。"  
    }
    else {  
        Write-Error "ルート追加に失敗しました。"  
        return  1  
    }
        #>
    write-host "終了"  
}
<#
Add-Route-to-TGW "subnet-08681442dd6eccf1b" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-0cb2d74bb504ce230" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-0a32ffb30358d0cf3" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-047f04088a73b77d1" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-084291f7d3b693ed1" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-06536e765acef72c1" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-077c1e8518e908319" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-039812cce531735e2" tgw-0c44ebe130badbb26
Add-Route-to-TGW "subnet-06102caabe8173006" tgw-0c44ebe130badbb26
#>