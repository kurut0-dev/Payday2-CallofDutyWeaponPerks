# Builds the perk icon textures (256x128 uncompressed BGRA DDS, same format as the other perk mods).
# For each perk, icons_src\<perk_id>.png is used if it exists, otherwise an original drawn icon is used.
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File make_icons.ps1 [-Preview sheet.png]
#   -Preview  also writes a contact sheet PNG of every icon, to check them without launching the game
param(
	[string]$Preview
)

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "icons_src"
$out = Join-Path $root "assets\guis\dlcs\codperks\textures\pd2\blackmarket\icons\mods"
New-Item -ItemType Directory -Force $out | Out-Null

# id, label, source game ("mw19" = in both games, orange accent; "codm" = CoD: Mobile only, blue accent)
$perks = @(
	@("sleight_of_hand", "SLEIGHT OF HAND", "mw19"),
	@("fmj", "FMJ", "mw19"),
	@("full_ammo", "FULL AMMO", "mw19"),
	@("disable", "DISABLE", "mw19"),
	@("tough", "TOUGH", "codm"),
	@("long_shot", "LONG SHOT", "codm"),
	@("melee_master", "MELEE MASTER", "codm"),
	@("bullet_return", "BULLET RETURN", "codm"),
	@("fast_switch", "FAST SWITCH", "codm"),
	@("empty_reload", "EMPTY RELOAD", "codm"),
	@("wild_hip_fire", "WILD HIP FIRE", "codm"),
	@("double_kill", "DOUBLE KILL", "codm"),
	@("fast_reload_kill", "FAST RELOAD KILL", "codm"),
	@("speed_up_kill", "SPEED UP KILL", "codm"),
	@("slide_flak_jacket", "SLIDE FLAK JACKET", "codm")
)

$width = 256
$height = 128

# 128-byte DDS header: 256x128, 32-bit BGRA, one mip level.
$header = New-Object byte[] 128
[BitConverter]::GetBytes([uint32]0x20534444).CopyTo($header, 0)
[BitConverter]::GetBytes([uint32]124).CopyTo($header, 4)
[BitConverter]::GetBytes([uint32]0x0002100F).CopyTo($header, 8)
[BitConverter]::GetBytes([uint32]$height).CopyTo($header, 12)
[BitConverter]::GetBytes([uint32]$width).CopyTo($header, 16)
[BitConverter]::GetBytes([uint32]($width * 4)).CopyTo($header, 20)
[BitConverter]::GetBytes([uint32]1).CopyTo($header, 24)
[BitConverter]::GetBytes([uint32]1).CopyTo($header, 28)
[BitConverter]::GetBytes([uint32]32).CopyTo($header, 76)
[BitConverter]::GetBytes([uint32]0x41).CopyTo($header, 80)
[BitConverter]::GetBytes([uint32]32).CopyTo($header, 88)
[BitConverter]::GetBytes([uint32]0x00FF0000).CopyTo($header, 92)
[BitConverter]::GetBytes([uint32]0x0000FF00).CopyTo($header, 96)
[BitConverter]::GetBytes([uint32]0x000000FF).CopyTo($header, 100)
$header[107] = 0xFF
[BitConverter]::GetBytes([uint32]0x1000).CopyTo($header, 108)

$white = [System.Drawing.Color]::White
$dark = [System.Drawing.Color]::FromArgb(255, 70, 70, 70)

function New-Pen($color, $w) {
	$p = New-Object System.Drawing.Pen $color, $w
	$p.StartCap = "Round"
	$p.EndCap = "Round"
	$p.LineJoin = "Round"
	return $p
}

function Fill-Poly($g, $color, $pts) {
	$g.FillPolygon((New-Object System.Drawing.SolidBrush $color), [System.Drawing.PointF[]]$pts)
}

function P($x, $y) { return New-Object System.Drawing.PointF ([single]$x), ([single]$y) }

# Arrow head with its tip at (x,y)+(dx,dy)*s, pointing along the unit direction (dx,dy).
function Head($g, $color, [double]$x, [double]$y, [double]$dx, [double]$dy, [double]$s) {
	Fill-Poly $g $color @(
		(P ($x + $dx * $s) ($y + $dy * $s)),
		(P ($x - $dy * $s * 0.8) ($y + $dx * $s * 0.8)),
		(P ($x + $dy * $s * 0.8) ($y - $dx * $s * 0.8))
	)
}

