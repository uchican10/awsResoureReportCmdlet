
function Get-Ec2List
 {
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
  
    # AWS CLIでEC2インスタンス情報をJSON取得  
    try {  
        $jsonOutput = aws ec2 describe-instances --output json 2>&1  
        if ($LASTEXITCODE -ne 0) {  
            Write-Error "aws cliの実行に失敗しました。エラー: $jsonOutput"  
            return  
        }  
    }
    catch {  
        Write-Error "aws cliの実行中に例外が発生しました: $_"  
        return  
    }  
      
    # jqで必要情報を抽出  
    try {  
        $csv = $jsonOutput | jq -r '  
          .Reservations[].Instances[] |  
          {  
            InstanceId: .InstanceId,  
            TagName: (.Tags[]? | select(.Key=="Name") | .Value // ""),  
            SecurityGroups: (  
              [.SecurityGroups[]? | {Id: .GroupId, Name: .GroupName}] |  
              map("\(.Id)(\(.Name))") | join(";")  
            ),  
            PrivateIpAddress: (.PrivateIpAddress // ""),  
            VpcId: (.VpcId // ""),  
            SubnetId: (.SubnetId // ""),  
            InstanceType: (.InstanceType // "")  
          } |   
          [  
            .TagName,
            .InstanceId,  
            .SecurityGroups,  
            .PrivateIpAddress,  
            .VpcId,  
            .SubnetId,  
            .InstanceType 
          ] |  
          @csv  
        ' 
    }
    catch {  
        Write-Error "jqの実行中に例外が発生しました: $_"  
        return  
    }  
  
    # CSVヘッダー  
    $header = "InstanceId,TagName,SecurityGroupId(SecurityGroupName),PrivateIpAddress,VPC,Subnet,InstanceType"  
  
 

    $c = $header + "`n" + ($csv -join "`n")
    $c
   # $c|ConvertFrom-Csv  
}  