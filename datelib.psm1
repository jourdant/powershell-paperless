#
# Title:     itextsharplib.psm1
# Author:    Jourdan Templeton
# Email:     hello@jourdant.me
# Modified:  10/01/2015 21:49PM NZDT
#

###regex breakdown
$r_day	=				'(?<!\d)(3[0-1]|[1-2]\d|0?\d)(?:\s?[SsTt][TtHh])?'	
$r_month_0 =			'(1[0-2]|0?[1-9]|'																														#Captures 01-31 and matches with the optional st or th
$r_month_1 =			'A[UP][RG][A-z]{0,3}|[J][AU][NL][A-z]{0,4}|FEB[A-z]{0,5}|MA[RY][A-z]{0,2}|SEP[A-z]{0,6}|OCT[A-z]{0,4}|NOV[A-z]{0,5}|DEC[A-z]{0,5})'		#Captures Jan-Dec
$r_month =				$r_month_0 + $r_month_1																													#Captures 01-12 or Jan-Dec
$r_month_name =			'(' + $r_month_1																														#Captures 
$r_year =				'((?:19)?9\d|(?:20)?[01]\d)'																											#Captures 1991-1999 2000-2016 (91-99 00-16)
$r_seperator =			'(?:(?<!\n|\r)[\W-_]{0,2})?'																											#Captures ' ' \ / - , .

$patterns =				@(($r_day + $r_seperator + $r_month + $r_seperator + $r_year),				# 20/10/1999
						  ('(?<!\d)' + $r_month + $r_seperator + $r_day + $r_seperator + $r_year),	# September 20th 2013
						  ($r_year + $r_seperator + $r_month + $r_seperator + $r_day),				# 2014-2-31
						  ($r_year + $r_seperator + $r_day + $r_seperator + $r_month),				# 2014/31/may
						  ($r_year + $r_seperator + $r_month_name),									# 2014-May
						  ($r_month_name + $r_seperator + $r_year))									# Oct 2013

$patterns | % { Write-Host ($_ + " `r`n") }
###/regex breakdown

$min_year = 1991
$max_year = 2020

<#
.SYNOPSIS

Returns a date from the given text.
.DESCRIPTION

This cmdlet agressively parses the text to find a date matching multiple formats. These formats can be adjusted in the module code.
.PARAMETER InputText

The text to be parsed.

.EXAMPLE

$text = Get-TessTextFromImage -Path C:\Temp\temp.jpg
$date = Find-Date -InputText $text
#>
Function Find-Date([Parameter(Mandatory=$true)][string]$InputText) 
{
	If ($InputText -eq $null) { throw "$InputText cannot be null" }

	$text = $InputText.ToUpper()
	Write-Verbose $text

	#capture all dates within the image
	$dates = @()
	ForEach ($regex in $script:patterns) 
	{
		write-verbose $regex
		#regex
		$matches = ([regex]$regex).Matches($text)
		If ($matches.Count -gt 0) 
		{
			write-verbose $matches
			#select all parsable dates between set range (clean out as many false positives and mistakes as possible)
			$matches = $matches | Where-Object { $_.Value.Length -gt 5 } | % { Try { [DateTime]::Parse($_) } Catch {} } | Where-Object { $_.Year -ge $script:min_year -and $_.Year -le $script:max_year }
			Write-Verbose ("Matches==Null: " + ($matches -eq $null) + ", Total Matches: " + $matches.Count)
			If ($matches.Count -gt 0) { $dates += $matches[0] }
		}

		#clear matches collection for next iteration
		$matches = $null
	}

	#final logic
	If ($dates -ne $null -and $dates.Count -gt 0) 
	{
		#optional: custom date selection logic eg:
		#If ($InputText -match "statement|bank|account") { $dates = $dates | Sort -Descending }
		
		return $dates[0]
	} 
	Else 
	{ 
		If ($InputText.Contains(' ') -eq $false)  { throw "No date could be found." } 
		Else 
		{
			#recurse with text minus spaces
			return Find-Date -InputText $InputText.Replace(' ', '') 
		}
	}
}