# Upright bullet with its top-left corner at (x,y).
function Bullet($g, $color, [double]$x, [double]$y, [double]$w, [double]$h) {
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$path.AddArc([single]$x, [single]$y, [single]$w, [single]($w * 1.6), 180, 180)
	$path.AddLine([single]($x + $w), [single]($y + $w * 0.8), [single]($x + $w), [single]($y + $h))
	$path.AddLine([single]($x + $w), [single]($y + $h), [single]$x, [single]($y + $h))
	$path.CloseFigure()
	$g.FillPath((New-Object System.Drawing.SolidBrush $color), $path)
	$path.Dispose()

	# Case line separates the casing from the projectile.
	$g.DrawLine((New-Pen $dark 2), [single]$x, [single]($y + $h * 0.62), [single]($x + $w), [single]($y + $h * 0.62))
}

function Cross($g, $color, [double]$x, [double]$y, [double]$r, [double]$w) {
	$pen = New-Pen $color $w
	$g.DrawLine($pen, [single]($x - $r), [single]($y - $r), [single]($x + $r), [single]($y + $r))
	$g.DrawLine($pen, [single]($x + $r), [single]($y - $r), [single]($x - $r), [single]($y + $r))
}

# Original glyph for each perk, drawn around (cx, cy) in roughly a 90x70 box.
function Draw-Glyph($g, $id, $accent, $cx, $cy) {
	$pen = New-Pen $white 7
	$accentPen = New-Pen $accent 7
	$whiteBrush = New-Object System.Drawing.SolidBrush $white
	$accentBrush = New-Object System.Drawing.SolidBrush $accent

	switch ($id) {
		"sleight_of_hand" {
			# Reload arrow around a magazine.
			$g.DrawArc($pen, [single]($cx - 28), [single]($cy - 28), 56, 56, -60, 280)
			$a = 220 * [Math]::PI / 180
			Head $g $white ($cx + 28 * [Math]::Cos($a)) ($cy + 28 * [Math]::Sin($a)) (-[Math]::Sin($a)) ([Math]::Cos($a)) 13
			$g.FillRectangle($accentBrush, $cx - 8, $cy - 14, 16, 28)
		}
		"fmj" {
			# Bullet punching through a wall.
			$g.FillRectangle($whiteBrush, $cx + 2, $cy - 32, 14, 64)
			$g.TranslateTransform($cx, $cy)
			$g.RotateTransform(90)
			Bullet $g $accent -9 -34 18 56
			$g.ResetTransform()
		}
		"full_ammo" {
			foreach ($dx in -28, 0, 28) {
				Bullet $g $white ($cx + $dx - 10) ($cy - 32) 20 64
			}
		}
		"disable" {
			# Leg and boot with a target ring on the lower leg.
			Fill-Poly $g $white @((P ($cx - 16) ($cy - 34)), (P ($cx + 2) ($cy - 34)), (P ($cx + 2) ($cy + 10)), (P ($cx + 26) ($cy + 18)), (P ($cx + 26) ($cy + 32)), (P ($cx - 16) ($cy + 32)))
			$thin = New-Pen $accent 5
			$g.DrawEllipse($thin, [single]($cx - 27), [single]($cy - 8), 40, 40)
			$g.DrawLine($thin, [single]($cx - 38), [single]($cy + 12), [single]($cx - 20), [single]($cy + 12))
			$g.DrawLine($thin, [single]($cx + 6), [single]($cy + 12), [single]($cx + 24), [single]($cy + 12))
			$g.DrawLine($thin, [single]($cx - 7), [single]($cy - 18), [single]($cx - 7), [single]($cy))
		}
		"tough" {
			# Shield with a lightning bolt.
			Fill-Poly $g $white @((P ($cx - 28) ($cy - 32)), (P ($cx + 28) ($cy - 32)), (P ($cx + 28) ($cy + 2)), (P $cx ($cy + 34)), (P ($cx - 28) ($cy + 2)))
			Fill-Poly $g $accent @((P ($cx + 5) ($cy - 24)), (P ($cx - 12) ($cy + 3)), (P ($cx - 1) ($cy + 3)), (P ($cx - 6) ($cy + 24)), (P ($cx + 13) ($cy - 6)), (P ($cx + 2) ($cy - 6)))
		}
		"long_shot" {
			# Bullet flying along a dashed path to a distant target.
			$g.TranslateTransform($cx - 36, $cy)
			$g.RotateTransform(90)
			Bullet $g $white -6 -14 12 34
			$g.ResetTransform()
			$dash = New-Pen $accent 5
			$dash.DashPattern = [single[]](2, 2)
			$g.DrawLine($dash, [single]($cx - 14), [single]$cy, [single]($cx + 12), [single]$cy)
			$g.DrawEllipse($pen, [single]($cx + 14), [single]($cy - 22), 44, 44)
			$g.FillEllipse($accentBrush, $cx + 29, $cy - 7, 14, 14)
		}
		"melee_master" {
			# Combat knife.
			$g.TranslateTransform($cx, $cy)
			$g.RotateTransform(40)
			Fill-Poly $g $white @((P 0 -40), (P 10 -26), (P 10 6), (P -9 6), (P -9 -24))
			$g.FillRectangle($accentBrush, -17, 6, 34, 7)
			$g.FillRectangle($whiteBrush, -6, 13, 12, 26)
			$g.ResetTransform()
		}
		"bullet_return" {
			# Bullet with a return arrow looping back to it.
			Bullet $g $white ($cx - 8) ($cy - 20) 16 40
			$g.DrawArc($accentPen, [single]($cx - 30), [single]($cy - 30), 60, 60, 120, 270)
			$a = 30 * [Math]::PI / 180
			Head $g $accent ($cx + 30 * [Math]::Cos($a)) ($cy + 30 * [Math]::Sin($a)) (-[Math]::Sin($a)) ([Math]::Cos($a)) 13
		}
		"fast_switch" {
			# Two weapons swapping places.
			$g.DrawLine($pen, [single]($cx - 30), [single]($cy - 16), [single]($cx + 16), [single]($cy - 16))
			Head $g $white ($cx + 16) ($cy - 16) 1 0 14
			$g.DrawLine($accentPen, [single]($cx + 30), [single]($cy + 16), [single]($cx - 16), [single]($cy + 16))
			Head $g $accent ($cx - 16) ($cy + 16) -1 0 14
		}
		"empty_reload" {
			# Empty magazine outline with an arrow feeding it.
			$g.DrawRectangle($pen, [single]($cx - 15), [single]($cy - 30), 30, 60)
			$g.DrawLine($accentPen, [single]$cx, [single]($cy + 16), [single]$cx, [single]($cy - 8))
			Head $g $accent $cx ($cy - 8) 0 -1 14
		}
		"wild_hip_fire" {
			# Wide, loose crosshair.
			$g.DrawEllipse($pen, [single]($cx - 26), [single]($cy - 26), 52, 52)
			$g.FillEllipse($accentBrush, $cx - 6, $cy - 6, 12, 12)
			foreach ($d in @(@(0, -1), @(0, 1), @(-1, 0), @(1, 0))) {
				$g.DrawLine($accentPen, [single]($cx + $d[0] * 20), [single]($cy + $d[1] * 20), [single]($cx + $d[0] * 38), [single]($cy + $d[1] * 38))
			}
		}
		"double_kill" {
			Cross $g $white ($cx - 24) $cy 17 10
			Cross $g $accent ($cx + 24) $cy 17 10
		}
		"fast_reload_kill" {
			# Stopwatch with a kill mark.
			$g.DrawEllipse($pen, [single]($cx - 24), [single]($cy - 20), 48, 48)
			$g.FillRectangle($whiteBrush, $cx - 7, $cy - 32, 14, 8)
			$g.DrawLine($pen, [single]$cx, [single]($cy + 4), [single]$cx, [single]($cy - 10))
			$g.DrawLine($pen, [single]$cx, [single]($cy + 4), [single]($cx + 10), [single]($cy + 10))
			Cross $g $accent ($cx + 36) ($cy - 24) 9 6
		}
		"speed_up_kill" {
			# Speed chevrons with a kill mark.
			foreach ($i in 0..2) {
				$x = $cx - 36 + $i * 24
				$p = if ($i -eq 2) { $accentPen } else { $pen }
				$g.DrawLines($p, [System.Drawing.PointF[]]@((P $x ($cy - 20)), (P ($x + 16) $cy), (P $x ($cy + 20))))
			}
			Cross $g $accent ($cx + 40) ($cy - 26) 8 5
		}
		"slide_flak_jacket" {
			# Armoured vest.
			Fill-Poly $g $white @((P ($cx - 28) ($cy - 32)), (P ($cx - 12) ($cy - 32)), (P $cx ($cy - 16)), (P ($cx + 12) ($cy - 32)), (P ($cx + 28) ($cy - 32)), (P ($cx + 28) ($cy + 32)), (P ($cx - 28) ($cy + 32)))
			$g.DrawLine((New-Pen $dark 4), [single]$cx, [single]($cy - 16), [single]$cx, [single]($cy + 32))
			$g.FillRectangle($accentBrush, $cx - 22, $cy + 8, 14, 14)
			$g.FillRectangle($accentBrush, $cx + 8, $cy + 8, 14, 14)
		}
	}
}

