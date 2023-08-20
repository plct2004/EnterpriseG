@echo off
pushd "%~dp0" >nul 2>&1

:: Set Windows Version
set "Windows=Windows 11"

:: Specify the Windows Build (Insider Previews mostly end with .1000 and Stable always with .1)
set "VERSION=10.0.22621.1"

:: Specify whether you want Enteprise G N instead of Enterprise G. Please note that you will need EnterpriseGN edition files instead of EnterpriseG edition files.
set "EnterpriseGN=False"

:: Specify whether the Image you are using is a Windows vNext Build (Canary Channel Builds)
set "vNext=False"

:: Further Registry Tweaks to disable GameDVR, Recommended Section etc.
set "AdvancedTweaks=False"

:: Disable compatibility checks for TPM, CPU, Disk, RAM and Secure Boot. Please note that you need to copy the boot.wim to the EnterpriseG folder too for this option.
set "DisableCompatibilityCheck"=False"

:: Pre-Active Windows using KMS38 during setup/installation
set "ActivateWindows=False"

:: Compress Image from .WIM to .ESD to reduce size 
set "WimToESD=False"

if not exist mount mkdir mount >nul 2>&1
if not exist temp mkdir temp >nul 2>&1

:: In case any other Build than 22621.1 is defined, it will rename the file names and the strings inside the files.
echo [+] Preparing sxs files [+]

:: Prepare SXS files
if "%vNext%"=="False" (
    copy files\sxs\* sxs\ >nul 2>&1
    ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~10.0.22621.1.mum" "Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" >nul 2>&1
    ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~10.0.22621.1.cat" "Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" >nul 2>&1
    powershell -Command "(Get-Content 'sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum') -replace '10\.0\.22621\.1','%VERSION%' | Set-Content 'sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum'" >nul 2>&1
    powershell -Command "(Get-Content 'sxs\1.xml') -replace '10\.0\.22621\.1','%VERSION%' | Set-Content 'sxs\1.xml'" >nul 2>&1
)

if "%vNext%"=="True" (
    copy files\sxs\vNext\* sxs\ >nul 2>&1
    ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~10.0.22621.1.mum" "Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" >nul 2>&1
    ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~10.0.22621.1.cat" "Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" >nul 2>&1
    powershell -Command "(Get-Content 'sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum') -replace '10\.0\.22621\.1','%VERSION%' | Set-Content 'sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum'" >nul 2>&1
    powershell -Command "(Get-Content 'sxs\1.xml') -replace '10\.0\.22621\.1','%VERSION%' | Set-Content 'sxs\1.xml'" >nul 2>&1
)
echo.

:: Prepare SXS files for EnterpriseGN
if "%EnterpriseGN%"=="True" (
    ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" "Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" >nul 2>&1
    ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" "Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" >nul 2>&1
    powershell -Command "(Get-Content 'sxs\Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.mum') -replace 'EnterpriseG','EnterpriseGN' | Set-Content 'sxs\Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.mum'" >nul 2>&1
    powershell -Command "(Get-Content 'sxs\1.xml') -replace 'EnterpriseG','EnterpriseGN' | Set-Content 'sxs\1.xml'" >nul 2>&1
    echo.
)

:: Mount original install.wim
echo [+] Mounting Image [+]
dism /mount-wim /wimfile:install.wim /index:1 /mountdir:mount || exit /b 1 >nul 2>&1
echo.

:: Remove Professional Packages and add EnterpriseG or EnterpriseGN Packages
echo [+] Converting SKU [+] 
dism /scratchdir:"%~dp0temp" /image:mount /apply-unattend:sxs\1.xml || exit /b 1 >nul 2>&1
echo.

:: Adding Language Pack
echo [+] Adding Language Pack [+] 
dism /scratchdir:"%~dp0temp" /image:mount /add-package:lp || exit /b 1 >nul 2>&1

echo.

del mount\Windows\*.xml >nul 2>&1
if "%EnterpriseGN%"=="False" (
    copy mount\Windows\servicing\Editions\EnterpriseGEdition.xml mount\Windows\EnterpriseG.xml >nul 2>&1
)

if "%EnterpriseGN%"=="True" (
    copy mount\Windows\servicing\Editions\EnterpriseGNEdition.xml mount\Windows\EnterpriseGN.xml >nul 2>&1
)
echo.

