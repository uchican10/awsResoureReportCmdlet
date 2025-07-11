function Export-EC2InstancesToCsv {  
    [CmdletBinding()]  
    param(  
        [string]$OutputPath = "./ec2_instances.csv"  
    )  
  
    # AWS CLIでEC2インスタンス情報をJSON取得  
    try {  
        $jsonOutput = aws ec2 describe-instances --output json 2>&1  
        if ($LASTEXITCODE -ne 0) {  
            Write-Error "aws cliの実行に失敗しました。エラー: $jsonOutput"  
            return  
        }  
    } catch {  
        Write-Error "aws cliの実行中に例外が発生しました: $_"  
        return  
    }  
      
    # jqで必要情報を抽出（VpcIdのタグName取得とSubnetIdのタグName取得を追加）  
 
        $csv = $jsonOutput | jq -r '  
          # VPCタグ名を取得する関数 定義  
          def vpc_tagnames:  
            # describe-tagsの出力でもっとも正確にするには別call必要だが、ここはインスタンスのTagsと違うので以下の方法  
            # jqだけでやるためには外部呼び出し必須、ここでは簡易的にEmptyを返す  
            "";  
  
          # Subnetタグ名を取得する関数 こちらも外部呼び出し想定されるが今回は空文字  
          def subnet_tagnames:  
            "";  
  
          .Reservations[].Instances[] as $inst |  
          {  
            InstanceId: $inst.InstanceId,  
            TagName: ($inst.Tags[]? | select(.Key=="Name") | .Value // ""),  
            SecurityGroups: (  
              [$inst.SecurityGroups[]? | {Id: .GroupId, Name: .GroupName}] |  
              map("\(.Id)(\(.Name))") | join(";")  
            ),  
            PrivateIpAddress: ($inst.PrivateIpAddress // ""),  
            VpcIdFull: ($inst.VpcId +   
                (if $inst.VpcId then "(" else "") +  
                ("" ) + # タグ名はここで空文字 placeholder。後でpowershell側で補完します  
                (if $inst.VpcId then ")" else "")),  
            SubnetIdFull: ($inst.SubnetId +  
                (if $inst.SubnetId then "(" else "") +  
                ("" ) + # タグ名はここで空文字 placeholder。後でpowershell側で補完します  
                (if $inst.SubnetId then ")" else "")),  
            VpcId: $inst.VpcId,  
            SubnetId: $inst.SubnetId,  
            InstanceType: ($inst.InstanceType // "")  
          }  
        ' | ConvertFrom-Csv -Header InstanceId,TagName,SecurityGroups,PrivateIpAddress,VpcIdFull,SubnetIdFull,VpcId,SubnetId,InstanceType  
  
# jqのみではVPCタグ名やSubnetタグ名を取得できないため、PowerShellで補完  
# VPCタグ名を取得する関数  
function Get-VpcTagName {  
    param([string]$VpcId)  
    if ([string]::IsNullOrEmpty($VpcId)) { return "" }  
    try {  
        $vpcTagsJson = aws ec2 describe-tags --filters @{ Name="resource-id"; Values=$VpcId }, @{ Name="key"; Values="Name" } --output json 2>$null  
        $vpcTags = $vpcTagsJson | ConvertFrom-Json  
        $tag = $vpcTags.Tags | Where-Object { $_.Key -eq "Name" } | Select-Object -First 1  
        return if ($tag) { $tag.Value } else { "" }  
    } catch {  
        Write-Warning "VPCタグ名の取得に失敗しました: $_"  
        return ""  
    }  
}  
  
# Subnetタグ名を取得する関数  
function Get-SubnetTagName {  
    param([string]$SubnetId)  
    if ([string]::IsNullOrEmpty($SubnetId)) { return "" }  
    try {  
        $subnetTagsJson = aws ec2 describe-tags --filters @{ Name="resource-id"; Values=$SubnetId }, @{ Name="key"; Values="Name" } --output json 2>$null  
        $subnetTags = $subnetTagsJson | ConvertFrom-Json  
        $tag = $subnetTags.Tags | Where-Object { $_.Key -eq "Name" } | Select-Object -First 1  
        return if ($tag) { $tag.Value } else { "" }  
    } catch {  
        Write-Warning "Subnetタグ名の取得に失敗しました: $_"  
        return ""  
    }  
}  
  
# JSONから読み込んだオブジェクトに対し補完処理  
$instanceObjects = $csv | ForEach-Object {  
    # VpcId, SubnetIdは配列の最後の2項目に入っているので取得  
    $vpcId = $_.VpcId  
    $subnetId = $_.SubnetId  
  
    $vpcTagName = Get-VpcTagName -VpcId $vpcId  
    $subnetTagName = Get-SubnetTagName -SubnetId $subnetId  
  
    # VpcIdFull と SubnetIdFull にID(タグ名)形式でセット  
    $vpcIdFull = if ($vpcId) { "$vpcId($vpcTagName)" } else { "" }  
    $subnetIdFull = if ($subnetId) { "$subnetId($subnetTagName)" } else { "" }  
  
    # 出力オブジェクト作成  
    [PSCustomObject]@{  
        InstanceId = $_.InstanceId  
        TagName = $_.TagName  
        SecurityGroups = $_.SecurityGroups  
        PrivateIpAddress = $_.PrivateIpAddress  
        VpcIdFull = $vpcIdFull  
        SubnetIdFull = $subnetIdFull  
        InstanceType = $_.InstanceType  
    }  
}  
  
# CSVヘッダー  
$header = "InstanceId,TagName,SecurityGroupId(SecurityGroupName),PrivateIpAddress,VPC,Subnet,InstanceType"  
  

# 出力用CSV文字列作成  
$outputCsv = $instanceObjects | Select-Object InstanceId, TagName, SecurityGroups, PrivateIpAddress, VpcIdFull, SubnetIdFull, InstanceType |   
    ConvertTo-Csv -NoTypeInformation -Encoding UTF8  
  
# ファイルへ出力  
try {  
    $outputCsv | Out-File -FilePath $OutputPath -Encoding UTF8  
    Write-Host "EC2インスタンス一覧をCSVに出力しました: $OutputPath"  
} catch {  
    Write-Error "CSVファイルの書き込み中に例外が発生しました: $_"  
}  