function New-Placeholder($id, $label, $game) {
	$bmp = New-Object System.Drawing.Bitmap $width, $height
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.SmoothingMode = "AntiAlias"
	$g.TextRenderingHint = "AntiAliasGridFit"
	$g.Clear([System.Drawing.Color]::Transparent)

	# Plain white glyph with light grey details on a transparent background, like the stock PAYDAY 2 mod icons.
	$accent = [System.Drawing.Color]::FromArgb(255, 150, 150, 150)
	Draw-Glyph $g $id $accent ($width / 2) ($height / 2)
	$g.Dispose()

	# The glyphs are drawn small, so scale them up to fill the icon.
	$scale = 1.4
	$scaled = New-Object System.Drawing.Bitmap $width, $height
	$sg = [System.Drawing.Graphics]::FromImage($scaled)
	$sg.InterpolationMode = "HighQualityBicubic"
	$sg.SmoothingMode = "AntiAlias"
	$sg.Clear([System.Drawing.Color]::Transparent)
	$w = $width * $scale
	$h = $height * $scale
	$sg.DrawImage($bmp, ($width - $w) / 2, ($height - $h) / 2, $w, $h)
	$sg.Dispose()
	$bmp.Dispose()
	return $scaled
}

function New-FromImage($path) {
	$img = [System.Drawing.Image]::FromFile($path)
	$bmp = New-Object System.Drawing.Bitmap $width, $height
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.InterpolationMode = "HighQualityBicubic"
	$g.Clear([System.Drawing.Color]::Transparent)

	# Keep the aspect ratio and centre the icon.
	$scale = [Math]::Min($width / $img.Width, $height / $img.Height)
	$w = [int]($img.Width * $scale)
	$h = [int]($img.Height * $scale)
	$g.DrawImage($img, [int](($width - $w) / 2), [int](($height - $h) / 2), $w, $h)

	$g.Dispose()
	$img.Dispose()
	return $bmp
}

