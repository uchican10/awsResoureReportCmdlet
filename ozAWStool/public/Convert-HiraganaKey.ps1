function Convert-HiraganaKey {  
    param(  
        [Parameter(Mandatory = $true)]  
        [ValidateSet("ToKey", "ToHiragana")]  
        [string]$Direction,  
  
        [Parameter(Mandatory = $true)]  
        [string]$InputString  
    )  
  
    $hiraganaToKey = @{  
        'あ' = '3'; 'い' = 'E'; 'う' = '4'; 'え' = '5'; 'お' = '6'  
        'か' = 'T'; 'き' = 'G'; 'く' = 'H'; 'け' = ':'; 'こ' = 'B'  
        'さ' = 'X'; 'し' = 'D'; 'す' = 'R'; 'せ' = 'P'; 'そ' = 'C'  
        'た' = 'Q'; 'ち' = 'A'; 'つ' = 'Z'; 'て' = 'W'; 'と' = 'S'  
        'な' = 'U'; 'に' = 'I'; 'ぬ' = '1'; 'ね' = ','; 'の' = 'K'  
        'は' = 'F'; 'ひ' = 'V'; 'ふ' = '2'; 'へ' = '^'; 'ほ' = '-'  
        'ま' = 'J'; 'み' = 'N'; 'む' = ']'; 'め' = '/'; 'も' = 'M'; 
        'や' = '7'; 'ゆ' = '8'; 'よ' = '9'  
        'ら' = 'O'; 'り' = 'L'; 'る' = '.'; 'れ' = ';'; 'ろ' = '\'  
        'わ' = '0'; 'を' = '0'; 'ん' = 'Y'  
        '゛' = '`'; '゜' = '@'; '「' = '['; '」' = ']'  
    }  
    $dakuon=@{
        'が' = 'T@'; 'ぎ' = 'G@'; 'ぐ' = 'H@'; 'げ' = ':@'; 'ご' = 'B@'; 
        'ざ' = 'X@'; 'じ' = 'D@'; 'ず' = 'R@'; 'ぜ' = 'P@'; 'ぞ' = 'C@'; 
        'だ' = 'Q@'; 'ぢ' = 'A@'; 'づ' = 'Z@'; 'で' = 'W@'; 'ど' = 'S@'; 
        'ば' = 'F@'; 'び' = 'V@'; 'ぶ' = '2@'; 'べ' = '^@'; 'ぼ' = '-@'; 
        'ぱ' = 'F['; 'ぴ' = 'V['; 'ぷ' = '2['; 'ぺ' = '^['; 'ぽ' = '-['; 
        'ぁ' = '3'; 'ぃ' = 'E'; 'ぅ' = '4'; 'ぇ' = '5'; 'ぉ' = '6'; 
        'ゃ' = '7'; 'ゅ' = '8'; 'ょ' = '9'; 'っ' = 'Z';
    }


  
    $keyToHiragana = @{}  
    foreach ($kvp in $hiraganaToKey.GetEnumerator()) {  
        if (-not [string]::IsNullOrEmpty($kvp.Value)) {  
            $keyToHiragana[$kvp.Value.ToUpper()] = $kvp.Key  
        }  
    }  
  
    $result = ""  
  
    switch ($Direction) {  
        "ToKey" {  
            foreach ($char in $InputString.ToCharArray()) {  
                #$schar = $char.ToString()
                if ($hiraganaToKey.ContainsKey("$char")) {  
                    $mapped = $hiraganaToKey["$char"]  
                    if ($mapped -ne "") {  
                        $result += $mapped  
                    }  
                    # 空文字の場合はスキップ（対応なし）  
                } elseif ($dakuon.ContainsKey("$char")) {  
                    $mapped = $dakuon["$char"]  
                    if ($mapped -ne "") {  
                        $result += $mapped  
                    }  
                } else {  
                    # 対応なし文字はそのまま追加、または空白にしてもよい  
                    $result += "*$char"  
                }  
            }  
        }  
        "ToHiragana" {  
            foreach ($char in $InputString.ToCharArray()) {  
                $upperChar = $char.ToString().ToUpper()  
                if ($keyToHiragana.ContainsKey($upperChar)) {  
                    $result += $keyToHiragana[$upperChar]  
                } else {  
                    $result += $char  
                }  
            }  
        }  
    }  
  
    return $result  
}  
<#  
# 使用例  
Write-Output "--- ひらがな文字列→キー列 ---"  
$hiraganaStr = "こんにちは、せかい！"  
$keyStr = Convert-HiraganaKey -Direction ToKey -InputString $hiraganaStr  
Write-Output $keyStr  
  
Write-Output "--- キー列→ひらがな文字列 ---"  
$keyInputStr = "39DA,BPQ!"  
$hiraganaOutputStr = Convert-HiraganaKey -Direction ToHiragana -InputString $keyInputStr  
Write-Output $hiraganaOutputStr  
#>