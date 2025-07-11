#以下のpowershell Cmdletを作ってください
#
#aws cliとjqが使えます
#AMIidと共有アカウント（複数カンマ区切り）を指定します
#
#AMIを指定アカウントに共有します
#AMIが使っているEBSスナップショットを指定アカウントに共有します
#パラメータとしては、リージョンも指定できるようにしてください。ただしデフォルトap-northeast-1で省略可能です


function Grant-AmiAndSnapshots {  
    [CmdletBinding()]  
    param (  
        [Parameter(Mandatory=$true)]  
        [string]$AmiId,  
  
        [Parameter(Mandatory=$true)]  
        [string]$SharedAccountIds,  # カンマ区切りの複数アカウントID  
  
        [string]$Region = "ap-northeast-1"  
    )  
  
    # 分割して配列に  
    $accounts = $SharedAccountIds.Split(',') | ForEach-Object { $_.Trim() }  
  
    Write-Host "AMI ID: $AmiId"  
    Write-Host "共有対象アカウント: $($accounts -join ', ')"  
    Write-Host "リージョン: $Region"  
    Write-Host ""  
  
    # 1. AMIを共有する  
    try {  
        Write-Host "AMIの共有を設定しています..."  
        aws ec2 modify-image-attribute `
            --image-id $AmiId `
            --region $Region `
            --launch-permission "Add=[{UserId=$($accounts -join '},{UserId=')}]" | Out-Null  
        Write-Host "AMIの共有設定が完了しました。"  
    } catch {  
        Write-Error "AMIの共有設定に失敗しました: $_"  
        return  
    }  
  
    # 2. AMIに紐づくスナップショットIDを取得する  
    Write-Host "AMIに関連するEBSスナップショットを取得します..."  
    $describe = aws ec2 describe-images --image-ids $AmiId --region $Region --output json  
    if (-not $describe) {  
        Write-Error "AMI情報の取得に失敗しました。"  
        return  
    }  
  
    # jqを使用してBlockDeviceMappings[].Ebs.SnapshotIdを抽出 (null除外)  
    $snapshotIds = $describe | jq -r '.Images[0].BlockDeviceMappings[].Ebs.SnapshotId // empty'  
  
    if (-not $snapshotIds) {  
        Write-Host "AMIに関連するスナップショットはありません。"  
        return  
    }  
  
    Write-Host "共有対象のスナップショット："  
    $snapshotIds | ForEach-Object { Write-Host "- $_" }  
  
    # 3. スナップショットを指定アカウントに共有  
    foreach ($snapshotId in $snapshotIds) {  
        try {  
            Write-Host "スナップショット $snapshotId を共有設定中..."  
            aws ec2 modify-snapshot-attribute `
                --snapshot-id $snapshotId `
                --region $Region `
                --attribute createVolumePermission `
                --operation-type add `
                --user-ids $accounts | Out-Null  
            Write-Host "スナップショット $snapshotId の共有設定が完了しました。"  
        } catch {  
            Write-Warning "スナップショット $snapshotId の共有設定に失敗しました: $_"  
        }  
    }  
  
    Write-Host "すべての処理が完了しました。"  
}  


#使い方例
 


## AMIを複数アカウント(123456789012, 987654321098)に共有し、  
## リージョンはデフォルト(ap-northeast-1)を使う場合  
#Share-AmiAndSnapshots -AmiId ami-0abcdef1234567890 -SharedAccountIds "123456789012,987654321098"  
#  
## リージョンを指定する場合（例: us-east-1）  
#Share-AmiAndSnapshots -AmiId ami-0abcdef1234567890 -SharedAccountIds "123456789012,987654321098" -Region us-east-1  
 