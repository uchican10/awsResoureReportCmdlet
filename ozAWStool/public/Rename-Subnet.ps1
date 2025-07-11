
function Rename-Subnet {

    <#
.SYNOPSIS
    Subnet名をRenameする
.DESCRIPTION
    Subnet名をRenameする
    Subnetの指定は -Nameでの旧名指定（デフォルト）　または　-IDでのID指定　のどちらか
    内部ではaws cliを使用している
.PARAMETER Name
    変更対象となるSubnet名
.PARAMETER ID   
    変更対象となるSubnetId
.PARAMETER newName
    変更後のSubnet名
.PARAMETER dry
    実行せずaws cli コマンド列の表示のみ行う
.EXAMPLE
    Rename-Subnet testSubnet1 subnet-Project-A-1a
.EXAMPLE
    Rename-Subnet -Name testSubnet2 -newName subnet-Project-A-1c
.EXAMPLE
    Rename-Subnet -ID subnet-09876543210abcdef subnet-Project-A-1c
.EXAMPLE
    Rename-Subnet -ID subnet-09876543210abcdef subnet-Project-A-1c -dry

#>
    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "ByName")]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [string]$ID, 
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$newName,  
        [switch]$dry
    
    )

    # サブネットIDを取得  
    switch ($PSCmdlet.ParameterSetName) {  
        'ByName' {
            $subnetId = aws ec2 describe-subnets --filters "Name=tag:Name,Values=$Name" --query "Subnets[0].SubnetId" --output text  
            if ($subnetId -eq "None" -or [string]::IsNullOrEmpty($subnetId)) {  
                Throw "サブネット名 '$Name' のサブネットが見つかりませんでした。"  
                exit 1  
            }  
        }
        'ById' {  
            Write-Host "ID $ID のサブネットを新しい名前 $NewName に変更します。"  
            $subnetId = $ID
        }  
        default {  
            Throw "無効なパラメータセットです。"  
        }  
    }
  
    # タグを作成（Nameタグを上書き）  
    if ($dry) {
        Write-Host("# dry")
        Write-Host("aws ec2 create-tags --resources $subnetId --tags Key=Name,Value=$newName  ")
    }
    else {
           
        aws ec2 create-tags --resources $subnetId --tags "Key=Name, Value=$newName"   
        if ($LASTEXITCODE -eq 0) {
            switch ($PSCmdlet.ParameterSetName) {  
                'ByName' {
                    Write-Host "サブネット '$Name' ($subnetId) の名前を '$newName' に変更しました。"
    
                }
                'ById' {  
                    Write-Host "サブネット $subnetId の名前を '$newName' に変更しました。"
                }  
      
            }
        } 
    }  
}