:: Set Windows Version to EnterpriseG or EnterpriseGN
if "%EnterpriseGN%"=="False" (
    echo [+] Setting SKU to EnterpriseG [+] 
    dism /scratchdir:"%~dp0temp" /image:mount /apply-unattend:mount\Windows\EnterpriseG.xml || exit /b 1 >nul 2>&1
    dism /scratchdir:"%~dp0temp" /image:mount /set-productkey:YYVX9-NTFWV-6MDM3-9PT4T-4M68B || exit /b 1 >nul 2>&1
    dism /scratchdir:"%~dp0temp" /image:mount /get-currentedition || exit /b 1 >nul 2>&1 
)

if "%EnterpriseGN%"=="True" (
    echo [+] Setting SKU to EnterpriseGN [+] 
    dism /scratchdir:"%~dp0temp" /image:mount /apply-unattend:mount\Windows\EnterpriseGN.xml || exit /b 1 >nul 2>&1
    dism /scratchdir:"%~dp0temp" /image:mount /set-productkey:44RPN-FTY23-9VTTB-MP9BX-T84FV || exit /b 1 >nul 2>&1
    dism /scratchdir:"%~dp0temp" /image:mount /get-currentedition || exit /b 1 >nul 2>&1 
)
echo.

:: Load Registry Hive
echo [+] Loading Registry Hive [+] 
reg load HKLM\zNTUSER mount\Users\Default\ntuser.dat >nul 2>&1
reg load HKLM\zSOFTWARE mount\Windows\System32\config\SOFTWARE >nul 2>&1
reg load HKLM\zSYSTEM mount\Windows\System32\config\SYSTEM >nul 2>&1
reg load HKLM\zDEFAULT mount\Windows\System32\config\default >nul 2>&1
echo.

:: Apply Registry Keys to Registry Hive
echo [+] Applying Registry Keys [+] 

:: Add Microsoft Account support
reg Add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Accounts" /v "AllowMicrosoftAccountSignInAssistant" /t REG_DWORD /d "1" /f >nul 2>&1
:: Fix Windows Security
reg add "HKLM\zSYSTEM\ControlSet001\Control\CI\Policy" /v "VerifiedAndReputablePolicyState" /t REG_DWORD /d 0 /f >nul 2>&1
:: Add Producer branding
reg add "HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionSubManufacturer /t REG_SZ /d "Microsoft Corporation" /f

if "%AdvancedTweaks%"=="True" (
    :: Turn off automatic updates
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d "2" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\policies\microsoft\windows\windowsupdate\au" /v "NoAutoUpdate" /t REG_DWORD /d "1" /f >nul 2>&1
    :: Don't search Windows Update for device drivers
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d "1" /f >nul 2>&1
    :: Turn off Delivery Optimization
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f >nul 2>&1
    :: Don't trigger network traffic for maps
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Maps" /v "AllowUntriggeredNetworkTrafficOnSettingsPage" /t REG_DWORD /d "0" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\OneDrive" /v "PreventNetworkTrafficPreUserSignIn" /t REG_DWORD /d "1" /f >nul 2>&1
    :: Hide Recommended Section in Start Menu
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f >nul 2>&1
    reg add "HKLM\zNTUSER\Software\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f >nul 2>&1
    :: Turn off GameDVR
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f >nul 2>&1
)

if "%DisableCompatibilityCheck%"=="True" (
    Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d "1" /f >nul 2>&1
)
echo.

:: Unload Registry Hive
echo [+] Unloading Registry Hive [+] 
reg unload HKLM\zNTUSER >nul 2>&1
reg unload HKLM\zSOFTWARE >nul 2>&1
reg unload HKLM\zSYSTEM >nul 2>&1
reg unload HKLM\zDEFAULT >nul 2>&1
echo.

:: Add License to Image
echo [+] Adding License/EULA [+] 
if "%EnterpriseGN%"=="False" (
    copy files\License\license.rtf mount\Windows\System32\Licenses\neutral\_Default\EnterpriseG\license.rtf >nul 2>&1
)

if "%EnterpriseGN%"=="True" (
    mkdir mount\Windows\System32\Licenses\neutral\_Default\EnterpriseGN >nul 2>&1
    copy files\License\license.rtf mount\Windows\System32\Licenses\neutral\_Default\EnterpriseGN\license.rtf >nul 2>&1
)
echo.

