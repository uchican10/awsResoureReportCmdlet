function Get-RoleList {  
<#  
.SYNOPSIS  
    指定した日付以降に作成されたAWS IAMロールの一覧を取得します。  
  
.DESCRIPTION  
    この関数は、引数で渡した日付（yyyymmdd形式）以降に作成されたIAMロールをAWS CLIとjqを使って取得します。  
    ロールの作成日時をもとにフィルターをかけ、該当するロールのRoleNameとCreateDateをPowerShellオブジェクトとして返します。  
    AWS Tools for PowerShell を使わずにAWS CLI環境下で動作します。  
  
.PARAMETER SinceDateString  
    ロール作成日の抽出基準日をyyyymmdd形式の文字列で指定します。  
    例: 20240601 → 2024年6月1日0時(UTC)以降に作成されたロールを取得。  
  
.EXAMPLE  
    Get-RoleList -SinceDateString 20240601  
    # 2024年6月1日00:00:00 UTC以降に作成されたIAMロールの一覧を取得し表示します。  
  
.EXAMPLE  
    $roles = Get-RoleList -SinceDateString 20240101  
    $roles | Format-Table RoleName, CreateDate -AutoSize  
    # 2024年1月1日以降に作成されたロールを変数に格納し、表形式で表示します。  
#>  
   [CmdletBinding()]
    param(  
        #
    )  
  
    # AWS CLIでロール一覧を取得  
    $rawJson = aws iam list-roles  
  
    if (-not $?) {  
        Write-Error "aws cli コマンドの実行に失敗しました。"  
        return  
    }  
  
    
    # jq で指定日以降に作成されたロールを抽出、RoleNameとCreateDateを出力  
 # $filteredRoles = $rawJson | jq  -rc '.Roles[] | select(.Path != "/")  | [.RoleName, .CreateDate, .Path , .AssumeRolePolicyDocument.Statement]'  
 $filteredRoles = $rawJson | jq  -rc '.Roles[]   | {Path:.Path , RoleName:.RoleName, RoleId:.RoleId, CreateDate:.CreateDate ,Principals : ([.AssumeRolePolicyDocument.Statement[]|.Principal.Service]|map("\(.)"|join(";") )|
 [.Path,.RoleName,.RoleId,.CreaeDate,.Principals   ]]|@csv'  
  
    if (-not $filteredRoles) {  
        Write-Host "IAMロールは見つかりませんでした。"  
        return  
    }  
$header="Path,RoleName,RoleId,CreaeDate,Principals"
$header
$filteredRoles
    }  
 