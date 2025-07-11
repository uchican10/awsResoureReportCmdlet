function Check-SSMEndpoint{

param(  
    [Parameter(Mandatory = $true)]  
    [string]$VpcId  
)  
  
Write-Host "VPC ID: $VpcId で作成された Interface VPC エンドポイントを取得中..."  
  
# VPC Endpoint の情報を取得（Interfaceタイプかつ指定VPC）  
$vpcEndpointsJson = aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VpcId" "Name=vpc-endpoint-type,Values=Interface " 
$vpcEndpoints = $vpcEndpointsJson | ConvertFrom-Json  
  
if ($vpcEndpoints.VpcEndpoints.Count -eq 0) {  
    Write-Warning "指定VPCにInterfaceタイプのVPCエンドポイントはありません。"  
    exit  
}  
  
# チェック対象のサービス名のキーワード（Fleet Manager関連のSSM系）  
$targetServiceKeywords = @("ssm", "ec2messages", "ssmmessages")  
  
foreach ($vpcEndpoint in $vpcEndpoints.VpcEndpoints) {  
    $serviceName = $vpcEndpoint.ServiceName  
    # サービス名にターゲットキーワードが含まれているかチェック  
    $matched = $false  
    foreach ($keyword in $targetServiceKeywords) {  
        if ($serviceName -like "*$keyword*") {  
            $matched = $true  
        }  
    }  
    if (-not $matched) {  
        continue  
    }  
  
    Write-Host "--------------------------------------------"  
    Write-Host "VPC Endpoint ID: $($vpcEndpoint.VpcEndpointId)"  
    Write-Host "サービス名: $serviceName"  
    Write-Host "ステータス: $($vpcEndpoint.State)"  
    Write-Host "DNS名: $($vpcEndpoint.DnsEntries | ForEach-Object { $_.DnsName })"  
  
    $sgIds = $vpcEndpoint.Groups | ForEach-Object { $_.GroupId }  
  
    if ($sgIds.Count -eq 0) {  
        Write-Warning "アタッチされているセキュリティグループがありません。"  
        continue  
    }  
  
    Write-Host "アタッチされているセキュリティグループ:"  
    foreach ($sgId in $sgIds) {  
        Write-Host " - $sgId"  
  
        # セキュリティグループの詳細を取得  
        $sgJson = aws ec2 describe-security-groups --group-ids $sgId  
        $sg = $sgJson | ConvertFrom-Json  
  
        foreach ($securityGroup in $sg.SecurityGroups) {  
            Write-Host " セキュリティグループ名: $($securityGroup.GroupName)"  
            Write-Host " 説明: $($securityGroup.Description)"  
  
            Write-Host " インバウンドルール:"  
            foreach ($rule in $securityGroup.IpPermissions) {  
                $fromPort = if ($null -ne $rule.FromPort) { $rule.FromPort } else { "All" }  
                $toPort = if ($null -ne $rule.ToPort) { $rule.ToPort } else { "All" }  
                $protocol = if ($rule.IpProtocol -eq "-1") { "ALL" } else { $rule.IpProtocol }  
  
                # IP範囲  
                $ipRanges = ($rule.IpRanges | ForEach-Object { $_.CidrIp }) -join ", "  
                $ipv6Ranges = ($rule.Ipv6Ranges | ForEach-Object { $_.CidrIpv6 }) -join ", "  
                $prefixLists = ($rule.PrefixListIds | ForEach-Object { $_.PrefixListId }) -join ", "  
                $userIdGroupPairs = ($rule.UserIdGroupPairs | ForEach-Object { $_.GroupId }) -join ", "  
  
                Write-Host ("  プロトコル: {0}, ポート: {1} - {2}" -f $protocol, $fromPort, $toPort)  
                if ($ipRanges) { Write-Host "   IPv4レンジ: $ipRanges" }  
                if ($ipv6Ranges) { Write-Host "   IPv6レンジ: $ipv6Ranges" }  
                if ($prefixLists) { Write-Host "   プレフィックスリスト: $prefixLists" }  
                if ($userIdGroupPairs) { Write-Host "   セキュリティグループ: $userIdGroupPairs" }  
            }  
  
            Write-Host " アウトバウンドルール:"  
            foreach ($rule in $securityGroup.IpPermissionsEgress) {  
                $fromPort = if ($null -ne $rule.FromPort) { $rule.FromPort } else { "All" }  
                $toPort = if ($null -ne $rule.ToPort) { $rule.ToPort } else { "All" }  
                $protocol = if ($rule.IpProtocol -eq "-1") { "ALL" } else { $rule.IpProtocol }  
  
                $ipRanges = ($rule.IpRanges | ForEach-Object { $_.CidrIp }) -join ", "  
                $ipv6Ranges = ($rule.Ipv6Ranges | ForEach-Object { $_.CidrIpv6 }) -join ", "  
                $prefixLists = ($rule.PrefixListIds | ForEach-Object { $_.PrefixListId }) -join ", "  
                $userIdGroupPairs = ($rule.UserIdGroupPairs | ForEach-Object { $_.GroupId }) -join ", "  
  
                Write-Host ("  プロトコル: {0}, ポート: {1} - {2}" -f $protocol, $fromPort, $toPort)  
                if ($ipRanges) { Write-Host "   IPv4レンジ: $ipRanges" }  
                if ($ipv6Ranges) { Write-Host "   IPv6レンジ: $ipv6Ranges" }  
                if ($prefixLists) { Write-Host "   プレフィックスリスト: $prefixLists" }  
                if ($userIdGroupPairs) { Write-Host "   セキュリティグループ: $userIdGroupPairs" }  
  
                # 判定例: Fleet Manager用VPCエンドポイントの許可例として、HTTPS(443) TCP許可をIPv4プライベートネットワーク（例: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16）に限定し、  
                # その他の許可は警告とする単純例  
                $isValidPort = ($protocol -in @("tcp", "TCP")) -and ($fromPort -le 443) -and ($toPort -ge 443)  
                $isValidIpRange = $false  
                if ($ipRanges) {  
                    foreach ($cidr in $ipRanges -split ",") {  
                        $cidrTrim = $cidr.Trim()  
                        if (  
                            $cidrTrim.StartsWith("10.") -or  
                            ($cidrTrim -match "^172\.1[6-9]\." ) -or  
                            ($cidrTrim -match "^172\.2[0-9]\.") -or  
                            ($cidrTrim -match "^172\.3[0-1]\.") -or  
                            $cidrTrim.StartsWith("192.168.")  
                        ) {  
                            $isValidIpRange = $true  
                            break  
                        }  
                    }  
                }  
  
                if ($isValidPort -and $isValidIpRange) {  
                    Write-Host "  => [OK] 設定は Fleet Manager 用の一般的な要件に合致しています。" -ForegroundColor Green  
                }  
                else {  
                    Write-Warning "  => [警告] 設定が一般的な Fleet Manager 用の推奨設定と異なります。確認してください。"  
                }  
            }  
        }
    }
}
}