<#
.SYNOPSIS
Burn a ISO file to a USB drive
.DESCRIPTION
Burn a ISO file to a USB drive
.PARAMETER Disk
The Disk that you want to burn the ISO to
.PARAMETER ISO
Path to the ISO file
.PARAMETER FileSystem
The File System you wish to format the drive as (NTFS or FAT32)
Defaults to FAT32
.PARAMETER VolumeLabel
The label of the Drive after the ISO has been burnt
.PARAMETER Force
Bypasses the user confirmation
.EXAMPLE
.\Burn-ISO2USB.ps1 -Disk E -ISO C:\Win7.iso -VolumeLabel "Windows 7 Setup"

Burns the Win7.iso file to the E drive and labels the drive as Windows 7 Setup
.EXAMPLE
.\Burn-ISO2USB.ps1 -Disk E -ISO C:\Win7.iso -VolumeLabel "Windows 7 Setup" -Force

Burns the Win7.iso file to the E drive and labels the drive as Windows 7 Setup and Bypasses the user confirmation
.NOTES
Copyright (C) MosaicMK Software LLC - All Rights Reserved
Unauthorized copying of this application via any medium is strictly prohibited Proprietary and confidentia
Written by MosaicMK Software LLC (contact@mosaicmk.com)

By using this software you agree to the following:

Agreement Permission is hereby granted, free of charge, to any person or organization obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software and the rights to use and distribute the software so long a no licensing and or documentation files are remove, revised or modified
the Software is furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

Contact: Contact@MosaicMK.com
Version 1.0.0.0
.LINK
https://www.mosaicmk.com
#>

PARAM(
    [Parameter(Mandatory=$true)]
    [string]$Disk,
    [Parameter(Mandatory=$true)]
    [string]$ISO,
    [ValidateSet('NTFS,FAT32')]
    [string]$FileSystem = "FAT32",
    [string]$VolumeLabel = "ISO2USB",
    [switch]$Force
)

If (!($Force)){
    $Proc = Read-Host "All data on drive $Drive will be removed, Are you sure you wish to continue ? (Y,N)"
    IF ($Proc -notlike "Y*"){Exit 0}
}

IF (!(Test-Path $ISO)){Write-Error "Could not find $ISO" ; Exit 1}
IF (!(Get-Volume -DriveLetter $Disk )){Write-Error "Could not find disk $Disk" ; Exit 1}
#Cleans and formats the Drive
try {
    $DiskNum = (Get-Partition -DriveLetter $Disk | Get-Disk).Number
    Clear-Disk -Number $DiskNum -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
    New-Partition -DiskNumber $DiskNum -UseMaximumSize -DriveLetter $Disk -ErrorAction Stop
    Format-Volume -DriveLetter $Disk -FileSystem $FileSystem -NewFileSystemLabel "$VolumeLabel" -Force -InformationAction SilentlyContinue -ErrorAction Stop
} catch {Write-Error "Could not format $Disk : $_" ; Exit}
#Mounts the ISO file so the content can be copied to the Drive
try {
    Mount-DiskImage -ImagePath "$iso" -ErrorAction Stop
    $MountLetter = (Get-DiskImage $iso | Get-Volume).DriveLetter
    $Source = $MountLetter + ":\"
} Catch {Write-Error "Could not mount $ISO" ; Exit 1}
#Makes the Drive Bootable
$bootdir = $Disk + ":"
bootsect.exe /nt60 $bootdir /force /mbr
If ($LASTEXITCODE -ne 0){
    Dismount-DiskImage -ImagePath "$iso"
    Write-Error "Could not update boot code on $Disk"
    Exit 1
}
#Copies the content of the ISO to the Drive
Robocopy.exe $Source $Destination /E /J /R:0 /W:0 /LOG:$Env:TEMP\ISOtoUSB.log
#Dismounts the ISO after the content has been copied
Dismount-DiskImage -ImagePath "$ISO"