$sheet = $null
if ($Preview) {
	$cols = 4
	$rows = [Math]::Ceiling($perks.Count / $cols)
	$sheet = New-Object System.Drawing.Bitmap ($cols * $width), ($rows * $height)
	$sg = [System.Drawing.Graphics]::FromImage($sheet)
	$sg.Clear([System.Drawing.Color]::FromArgb(255, 40, 40, 40))
}

$index = 0
foreach ($perk in $perks) {
	$id, $label, $game = $perk
	$png = Join-Path $src "$id.png"

	if (Test-Path $png) {
		$bmp = New-FromImage $png
		$mode = "icon"
	} else {
		$bmp = New-Placeholder $id $label $game
		$mode = "drawn"
	}

	if ($sheet) {
		$sg.DrawImage($bmp, ($index % $cols) * $width, [Math]::Floor($index / $cols) * $height)
	}
	$index++

	$pixels = New-Object byte[] ($width * $height * 4)
	for ($y = 0; $y -lt $height; $y++) {
		for ($x = 0; $x -lt $width; $x++) {
			$c = $bmp.GetPixel($x, $y)
			$i = ($y * $width + $x) * 4
			$pixels[$i] = $c.B
			$pixels[$i + 1] = $c.G
			$pixels[$i + 2] = $c.R
			$pixels[$i + 3] = $c.A
		}
	}
	$bmp.Dispose()

	$file = Join-Path $out "wpn_fps_upg_perk_cod_$id.texture"
	[System.IO.File]::WriteAllBytes($file, $header + $pixels)
	Write-Host ("{0,-20} {1,-12} {2}" -f $id, $game, $mode)
}

if ($sheet) {
	$sg.Dispose()
	$sheet.Save($Preview, [System.Drawing.Imaging.ImageFormat]::Png)
	$sheet.Dispose()
	Write-Host "Preview written to $Preview"
}
