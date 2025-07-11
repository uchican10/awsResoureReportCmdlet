function Get-RouteTables {  
    [CmdletBinding()]  
    param(  
       #
    )  

    try {  
        $json = aws ec2 describe-route-tables

        if ($LASTEXITCODE -ne 0) {  
            Write-Error "aws cliの実行に失敗しました。エラー: $json"  
            return  
        }  
    }
    catch {  
        Write-Error "aws cliの実行中に例外が発生しました: $_"  
        return  
    }  

    $routeTablesJson = $json|ConvertFrom-Json
    $results = foreach ($rt in $routeTablesJson.RouteTables) {  
        # タグからNameを取得  
        $nameTag = $rt.Tags | Where-Object { $_.Key -eq 'Name' }  
        $name = if ($nameTag) { $nameTag.Value } else { "" }  
  
        # ルートを「送信先:ターゲット」形式で文字列化  
        $routeStrings = foreach ($route in $rt.Routes) {  
            # 送信先のCIDRはIPv4かIPv6かを判定  
            $destination = $route.DestinationCidrBlock  
            if (-not $destination) {  
                $destination = $route.DestinationIpv6CidrBlock  
            }  
            if (-not $destination) {  
                $destination = "(UnknownDestination)"  
            }  
  
            # ターゲット（GatewayId,InstanceId,NetworkInterfaceId, VpcPeeringConnectionId, NatGatewayIdなど）  
            # AWS公式ドキュメントのルートターゲット例を探してキーを判定  
            $targetKeys = @("GatewayId","InstanceId","NetworkInterfaceId","VpcPeeringConnectionId","NatGatewayId","TransitGatewayId","EgressOnlyInternetGatewayId")  
            $target = $null  
            foreach ($key in $targetKeys) {  
                if ($route.PSObject.Properties.Name -contains $key) {  
                    $target = $route.$key  
                    if ($target) { break }  
                }  
            }  
            if (-not $target) { $target = "(UnknownTarget)" }  
  
            # 送信先:ターゲット の形にする  
            "$destination`:$target"  
        }  
        $routeString = $routeStrings -join ","  
  
        # 関連付けを文字列化  
        # AssociationId, SubnetId, Main (bool)などを表示しカンマ区切り  
        $assocStrings = foreach ($assoc in $rt.Associations) {  
            # AssociationId必須  
            $assocId = $assoc.AssociationId  
  
            # サブネットID or メインフラグ  
            $subnetId = $assoc.SubnetId  
            $isMain = $assoc.Main  
  
            $parts = @($assocId)  
            if ($subnetId) {  
                $parts += $subnetId  
            }  
            if ($isMain -eq $true) {  
                $parts += "Main=True"  
            }  
            $parts -join ":"  
        }  
        $assocString = $assocStrings -join ","  
                # オブジェクトで返す  
        [PSCustomObject]@{  
            Name         = $name  
            RouteTableId = $rt.RouteTableId  
            Routes       = $routeString  
            Associations = $assocString  
        }  
    }  
  
    # 結果を出力  
    $results  
}  