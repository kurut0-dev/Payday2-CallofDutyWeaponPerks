# Converts every .webp in icons_src\ to a .png next to it, so make_icons.ps1 can use them.
# Decoders tried in order:
#   1. Windows Imaging Component (works when the "WebP Image Extensions" Store app is installed)
#   2. dwebp (libwebp) if it is on PATH
#   3. ffmpeg if it is on PATH
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File convert_webp.ps1 [-Overwrite] [-Build]
#   -Overwrite  replace a .png that already exists
#   -Build      run make_icons.ps1 afterwards
param(
	[switch]$Overwrite,
	[switch]$Build
)

Add-Type -AssemblyName PresentationCore

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "icons_src"

function Convert-WithWic($webp, $png) {
	try {
		$stream = [System.IO.File]::OpenRead($webp)
		try {
			$decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
				$stream,
				[System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
				[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
			$encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
			$encoder.Frames.Add($decoder.Frames[0])

			$out = [System.IO.File]::Create($png)
			try { $encoder.Save($out) } finally { $out.Dispose() }
		} finally {
			$stream.Dispose()
		}
		return $true
	} catch {
		if (Test-Path $png) { Remove-Item $png -Force }
		return $false
	}
}

function Convert-WithTool($webp, $png) {
	$dwebp = Get-Command dwebp -ErrorAction SilentlyContinue
	if ($dwebp) {
		& $dwebp.Source $webp -o $png 2>$null | Out-Null
		if (Test-Path $png) { return $true }
	}

	$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
	if ($ffmpeg) {
		& $ffmpeg.Source -v error -y -i $webp $png 2>$null | Out-Null
		if (Test-Path $png) { return $true }
	}

	return $false
}

if (-not (Test-Path $src)) {
	Write-Host "icons_src folder not found: $src"
	exit 1
}

$files = Get-ChildItem $src -Filter *.webp
if (-not $files) {
	Write-Host "No .webp files in $src"
	exit 0
}

$failed = 0
foreach ($file in $files) {
	$png = Join-Path $src ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + ".png")

	if ((Test-Path $png) -and -not $Overwrite) {
		Write-Host ("{0,-32} skipped (png exists, use -Overwrite)" -f $file.Name)
		continue
	}

	if ((Convert-WithWic $file.FullName $png) -or (Convert-WithTool $file.FullName $png)) {
		Write-Host ("{0,-32} ok" -f $file.Name)
	} else {
		Write-Host ("{0,-32} FAILED" -f $file.Name)
		$failed++
	}
}

if ($failed) {
	Write-Host ""
	Write-Host "$failed file(s) could not be decoded. Install 'WebP Image Extensions' from the Microsoft Store,"
	Write-Host "or put dwebp (libwebp) or ffmpeg on your PATH, then run this again."
	exit 1
}

if ($Build) {
	& (Join-Path $PSScriptRoot "make_icons.ps1")
}
