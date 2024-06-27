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

# Enable BitLocker with specified configuration and backup key to a text file
function Enable-BitLocker {
    $Volume = Get-BitLockerVolume -MountPoint "C:"

    if ($Volume.ProtectionStatus -eq "Off") {
        $KeyProtector = Add-BitLockerKeyProtector -MountPoint "C:" -TpmProtector -EncryptionMethod Aes256 -UsedSpaceOnly
        Enable-BitLocker -MountPoint "C:"

        $RecoveryPassword = (Get-BitLockerVolume -MountPoint "C:").KeyProtector |
                            Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } |
                            Select-Object -ExpandProperty RecoveryPassword

        $RecoveryKeyFilePath = "C:\BitLockerRecoveryKey.txt"
        $RecoveryPassword | Out-File -FilePath $RecoveryKeyFilePath

        Write-Host "BitLocker has been enabled on drive C: with AES-256 and used space only encryption."
        Write-Host "Recovery key has been saved to $RecoveryKeyFilePath."
    } else {
        Write-Host "BitLocker is already enabled on drive C:."
    }
}

# Main script
if (Check-BitLockerPrerequisites) {
    Enable-BitLocker
} else {
    Write-Host "BitLocker prerequisites not met. Please check the requirements."
}

