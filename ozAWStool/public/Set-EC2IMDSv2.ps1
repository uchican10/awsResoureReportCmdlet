function Set-EC2IMDSv2 {  
    param(  
        [Parameter(ParameterSetName='ByName', Mandatory=$true)]  
        [string] $InstanceName,  
  
        [Parameter(ParameterSetName='ByNames', Mandatory=$true)]  
        [string[]] $InstanceNames,  
  
        [Parameter(ParameterSetName='ById', Mandatory=$true)]  
        [string] $InstanceId,  
  
        [Parameter(ParameterSetName='ByIds', Mandatory=$true)]  
        [string[]] $InstanceIds  
    )  
  
    # タグ"Name"の値からインスタンスID一覧を取得する関数  
    function Get-InstanceIdsByName {  
        param(  
            [string] $Name  
        )  
        $json = aws ec2 describe-instances --filters "Name=tag:Name,Values=$Name" | ConvertFrom-Json  
        $ids = @()  
        foreach ($reservation in $json.Reservations) {  
            foreach ($instance in $reservation.Instances) {  
                $ids += $instance.InstanceId  
            }  
        }  
        return $ids  
    }  
  
    # インスタンスIDの一覧作成  
    $targetInstanceIds = @()  
  
    switch ($PSCmdlet.ParameterSetName) {  
        'ByName' {  
            $ids = Get-InstanceIdsByName -Name $InstanceName  
            if (-not $ids -or $ids.Count -eq 0) {  
                Write-Warning "タグName=$InstanceName のインスタンスが見つかりません。"  
            }  
            $targetInstanceIds += $ids  
        }  
        'ByNames' {  
            foreach ($name in $InstanceNames) {  
                $ids = Get-InstanceIdsByName -Name $name  
                if (-not $ids -or $ids.Count -eq 0) {  
                    Write-Warning "タグName=$name のインスタンスが見つかりません。"  
                }  
                $targetInstanceIds += $ids  
            }  
        }  
        'ById' {  
            $targetInstanceIds += $InstanceId  
        }  
        'ByIds' {  
            $targetInstanceIds += $InstanceIds  
        }  
        default {  
            throw "パラメータセットの指定が間違っています。"  
        }  
    }  
  
    if (-not $targetInstanceIds -or $targetInstanceIds.Count -eq 0) {  
        throw "処理対象のEC2インスタンスが見つかりません。"  
    }  
  
    # IMDSv2を有効化（HttpTokens=requiredへ変更）  
    foreach ($id in $targetInstanceIds) {  
        Write-Verbose "インスタンスID $id にIMDSv2を有効化中..."  
        $result = aws ec2 modify-instance-metadata-options `
            --instance-id $id `
            --http-tokens required 2>&1  
  
        if ($LASTEXITCODE -eq 0) {  
            Write-Output "インスタンスID $id のIMDSv2設定を更新しました。"  
        } else {  
            Write-Warning "インスタンスID $id のIMDSv2設定更新に失敗しました。エラー: $result"  
        }  
    }  
}  