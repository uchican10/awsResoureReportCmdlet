
function Get-Ec2s {
    <#
.SYNOPSIS
    Subnetを一覧でCsv出力する
.DESCRIPTION
    Subnet名をRenameする
    Subnetの指定は -Nameでの旧名指定（デフォルト）　または　-IDでのID指定　のどちらか
    内部ではaws cliを使用している
.PARAMETER Vpc
    変更対象となるSubnet名
.EXAMPLE
    Rename-Subnet testSubnet1 subnet-Project-A-1a
.EXAMPLE
    Rename-Subnet -Name testSubnet2 -newName subnet-Project-A-1c
.EXAMPLE
    Rename-Subnet -ID subnet-09876543210abcdef subnet-Project-A-1c
.EXAMPLE
    Rename-Subnet -ID subnet-09876543210abcdef subnet-Project-A-1c -dry

#>
    [CmdletBinding()]  
    param(  
        #    [string]$OutputPath = "./ec2_instances.csv"  
    )  
  
    $delimit1="#"
    # AWS CLIでEC2インスタンス情報をJSON取得  
    try {  
        $json = aws ec2 describe-instances

        if ($LASTEXITCODE -ne 0) {  
            Write-Error "aws cliの実行に失敗しました。エラー: $json"  
            return  
        }  
    }
    catch {  
        Write-Error "aws cliの実行中に例外が発生しました: $_"  
        return  
    }  
      
    $result = ($json | convertFrom-Json).Reservations | foreach-object {
        $_.Instances | foreach-object {
            $instanceId = $_.InstanceId
            $nameTag = $_.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -ExpandProperty value 
            if (-not $nameTag) { $nameTag = "<no name>" }

            $sgs = New-Object System.Collections.Generic.List[string]
            $_.SecurityGroups | ForEach-Object { 
                $gname=$_.GroupName
                $gid=$_.GroupId

                $sgs.add("$gname($gid)") 
            }

            $state=$_.State.Name

            $rolearn=$_.IamInstanceProfile.Arn
            if ($rolearn) {
                $index=$rolearn.lastindexof("/")
                $role=$rolearn.substring($index+1)
            }

            [PSCustomObject]@{
                InstanceName             = $nameTag
                InstanceId       = $instanceId
                Role    =$role
                State=$state
                PrivateIpAddress = $_.PrivateIpAddress
                VpcId            = $_.VpcId
                SubnetId         = $_.SubnetId
                InstanceType     = $_.InstanceType
                SecurityGroup    = $sgs -join $delimit1
            }
            
        }
    }  
    $result
}
 