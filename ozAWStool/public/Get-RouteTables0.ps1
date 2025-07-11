
function Get-RouteTables {
    <#
.SYNOPSIS
    RouteTableを一覧でCsv出力する
.DESCRIPTION
    RouteTableを一覧でCsv出力する

#>
    [CmdletBinding()]  
    param(  
        #    [string]$OutputPath = "./ec2_instances.csv"  
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
      
    $result = ($json | convertFrom-Json).RouteTables | foreach-object {
        

        $nameTag = $_.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -ExpandProperty value 
        if (-not $nameTag) { $nameTag = "<no name>" }

        $routes = New-Object System.Collections.Generic.List[string]
        $_.Routes | ForEach-Object { 
            $cidr = $_.DestinationCidrBlock 
            
            $x="GatewayId" ;$y = $_.$x ;
            if ($null -ne $y ) {$target=$y}
            else {
                $x="TransitGatewayId" ;$y = $_.$x ;
                if ($null -ne $y ) {$target=$y}
            }
            
            $routes.add("$target($cidr)")
            
        }

        $assocs = New-Object System.Collections.Generic.List[string]
        $_.Associations | ForEach-Object { 
            $assocs.add($_.subnetId)
        }



        [PSCustomObject]@{
            Name         = $nameTag
            RouteTableId = $_.RouteTableId
            Route        = $routes -join(",")
            Associations = $assocs -join(",")
                
        }
    }  
    $result

}  