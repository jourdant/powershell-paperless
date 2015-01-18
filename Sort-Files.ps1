#
# Title:     Sort-Files.ps1
# Author:    Jourdan Templeton
# Email:     hello@jourdant.me
# Modified:  10/01/2015 21:52PM NZDT
#

[CmdletBinding(SupportsShouldProcess=$true)]Param(
	[Parameter(Mandatory=$true)][string]$InputDirectory,
	[Parameter(Mandatory=$true)][string]$OutputDirectory
)

#check paths
If ((Test-Path $InputDirectory) -eq $False) { Throw "Input directory does not exist." } Else { $InputDirectory = (Get-Item $InputDirectory).FullName }
"Input Directory:" + $InputDirectory
If ((Test-Path $OutputDirectory) -eq $False) { Throw "Output directory does not exist." } Else { $OutputDirectory = (Get-Item $OutputDirectory).FullName }
"Output Directory: " + $OutputDirectory + " `r`n"

#import libraries
Remove-Module *lib
Get-ChildItem -Filter "*lib.psm1" | % { Import-Module $_.FullName }

#get files
$files = Get-ChildItem -Path $InputDirectory  -Recurse -Filter *.pdf | Where-Object { !$_.PSIsContainer }
"Total files to process: " + $files.count

#process files
If ($files.count -lt 1) { "No files to process. Closing..."; return }
ForEach ($file in $files)
{	
	"Processing: " + $file.FullName
	#ocr image with tesseract
	If ($file.Name.Split('.')[-1] -notmatch "pdf")
	{
		$image = New-Object System.Drawing.Bitmap($file.FullName)
		$ocr = Get-TessTextFromImage -Image $image
		"Confidence: " + ($ocr.Confidence * 100).ToString("##") + "%"
		
		$text = $ocr.Text
		$ocr = $null

	#process with itextsharp
	} Else {
		$text = Get-ItsTextFromPdf -Path $file.FullName
	}

	#get date
	$path = $OutputDirectory
	$date = ''
	$output = ''

	Try 
	{
		#parse date and sort
		$date = Find-Date -InputText $text
		$path += "/" + $date.ToString("yyyy/MM-MMM")
		$output = $path + "/" + $date.ToString("yyyy-MM-dd_") + $file.Name.Replace(" ", "")
	}
	Catch 
	{
		$path += "/Unknown"
		$output = $path + "/" + $file.Name
	}
	Finally 
	{
		#create output dir
		If ((Test-Path $path) -eq $false) { mkdir $path | Out-Null }
		"Copying to: '" + $output + "'"
		Copy-Item -Path $file.FullName -Destination $output -Force
		
		$text = $null
	}

	"`r`n"
}
