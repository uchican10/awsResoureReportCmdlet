function Rename-RouteTable {  
    <#.SYNOPSIS  
        ルートテーブルのNameタグを変更する  
    .DESCRIPTION  
        ルートテーブルの指定は -Name（旧Nameタグ指定）または -Id（ルートテーブルID指定）のどちらか  
        内部ではaws cliを使用しています  
    .PARAMETER Name  
        変更対象となるルートテーブルの旧Nameタグ  
    .PARAMETER Id  
        変更対象となるルートテーブルのID（例: rtb-xxxxxx）  
    .PARAMETER NewName  
        変更後のNameタグ値  
    .PARAMETER Dry  
        実行せず、aws cliコマンドを表示するだけのスイッチ  
    .EXAMPLE  
        Rename-RouteTable -Name "OldRouteTableName" -NewName "NewRouteTableName"  
    .EXAMPLE  
        Rename-RouteTable -Id rtb-0123456789abcdef0 -NewName "NewRouteTableName" -Dry  
#>  
    [CmdletBinding(DefaultParameterSetName = "ByName")]  
    param (  
        [Parameter(Position=0, Mandatory=$true, ParameterSetName="ByName")]  
        [string]$Name,  
  
        [Parameter(Mandatory=$true, ParameterSetName="ById")]  
        [string]$Id,  
  
        [Parameter(Position=1, Mandatory=$true)]  
        [string]$NewName,  
  
        [switch]$Dry  
    )  
  
    switch ($PSCmdlet.ParameterSetName) {  
        "ByName" {  
            # aws cliでNameタグからルートテーブルID取得  
            $routeTableId = aws ec2 describe-route-tables --filters "Name=tag:Name,Values=$Name" --query "RouteTables[0].RouteTableId" --output text  
            if ([string]::IsNullOrEmpty($routeTableId) -or $routeTableId -eq "None") {  
                Throw "Nameタグ '$Name' のルートテーブルが見つかりません。"  
                exit 1  
            }  
        }  
        "ById" {  
            Write-Host "ルートテーブルID '$Id' を新しい名前 '$NewName' に変更します。"  
            $routeTableId = $Id  
        }  
        default {  
            Throw "無効なパラメータセットです。"  
        }  
    }  
  
    $cmd = "aws ec2 create-tags --resources $routeTableId --tags Key=Name,Value=$NewName"  
  
    if ($Dry) {  
        Write-Host "# Dry Run - 以下のコマンドを実行予定です。"  
        Write-Host $cmd  
    }  
    else {  
        Write-Host "ルートテーブル $routeTableId の名前を '$NewName' に変更します..."  
        Invoke-Expression $cmd  
  
        if ($LASTEXITCODE -eq 0) {  
            Write-Host "名前変更が完了しました。"  
        }  
        else {  
            Write-Error "名前変更に失敗しました。"  
            exit 1  
        }  
    }  
}  