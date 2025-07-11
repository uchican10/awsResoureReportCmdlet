function Get-EC2RoleList{
    [CmdletBinding()]
    Param()
# EC2インスタンス情報を取得  
$instancesJson = aws ec2 describe-instances | ConvertFrom-Json  
  
# 各インスタンスに対して処理  
$instanceList = foreach ($reservation in $instancesJson.Reservations) {  
    foreach ($instance in $reservation.Instances) {  
        # InstanceIdの取得  
        $instanceId = $instance.InstanceId  
  
        # TagのNameを取得（なければ空文字）  
        $nameTag = ($instance.Tags | Where-Object { $_.Key -eq "Name" }).Value  
        if (-not $nameTag) {  
            $nameTag = ""  
        }  
  
        # IAMインスタンスプロファイルARNを取得  
        $profileArn = if ($instance.IamInstanceProfile) { $instance.IamInstanceProfile.Arn } else { "" }  
  
        $roleName = ""  
        if ($profileArn) {  
            # インスタンスプロファイル名をARNから取得  
            # arn:aws:iam::123456789012:instance-profile/プロファイル名  
            $profileName = $profileArn.Split("/")[-1]  
  
            # インスタンスプロファイル詳細取得  
            $profileJson = aws iam get-instance-profile --instance-profile-name $profileName | ConvertFrom-Json  
  
            # ロール名を取得（複数ある可能性ありが通常1つ）  
            if ($profileJson.InstanceProfile.Roles.Count -gt 0) {  
                $roleName = $profileJson.InstanceProfile.Roles[0].RoleName  
            }  
        }  
  
        [PSCustomObject]@{  
            InstanceId = $instanceId  
            Name       = $nameTag  
            RoleName   = $roleName  
        }  
    }  
}  
  
# 結果をテーブル形式で出力  
$instanceList | Format-Table -AutoSize  
}