:: If set to true, WIM will be compressed to ESD to save storage
if "%ActivateWindows%"=="True" (
    echo [+] Adding pre-activation for Windows [+]
    mkdir mount\Windows\Setup\Scripts >nul 2>&1
    copy files\Scripts\MAS_AIO.cmd mount\Windows\Setup\Scripts\MAS_AIO.cmd >nul 2>&1
    copy files\Scripts\SetupComplete.cmd mount\Windows\Setup\Scripts\SetupComplete.cmd >nul 2>&1
    echo.
)

:: Save all Changes and unmount Image
echo [+] Saving and unmounting Install.wim Image [+] 
dism /unmount-wim /mountdir:mount /commit || exit /b 1 >nul 2>&1
echo.

:: Optimize new Install.wim Image
echo [+] Optimizing Install.wim Image [+] 
files\wimlib-imagex optimize install.wim >nul 2>&1
echo.

:: Set WIM infos
echo [+] Setting appropriate WIM Infos [+]
if "%EnterpriseGN%"=="False" (
    files\wimlib-imagex info install.wim 1 --image-property NAME="%Windows% EnterpriseG" --image-property DESCRIPTION="%Windows% EnterpriseG" --image-property FLAGS="EnterpriseG" --image-property DISPLAYNAME="%Windows% Enterprise G" --image-property DISPLAYDESCRIPTION="%Windows% Enterprise G" >nul 2>&1
)

if "%EnterpriseGN%"=="True" (
    files\wimlib-imagex info install.wim 1 --image-property NAME="%Windows% EnterpriseGN" --image-property DESCRIPTION="%Windows% EnterpriseGN" --image-property FLAGS="EnterpriseGN" --image-property DISPLAYNAME="%Windows% Enterprise GN" --image-property DISPLAYDESCRIPTION="%Windows% Enterprise GN" >nul 2>&1
)
echo.

if "%DisableCompatibilityCheck%"=="True" (
    :: Mount boot.wim
    echo [+] Mounting boot.wim Image [+]
    dism /mount-wim /wimfile:boot.wim /index:2 /mountdir:mount || exit /b 1 >nul 2>&1

    :: Load boot.img Registry Hive
    echo [+] Loading Registry Hive [+] 
    reg load HKLM\zNTUSER mount\Users\Default\ntuser.dat >nul 2>&1
    reg load HKLM\zSYSTEM mount\Windows\System32\config\SYSTEM >nul 2>&1
    reg load HKLM\zDEFAULT mount\Windows\System32\config\default >nul 2>&1

    :: Apply registry keys to disable compatibility checks
    echo [+] Applying Registry Keys [+]
    Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV1" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache" /v "SV2" /t REG_DWORD /d "0" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassCPUCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassRAMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassSecureBootCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassStorageCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\LabConfig" /v "BypassTPMCheck" /t REG_DWORD /d "1" /f >nul 2>&1
	Reg add "HKLM\zSYSTEM\Setup\MoSetup" /v "AllowUpgradesWithUnsupportedTPMOrCPU" /t REG_DWORD /d "1" /f >nul 2>&1

    :: Unload boot.wim Registry Hive
    echo [+] Unloading Registry Hive [+] 
    reg unload HKLM\zNTUSER >nul 2>&1
    reg unload HKLM\zSYSTEM >nul 2>&1
    reg unload HKLM\zDEFAULT >nul 2>&1
)

:: If set to true, WIM will be compressed to ESD to save storage
if "%WimToESD%"=="True" (
    echo [+] Converting WIM to ESD [+]
    dism /Export-Image /SourceImageFile:install.wim /SourceIndex:1 /DestinationImageFile:install.esd /Compress:Recovery >nul 2>&1
    if exist install.wim del install.wim >nul 2>&1
)

:: Clean-Up - last final touches
if exist mount rmdir /s /q mount >nul 2>&1
if exist temp rmdir /s /q temp >nul 2>&1
if exist "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" del "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" >nul 2>&1
if exist "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" del "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" >nul 2>&1
if exist "sxs\Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" del "sxs\Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" >nul 2>&1
if exist "sxs\Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" del "sxs\Microsoft-Windows-EnterpriseGNEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" >nul 2>&1
if exist "sxs\1.xml" del "sxs\1.xml" >nul 2>&1
echo.

:: Script end
if "%EnterpriseGN%"=="False" (
    echo [+] EnterpriseG is ready [+] 
)

if "%EnterpriseGN%"=="True" (
    echo [+] EnterpriseGN is ready [+] 
)

pause
exit