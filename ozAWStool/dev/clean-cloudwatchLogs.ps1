


function Clean-Cloudwatch-Logs {  
    <#
.SYNOPSIS
    cloudwatchLogsのlambda関連のいらないロググループを検索・削除する
.DESCRIPTION
    引数なしで起動すると、ロググループだけが残っているLambda関数の一覧を表示する
    -delete をつけて実行するとロググループを消す
.PARAMETER delete
    削除する（これがないと検索のみ）
.EXAMPLE
    Clean-Cloudwatch-Logs　-delete 
.NOTES
    date: 2025/06/25
    author:ozaki
#>

    [CmdletBinding()]  
    param(  
        [switch]$delete
    )  

  


    $json = aws logs describe-log-groups
    $psJson = $json | ConvertFrom-Json
    $topLevelProp = ($psJson | Get-Member -MemberType  NoteProperty)[0].Name

    $functions = @{}
    foreach ($obj in $psjSON.$topLevelProp) { 
        #$obj 
        # $nameTag = $obj.Tags | Where-Object { $_.Key -eq 'Name' }  
        # $name = if ($nameTag) { $nameTag.Value } else { "" }  
  
        if ($obj.logGroupName -match '^/aws/lambda/.*') { 
            $functions.Add($obj.logGroupName.SubString(12), $obj.logGroupName)
        }
    }



    $json = aws lambda list-functions 
    $psJson = $json | ConvertFrom-Json
    $topLevelProp = ($psJson | Get-Member -MemberType  NoteProperty)[0].Name

    foreach ($obj in $psjSON.$topLevelProp) { 
        #$obj 
        # $nameTag = $obj.Tags | Where-Object { $_.Key -eq 'Name' }  
        # $name = if ($nameTag) { $nameTag.Value } else { "" }  
        $fname = $obj.FunctionName
        if ($functions.ContainsKey($fname)) {
            $functions.remove($fname)
            Write-Verbose ("exists function :  $fname")

        }
    }


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
}
