#
# Title:     itextsharplib.psm1
# Author:    Jourdan Templeton
# Email:     hello@jourdant.me
# Modified:  10/01/2015 21:49PM NZDT
#

Add-Type -Path "$PSScriptRoot\Lib\itextsharp.dll"

<#
.SYNOPSIS

This cmdlet loads a PDF file and returns the text content.
.DESCRIPTION

This cmdlet loads a PDF file and returns the text content. NOTE: this only applies to documents that have text fields embedded. This does not apply to text contained in images of the PDF.
.PARAMETER Path

The path to the image to be processed.
.EXAMPLE

Get-ItsTextFromImage -Path "C:\temp\test.pdf"
.EXAMPLE

$text = Get-ChildItem "C:\Temp" -Filter *.pdf | Get-ItsTextFromImage
#>
Function Get-ItsTextFromPdf()
{
	Param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)][Alias("FullName")][String]$Path
	)
	Process {
		#construct reader object and prepare for reading
		$reader = New-Object iTextSharp.text.pdf.PdfReader($Path)
		
		#read pdf
		$ret = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($reader, 1)
		
		#clean up references
		$reader.Dispose()
		return $ret
	}
}