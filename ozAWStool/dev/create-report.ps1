function Create-Report {
    [CmdletBinding()]
    param (
        
    )
    
        function invoke{
            param(
                [string]$target,
                [string]$filename
            )
            $title ="$target ${env:AWS_PROFILE_TITLE} "
            $command="get-${target}s `| Export-Excel -WorksheetName `"$target`" -title `"$title`"  -FreezeTopRowFirstColumn -AutoFilter `"$filename`""
            Write-Verbose($command)
            Invoke-Expression "$command" 
        }

    $excelfile = "./${env:AWS_PROFILE_TITLE}.xlsx"
    
    invoke "EC2" $excelfile
    invoke "SecurityGroup" $excelfile
    invoke "VPC" $excelfile
    invoke "Subnet" $excelfile
    invoke "Role" $excelfile
    invoke "RouteTable" $excelfile
    
    
    

}