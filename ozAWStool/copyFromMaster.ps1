$src="\\afs03\sh\558\000_自治体情報システム標準化\99_個人\088027_尾崎元春\ozAWStool\"
$dst="c:\src\GC\ps\ozAWStool\"

$option="/SEY" 
Write-Host $src を $dst にコピーします

xcopy "$src" "$dst" "$option"