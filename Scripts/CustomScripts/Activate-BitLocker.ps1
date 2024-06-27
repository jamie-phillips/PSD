# Check if the system meets the BitLocker prerequisites
function Check-BitLockerPrerequisites {
    $TPM = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm

    if ($TPM -eq $null) {
        Write-Host "TPM is not present on this system."
        return $false
    }

    if ($TPM.SpecVersion -lt "2.0") {
        Write-Host "TPM version is less than 2.0."
        return $false
    }

    if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -ne "64-bit") {
        Write-Host "Operating system is not 64-bit."
        return $false
    }

    $BitLockerFeature = Get-WindowsOptionalFeature -Online -FeatureName BitLocker
    if ($BitLockerFeature.State -ne "Enabled") {
        Write-Host "BitLocker feature is not enabled."
        return $false
    }

    Write-Host "All prerequisites are met."
    return $true
}

if (Check-BitLockerPrerequisites) {
    $Volume = Get-BitLockerVolume -MountPoint "C:"
    
    if ($Volume.ProtectionStatus -eq "Off") {
        Add-BitLockerKeyProtector -MountPoint "C:" -TpmProtector
        Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly -
    } else {
        Write-Host "BitLocker is already enabled on drive C:."
    }
} else {
    Write-Host "BitLocker prerequisites not met. Please check the requirements."
}

