#i-0c0023f312a1d2d7b

function Check-AmazonSSMManagedInstanceCore {

# チェックしたいEC2インスタンスIDをここに入力してください  
[cmdletbinding()]
PARAM(
    [string]$instanceId  
)
# 1. EC2インスタンス情報を取得  
$instanceJson = aws ec2 describe-instances --instance-ids $instanceId  
if (-not $instanceJson) {  
    Write-Error "インスタンス $instanceId が見つかりません。"  
    exit 1  
}  
  
$instanceData = $instanceJson | ConvertFrom-Json  
  
# 2. インスタンスプロファイルARNを取得  
$instanceProfileArn = $instanceData.Reservations[0].Instances[0].IamInstanceProfile.Arn  
  
if (-not $instanceProfileArn) {  
    Write-Error "EC2インスタンスにIAMインスタンスプロファイルがアタッチされていません。"  
    exit 1  
}  
  
# 3. インスタンスプロファイル名をARNから切り出す（arn:aws:iam::123456789012:instance-profile/プロファイル名）  
$instanceProfileName = $instanceProfileArn.Split('/')[-1]  
  
# 4. インスタンスプロファイルの詳細情報を取得  
$instanceProfileJson = aws iam get-instance-profile --instance-profile-name $instanceProfileName  
$instanceProfile = $instanceProfileJson | ConvertFrom-Json  
  
# 5. インスタンスプロファイルに紐づくロールを取得  
$roles = $instanceProfile.InstanceProfile.Roles  
  
if ($roles.Count -eq 0) {  
    Write-Error "インスタンスプロファイルに関連付けられたロールがありません。"  
    exit 1  
}  
  
# 6. 各ロールにポリシー 'AmazonSSMManagedInstanceCore' がアタッチされているか確認  
$targetPolicyName = "AmazonSSMManagedInstanceCore"  
$found = $false  
  
foreach ($role in $roles) {  
    $roleName = $role.RoleName  
    Write-Host "ロール '$roleName' のポリシーをチェックしています..."  
  
    # アタッチされているマネージドポリシーを取得  
    $attachedPoliciesJson = aws iam list-attached-role-policies --role-name $roleName  
    $attachedPolicies = $attachedPoliciesJson | ConvertFrom-Json  
  
    foreach ($policy in $attachedPolicies.AttachedPolicies) {  
        if ($policy.PolicyName -eq $targetPolicyName) {  
            Write-Host "ロール '$roleName' にポリシー '$targetPolicyName' がアタッチされています。"  
            $found = $true  
        }  
    }  
}  
  
if (-not $found) {  
    Write-Warning "ポリシー '$targetPolicyName' はインスタンスにアタッチされたロールに付与されていません。"  
}  
}