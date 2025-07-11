param (
    [string]$RepoUrl = "https://github.com/uchican10/awsResourceReportCmdlet.git",
    [string]$LocalFolderPath = "C:\src\ps\ozAWStool",
    [string]$TargetDir = "$env:TEMP\awsResourceReportCmdlet",
    [string]$CommitMessage = "Add ozAWStool folder"
)

# GitHubリポジトリをクローン
Write-Host "Cloning repository from $RepoUrl"
git clone $RepoUrl $TargetDir

# フォルダコピー
Write-Host "Copying ozAWSCmdlet folder to cloned repo..."
Copy-Item -Path $LocalFolderPath -Destination "$TargetDir\ozAWSCmdlet" -Recurse -Force

# Git作業ディレクトリに移動
Set-Location -Path $TargetDir

# Gitステージング & コミット
git add ozAWSCmdlet
git commit -m $CommitMessage

# プッシュ
git push origin main

Write-Host "✅ Push completed. Check the GitHub repo for confirmation."