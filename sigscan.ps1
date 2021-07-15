param([string]$hex, [string]$filepath)

If([string]::IsNullOrEmpty($filepath)){
	Write-Host "Error: No filepath supplied"
	Exit
}

If(!(Test-Path $filepath)){
	Write-Host "Error: File not found"
	Exit
}

If([string]::IsNullOrEmpty($hex)){
	Write-Host "Error: No hex supplied"
	Exit
}

$fileInfo = New-Object System.IO.FileInfo $filepath
$Stream = New-Object System.IO.FileStream -ArgumentList $filepath, 'Open', 'Read'

$Encoding = [Text.Encoding]::GetEncoding(28591)

$BinaryReader  = New-Object System.IO.BinaryReader -ArgumentList $Stream, $Encoding

# determine the size of the file
$file_size = (Get-Item $filepath).length

$MyRegex = [Regex]::New($hex)

$step = 0

$Matches = foreach($chunk in (0..[math]::Ceiling($file_size/4096))){
            # reset data
            $BinaryText = $null
            # Set offset to read from the file
            $BinaryReader.BaseStream.Position = [UInt64]($step*4096)
            # Initialize the buffer to be save size as the data block
            $buffer = [System.Byte[]]::new(4096)
                        
            # Read each offset to the buffer
            [Void]$BinaryReader.Read($buffer,0,4096)
            # Convert the buffer data to byte
            $BinaryText = [System.Text.Encoding]::GetEncoding(28591).getstring($buffer)
            if($step -gt 0){
            if(!!$MyRegex.Matches($BinaryText).success){foreach($index in $MyRegex.Matches($BinaryText).index){$index + $step*4096}}
            }
            else{if(!!$MyRegex.Matches($BinaryText).success){$MyRegex.Matches($BinaryText).index}}
            $step=$step+1
            }
            

$BinaryReader.Close()
$Stream.Close()


$MatchCount = $Matches.Count

If ($MatchCount -eq 0){
	Write-Host "Error: Nothing to parse."
	Exit
}
$Matches | ForEach-Object {"0x$(([uint64]$_).ToString('X16'))" }
