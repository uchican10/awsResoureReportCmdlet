# PowerShell から jq を起動する際のダブルクォート（"）やドル記号（$）のエスケープは特に注意が必要です。以下にポイントとサンプルをまとめます。
 

PowerShell でのエスケープの主なポイント
 

PowerShell のダブルクォート内で $ は変数展開される
例："$var" は $var の値に置換される。
これを防ぐには、$ を `$ にエスケープするか、シングルクォートで囲むか、二重にする。
PowerShell のシングルクォート内は文字列リテラルとして扱われ $ の展開がない
そのため、jqのフィルター文字列をシングルクォート囲みで書くと楽な場合が多い。
jq のフィルター内で文字列を比較するときは " が必要
例：.CreateDate >= "2024-06-15T00:00:00Z"
PowerShell の文字列として渡す場合、"はエスケープが必要だが、外側をシングルクォートで囲めば良い。
PowerShell の パイプ | と jq の パイプ | を混同しない
PowerShell のパイプはコマンド間のパイプで、`| （バッククォート付き）で文字列に含む必要がある。または適切にクォートする。
 

サンプル
 
例えば、bashでよくあるように jq フィルター文字列を直接PowerShellダブルクォートで書くと問題が起きます。


# NG例（$CreateDate がPowerShell変数として展開されてしまう）  
$filter = ".Roles[] | select(.CreateDate >= \"$sinceDateIso\") | {RoleName: .RoleName, CreateDate: .CreateDate}"  
  
# PowerShell で実行時に予期しない動作やエラーが出ることがあります  
 

対策1：jqフィルターを PowerShell のシングルクォートで囲う
 


$sinceDateIso = "2024-06-15T00:00:00Z"  
$jqFilter = ".Roles[] | select(.CreateDate >= `"$sinceDateIso`") | {RoleName: .RoleName, CreateDate: .CreateDate}"  
  
# ↑ PowerShell の文字列はシングルクォートで囲みたいが  
# ここでは文字列内にダブルクォートが必要な構造なので、バッククォートでエスケープ  
$jqFilter = ".Roles[] | select(.CreateDate >= `"$sinceDateIso`") | {RoleName: .RoleName, CreateDate: .CreateDate}"  
 

ただし自動展開をさせるためにダブルクォート文字列を使うなら上記バッククォートで " をエスケープ。


対策2：PowerShellのヒアストリングを使う方法（推奨）
 
ヒアストリングは複数行の文字列を扱いやすく、クォートまわりのエスケープが楽になります。


$sinceDateIso = "2024-06-15T00:00:00Z"  
  
$jqFilter = @"  
.Roles[] | select(.CreateDate >= "$sinceDateIso") | {RoleName: .RoleName, CreateDate: .CreateDate}  
"@  
 
このポイントは：

ヒアストリングは @" 文字列 "@ で囲みます。
ただし、ヒアストリング内のダブルクォートは文字列の区切りとしては扱われません。
変数展開も通常のダブルクォート文字列同様にされますので、$sinceDateIso に値が適切に埋め込まれます。
jqのフィルター内で日時はダブルクォートで囲む必要があるためダブルクォートを使いますが、PowerShellの文字列区切りとして問題になりません。
 

実行例
 


$sinceDateIso = "2024-06-15T00:00:00Z"  
  
$jqFilter = @"  
.Roles[] | select(.CreateDate >= "$sinceDateIso") | {RoleName: .RoleName, CreateDate: .CreateDate}  
"@  
  
# AWS CLI の出力を jq にパイプして実行  
$rawJson = aws iam list-roles  
  
$filteredRoles = $rawJson | jq -c $jqFilter  
 
 

補足
 

PowerShellで jq を使う場合、引数の文字列にスペースが含まれると正しく渡せない場合があります。
そうした場合は --arg オプションを使う方法もありますが、今回のような単純比較では上記のヒアストリング方式で十分です。
 
もし具体的な実装でより複雑なjqフィルターを渡す場合やエスケープで詰まった場合は、改めてお伝えください。