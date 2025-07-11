
function Get-Subnets
 {
<#
.SYNOPSIS
    Subnetを一覧出力する
.DESCRIPTION
    Subnetを一覧出力する
.EXAMPLE
    Get-Subnets

#>
    [CmdletBinding()]  
      param(  
    #    [string]$OutputPath = "./ec2_instances.csv"  
    )  



    try {  
        $json = aws ec2 describe-subnets

        if ($LASTEXITCODE -ne 0) {  
            Write-Error "aws cliの実行に失敗しました。エラー: $json"  
            return  
        }  
    }
    catch {  
        Write-Error "aws cliの実行中に例外が発生しました: $_"  
        return  
    }  
      
    $result = ($json | convertFrom-Json).Subnets | foreach-object {
        

            $nameTag = $_.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -ExpandProperty value 
            if (-not $nameTag) { $nameTag = "<no name>" }


            [PSCustomObject]@{
                Name        = $nameTag
                VpcId       = $_.VpcId
                CidrBlock = $_.CidrBlock
                SubnetId = $_.SubnetId
                
            }
    }  
    $result
}  