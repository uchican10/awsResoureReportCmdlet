function Get-EC2SubnetRoute {
    param(  
        [Parameter(Mandatory = $true)]  
        [string]$InstanceName  
    )  
  
    # 1. インスタンス情報取得: Nameタグが一致するインスタンスのSubnetId, VpcIdを取得  
    $instance = Get-EC2Instance -Filter @{ Name = "tag:Name"; Values = $InstanceName } | Select-Object -ExpandProperty Instances | Select-Object -First 1  
  
    if (-not $instance) {  
        Write-Error "Nameタグ '$InstanceName' のインスタンスが見つかりません。"  
        return 1  
    }  
  
    $subnetId = $instance.SubnetId  
    $vpcId = $instance.VpcId  
  
    # 2. SubnetのルートテーブルIDを取得するためにルートテーブルを取得し、所属サブネットと一致するルートテーブルを探す  
    $routeTables = Get-EC2RouteTable -Filter @{ Name = "vpc-id"; Values = $vpcId }  
  
    # サブネットに直接関連付けられたルートテーブルがあればそれを使う  
    $routeTable = $routeTables.RouteTables | Where-Object {  
        $_.Associations | Where-Object { $_.SubnetId -eq $subnetId }  
    } | Select-Object -First 1  
  
    # 直接紐づくルートテーブルが無ければ、VPCのメインルートテーブルを使う  
    if (-not $routeTable) {  
        $routeTable = $routeTables.RouteTables | Where-Object { $_.Associations | Where-Object { $_.Main } } | Select-Object -First 1  
    }  
  
    if (-not $routeTable) {  
        Write-Error "サブネットおよびVPCのルートテーブルが見つかりません。"  
        return 1  
    }  
  
    # 結果表示  
    Write-Output "Instance Name: $InstanceName"  
    Write-Output "SubnetId: $subnetId"  
    Write-Output "RouteTableId: $($routeTable.RouteTableId)"  
    Write-Output "VpcId: $vpcId"  
}