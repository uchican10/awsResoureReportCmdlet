
function Publish-ami {

    <#
.SYNOPSIS
    AMIを共有する
.DESCRIPTION
    AMIを共有する
    AMIid　と　共有先アカウントid　を引数で受け取る
    KMSkeyの共有はここでは行わない。別に行う事。
    AMI自体の共有とEBSの共有を行う。このスクリプトを使うと張り付けられているEBSスナップショットを探す手間がなくなる
.PARAMETER amiId
    共有する amiId
.PARAMETER accountids
    共有対象のアカウントId(複数カンマ区切り)
.EXAMPLE
    publish-ami -amiId ami-9876543210987 -accountIds  3456789012 -region ap-northeast-1
.EXAMPLE
    publish-ami ami-9876543210987  3456789012,4567890123

.NOTES
    date: 2025/06/24
    author:ozaki
    
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$amiId,
        [Parameter(Position = 1 , Mandatory = $true)]
        [string]$accountIds, 
        [string]$region = "ap-northeast-1"
    
    )

  
    # モジュールのインポート（インストール済み前提）  
    Import-Module AWS.Tools.EC2  
  
    # 共有先のアカウントにAMIを共有  
    Write-Host "Sharing AMI $amiId with account $targetAccountId..."  
  
    # AMIの情報を取得  
    $ami = Get-EC2Image -ImageId $amiId -Region $region  
  
    if (-not $ami) {  
        Write-Error "AMI $amiId が見つかりません。"  
        exit 1  
    }  

    #  カンマ区切りから @{UserId=xxxx} の配列を作成（-LaunchPermissuib_Addに渡す配列）
    $accountIdList = $accountIds -split ',' | ForEach-Object { @{UserId = $_ } } 

    # AMIのLaunchPermissionに対象アカウントを追加  
    Edit-EC2ImageAttribute `
        -ImageId $amiId `
        -Region $region `
        -LaunchPermission_Add $accountIdList
  
    Write-Host "AMI共有設定完了。"  
  
    # AMIに紐づくスナップショットを共有  
    foreach ($bdm in $ami.BlockDeviceMappings) {  
  
        if ($bdm.Ebs) {  
            $snapshotId = $bdm.Ebs.SnapshotId  
            if ($null -eq $snapshotId) {  
                Write-Host "スナップショットIDが見つかりません。"  
                continue  
            }  
  
            Write-Host "Sharing snapshot $snapshotId with account $accountId..."  
  

  
            # スナップショットの共有設定を追加  
            Edit-EC2SnapshotAttribute `
                -SnapshotId $snapshotId `
                -CreateVolumePermission_Add $accountIdList

            Write-Host "スナップショット $snapshotId を共有しました。"  
        }  
    }  
  
    Write-Host "AMIとスナップショットの共有処理が完了しました。" 
}


