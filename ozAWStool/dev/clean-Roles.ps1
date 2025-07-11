


function Clean-Roles {  
    <#
.SYNOPSIS
    Roleのlambda関連のいらないロールを検索・削除する
.DESCRIPTION
    引数なしで起動すると、ロールだけが残っているLambda関数の一覧を表示する
    -delete をつけて実行するとロールを消す
.PARAMETER delete
    削除する（これがないと検索のみ）
.EXAMPLE
    Clean-Roles　-delete 
.NOTES
    date: 2025/06/25
    author:ozaki
#>

    [CmdletBinding()]  
    param(  
        [switch]$delete
    )  

  


    $json = aws iam list-roles
    $psJson = $json | ConvertFrom-Json
    $topLevelProp = ($psJson | Get-Member -MemberType  NoteProperty)[0].Name

    $functions = @{}
    $roles=@{}
    foreach ($obj in $psjSON.$topLevelProp) { 
        #$obj 
        # $nameTag = $obj.Tags | Where-Object { $_.Key -eq 'Name' }  
        # $name = if ($nameTag) { $nameTag.Value } else { "" }  
  
        $service=$obj.AssumeRolePolicyDocument.Statement[0].Principal.Service
        if (-not $service){
            $service="F)" + $obj.AssumeRolePolicyDocument.Statement[0].Principal.Federated
            if ($service -eq "F)"){
                $service="A)" + $obj.AssumeRolePolicyDocument.Statement[0].Principal.AWS
            }
        }
        $RoleName=$obj.$RoleName

        [PSCustomObject]@{  
            Path = $obj.path
            RoleName=$obj.RoleName
            Service=$service               
        }


    }



<#
    $functions.GetEnumerator() | % {
        [PSCustomObject]@{  
            ghost_functionName = $_.Name
            ghost_logGroupName = $_.Value                
        }
    }
    if ($delete) { 
        $functions.GetEnumerator() | % {
            aws logs delete-log-group --log-group-name $_.Value  
        }
    }
#>

    }
