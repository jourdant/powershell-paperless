#
# Title:     Initialize-Environment.ps1
# Author:    Jourdan Templeton
# Email:     hello@jourdant.me
# Modified:  04/01/2015 05:44PM NZDT
#

#Environment Properties
#================================================================
$tesseract_url = "https://nuget.org/api/v2/package/Tesseract"
$tessdata_url = "https://nuget.org/api/v2/package/tesseract-ocr"
$tesseract_zip_name = "tesseract.zip"
$tessdata_zip_name = "tessdata.zip"

$input_dir_name = "Input"
$output_dir_name = "Output"
$lib_dir_name = "Lib"
#================================================================

#create dir structure
If ((Test-Path $input_dir_name) -eq $False) { mkdir $input_dir_name | Out-Null }
If ((Test-Path $output_dir_name) -eq $False) { mkdir $output_dir_name | Out-Null }
If ((Test-Path $lib_dir_name) -eq $False) { mkdir $lib_dir_name | Out-Null }

#import assemblies into session
Add-Type -Assembly "System.IO.Compression.FileSystem"

#download and extract tesseract libraries
If ((Test-Path $tesseract_zip_name) -eq $False) { 
	Write-Host "Downloading:" $tesseract_url "  To:" $tesseract_zip_name
	Invoke-WebRequest -Uri $tesseract_url -OutFile  $tesseract_zip_name
}

If ((Test-Path $tesseract_zip_name) -eq $True)
{
	$zip = [IO.Compression.ZipFile]::OpenRead($tesseract_zip_name).Entries
	
	#extract tesseract libraries
	$zip | Where FullName -match "(x86|x64)|net451/tesseract\.(?:dll|xml)" | % {
		$dir = (Get-Item $lib_dir_name).FullName
		If ($_.FullName.Contains("content")) { $dir +=  "\" + $matches[0] }
		If ((Test-Path $dir) -eq $False) { mkdir $dir | Out-Null }

		$file = $dir + "\" + $_.Name
		[IO.Compression.ZipFileExtensions]::ExtractToFile($_, $file, $true) 
	}
}

#download and extract tesseract data files
If ((Test-Path $tessdata_zip_name) -eq $False) { 
	Write-Host "Downloading:" $tessdata_url "  To:" $tessdata_zip_name
	Invoke-WebRequest -Uri $tessdata_url -OutFile  $tessdata_zip_name
}

If ((Test-Path $tessdata_zip_name) -eq $True)
{
	$zip = [IO.Compression.ZipFile]::OpenRead($tessdata_zip_name).Entries
	
	#extract tessdata libraries
	$zip | Where FullName -match "eng" | % {
		$dir = (Get-Item $lib_dir_name).FullName + "\tessdata"
		If ((Test-Path $dir) -eq $False) { mkdir $dir | Out-Null }
		
		$file = $dir + "\" + $_.Name
		[IO.Compression.ZipFileExtensions]::ExtractToFile($_, $file, $true) 
	}
}

#remove temp zip files
Remove-Item tess*.zip -Force