function Get-SecurityGroups {  
    [CmdletBinding()]  
    param(  
        #
    )  
    <#
    # AWS CLI コマンドのベース  
 
    $awsCli = " aws ec2 describe-route-tables"  
  
    try {  
        $routeTablesJson = & $awsCli | ConvertFrom-Json  
    }  
    catch {  
        Write-Error "AWS CLIからのデータ取得に失敗しました。AWS CLIがインストールされているか、設定が正しいか確認してください。"  
        return  
    }  
  #>
    $delimit1="#" 
    
    $json = aws ec2 describe-security-groups
    $psJson = $json | ConvertFrom-Json
    $topLevelProp = ($psJson | Get-Member -MemberType  NoteProperty)[0].Name

    $result = foreach ($obj in $psjSON.$topLevelProp) { 
        $sg = $obj
        # セキュリティグループのタグからNameの値を取得（存在すれば）  
        $nameTag = $sg.Tags | Where-Object { $_.Key -eq "Name" }  
        $name = if ($nameTag) { $nameTag.Value } else { "<<no name>>" }  
  
        # Security Group Identifier (GroupNameの代わりにGroupIdなどを使う場合もあります)  
        $groupName = $sg.GroupName  
          
        # セキュリティグループの説明  
        $description = $sg.Description  
  
        # VpcId  
        $vpcId = $sg.VpcId  
  
        # 3. Inboundルール処理  
        $inboundRules = $sg.IpPermissions  
        $inboundList = foreach ($rule in $inboundRules) {  
            # ポート範囲を決定（FromPort と ToPort が同じなら単一ポートを使う）  
            $fromPort = $rule.FromPort  
            $toPort = $rule.ToPort  
  
            if ($null -eq $fromPort) {  
                # ポート指定がない場合（例：ICMPなど）は"all"で表現  
                $portStr = "all"  
            }  
            elseif ($fromPort -eq $toPort) {  
                $portStr = $fromPort.ToString()  
            }  
            else {  
                $portStr = "$fromPort-$toPort"  
            }  
  
            # IpRangesのそれぞれに対して文字列を作成  
            foreach ($ipRange in $rule.IpRanges) {  
                $cidr = $ipRange.CidrIp  
                # 説明があれば取得、なければ空文字  
                $desc = if ($ipRange.Description) { $ipRange.Description } else { "" }  
  
                "<$portStr>$cidr($desc)"  
            }  
        }  
  
        $inboundString = $inboundList -join $delimit1  
  
        # 4. Outboundルール処理（同様）  
        $outboundRules = $sg.IpPermissionsEgress  
        $outboundList = foreach ($rule in $outboundRules) {  
            $fromPort = $rule.FromPort  
            $toPort = $rule.ToPort  
  
            if ($null -eq $fromPort) {  
                $portStr = "all"  
            }  
            elseif ($fromPort -eq $toPort) {  
                $portStr = $fromPort.ToString()  
            }  
            else {  
                $portStr = "$fromPort-$toPort"  
            }  
  
            foreach ($ipRange in $rule.IpRanges) {  
                $cidr = $ipRange.CidrIp  
                $desc = if ($ipRange.Description) { $ipRange.Description } else { "" }  
  
                 "<$portStr>$cidr($desc)"   
            }  
        }  
  
        $outboundString = $outboundList -join $delimit1
  

        
        [PSCustomObject]@{  
            Name        = $name  
            VpcId       = $vpcId  
            GroupName   = $groupName  
            Description = $description  
            Inbound     = $inboundString  
            Outbound    = $outboundString  
        } 
    }  
    $result
  

}  