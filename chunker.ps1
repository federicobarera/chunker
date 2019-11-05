Param (
	[Parameter(Mandatory = $true)] [string] $file,
	[int] $fileSize = 2,
	[ValidateSet('raw', 'line')] [string]$mode
)

function Split-Raw {
	$input = [System.IO.File]::OpenRead($file)
	$rootName = (Get-ChildItem $file).Name 
	$BUFFER_SIZE = 1 * 1024 * 1024;
	$buffer = [System.Byte[]]::CreateInstance([System.Byte], $BUFFER_SIZE)
	$index = 1

	while ($input.Position -lt $input.Length) {
		$fileName = "{0}.{1}" -f ($rootName, $index)
		$output = [System.IO.File]::Create($fileName)
		$remaining = $fileSize * 1024 * 1024;
		$bytesRead = 0

		while (($remaining -gt 0) -and ($bytesRead = $input.Read($buffer, 0, [Math]::Min($remaining, $BUFFER_SIZE))) -gt 0) {
			$output.Write($buffer, 0, $bytesRead);
			$output.Flush();
			$remaining -= $bytesRead;
		}
	
		$output.Close();
		$index++;
	}
	
	$input.Close()
}

function Split-Line {
	$reader = New-Object System.IO.StreamReader($file)
	$rootName = (Get-ChildItem $file).Name 
	$index = 1
	$fileName = "{0}.{1}" -f ($rootName, $index)
	$writer = New-Object System.IO.StreamWriter($fileName)
	
	while($null -ne ($line = $reader.ReadLine())) {
		$writer.WriteLine($line);
		$writer.Flush();

		if ($writer.BaseStream.Length -gt ($fileSize * 1024 * 1024)) {
			$writer.Close();
			$fileName = "{0}.{1}" -f ($rootName, ++$index)
			$writer = New-Object System.IO.StreamWriter($fileName)
		}
	}
	$writer.Close()
	$reader.Close()
}

if (!$(Test-Path $file)) {
	Write-Error "File $file not found"
	exit 1
}

switch ($mode) {
	'line' { Split-Line }
	Default { Split-Raw }
}