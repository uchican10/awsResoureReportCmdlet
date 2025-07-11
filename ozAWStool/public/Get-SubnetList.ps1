
function Get-SubnetList
 {
<#
.SYNOPSIS
    Subnetを一覧でCsv出力する
.DESCRIPTION
    Subnetを一覧でCsv出力する
    VPCを指定する機能はつけていない
.EXAMPLE
    Get-SubnetList

#>
    [CmdletBinding()]  
      param(  
    #    [string]$OutputPath = "./ec2_instances.csv"  
    )  
    # AWS CLIでEC2インスタンス情報をJSON取得  
    try {  
        $jsonOutput = aws ec2 describe-subnets  
        if ($LASTEXITCODE -ne 0) {  
            Write-Error "aws cliの実行に失敗しました。エラー: $jsonOutput"  
            return  
        }  
    } catch {  
        Write-Error "aws cliの実行中に例外が発生しました: $_"  
        return  
    }  
      
    # jqで必要情報を抽出  
    try {  
        $csv = $jsonOutput |jq -r '.[][]|[(.Tags[]|select(.Key=="Name")).Value,.SubnetId,.CidrBlock,.VpcId]|@csv'
        
        
    } catch {  
        Write-Error "jqの実行中に例外が発生しました: $_"  
        return  
    }  
  
    # CSVヘッダー  
    $header = "TagName,SubnetId,CidrBlock,VpcId"  
  
    # ファイルへ出力  
    try {  
        $header
        $csv
         #| Out-File -Encoding utf8 -FilePath $OutputPath  
        #Write-Host "EC2インスタンス一覧をCSVに出力しました: $OutputPath"  
    } catch {  
        Write-Error "CSVファイルの書き込み中に例外が発生しました: $_"  
    }  
}  