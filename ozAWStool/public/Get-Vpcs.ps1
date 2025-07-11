
function Get-Vpcs {
    <#
.SYNOPSIS
    Vpcを一覧でCsv出力する
.DESCRIPTION
    Vpcを一覧でCsv出力する
.EXAMPLE
    Rename-Subnet -Name testSubnet2 -newName subnet-Project-A-1c
.EXAMPLE
    Rename-Subnet -ID subnet-09876543210abcdef subnet-Project-A-1c
.EXAMPLE
    Rename-Subnet -ID subnet-09876543210abcdef subnet-Project-A-1c -dry

#>
    [CmdletBinding()]  
    param(  
        #    
    )  
  
 
    try {  
        $json = aws ec2 describe-vpcs

        if ($LASTEXITCODE -ne 0) {  
            Write-Error "aws cliの実行に失敗しました。エラー: $json"  
            return  
        }  
    }
    catch {  
        Write-Error "aws cliの実行中に例外が発生しました: $_"  
        return  
    }  
      
    $result = ($json | convertFrom-Json).Vpcs | foreach-object {
        

            $nameTag = $_.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -ExpandProperty value 
            if (-not $nameTag) { $nameTag = "<no name>" }


            [PSCustomObject]@{
                Name        = $nameTag
                VpcId       = $_.VpcId
                CidrBlock = $_.CidrBlock
            }
    }  
    $result
}
 