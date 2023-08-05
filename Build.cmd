@echo off
pushd "%~dp0" >nul 2>&1

:: Specify the Windows Build
set "VERSION=10.0.22621.1"

:: Compress .WIM to .ESD to fit on FAT32 drives
set "WimToESD=False"

:: Further Registry Tweaks to disable GameDVR, Recommended Section etc.
set "AdvancedTweaks=False"

if not exist mount mkdir mount >nul 2>&1
if not exist temp mkdir temp >nul 2>&1

:: In case any other Build than 22621.1 is defined, it will rename the file names and the strings inside the files.
echo [+] Preparing sxs files [+]
copy files\sxs\* sxs\ >nul 2>&1
ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~10.0.22621.1.mum" "Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" >nul 2>&1
ren "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~10.0.22621.1.cat" "Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" >nul 2>&1
powershell -Command "(Get-Content 'sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum') -replace '10\.0\.22621\.1','%VERSION%' | Set-Content 'sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum'" >nul 2>&1
powershell -Command "(Get-Content 'sxs\1.xml') -replace '10\.0\.22621\.1','%VERSION%' | Set-Content 'sxs\1.xml'" >nul 2>&1
echo.

:: Mount original install.wim
echo [+] Mounting Image [+]
dism /mount-wim /wimfile:install.wim /index:1 /mountdir:mount || exit /b 1 >nul 2>&1
echo.

:: Remove Professional Packages and add EnterpriseG Packages
echo [+] Converting SKU to EnterpriseG [+] 
dism /scratchdir:"%~dp0temp" /image:mount /apply-unattend:sxs\1.xml || exit /b 1 >nul 2>&1
echo.

:: Add EN-US Language Pack
echo [+] Adding Language Pack [+] 
dism /scratchdir:"%~dp0temp" /image:mount /add-package:lp || exit /b 1 >nul 2>&1
echo.

del mount\Windows\*.xml >nul 2>&1
copy mount\Windows\servicing\Editions\EnterpriseGEdition.xml mount\Windows\EnterpriseG.xml >nul 2>&1
echo.

:: Set Windows Version to EnterpriseG
echo [+] Setting SKU To EnterpriseG [+] 
dism /scratchdir:"%~dp0temp" /image:mount /apply-unattend:mount\Windows\EnterpriseG.xml || exit /b 1 >nul 2>&1
dism /scratchdir:"%~dp0temp" /image:mount /set-productkey:YYVX9-NTFWV-6MDM3-9PT4T-4M68B || exit /b 1 >nul 2>&1
dism /scratchdir:"%~dp0temp" /image:mount /get-currentedition || exit /b 1 >nul 2>&1 
echo.

:: Load Registry Hive
echo [+] Loading Registry Hive [+] 
reg load HKLM\zNTUSER mount\Users\Default\ntuser.dat >nul 2>&1
reg load HKLM\zSOFTWARE mount\Windows\System32\config\SOFTWARE >nul 2>&1
reg load HKLM\zSYSTEM mount\Windows\System32\config\SYSTEM >nul 2>&1
echo.

:: Apply Registry Keys to Registry Hive
echo [+] Applying Registry Keys [+] 

:: Don't touch these!
reg Add "HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Accounts" /v "AllowMicrosoftAccountSignInAssistant" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\zSYSTEM\ControlSet001\Control\CI\Policy" /v "VerifiedAndReputablePolicyState" /t REG_DWORD /d 0 /f >nul 2>&1

if "%AdvancedTweaks%"=="True" (
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d "2" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\policies\microsoft\windows\windowsupdate\au" /v "NoAutoUpdate" /t REG_DWORD /d "1" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d "1" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "AllowBuildPreview" /t REG_DWORD /d "0" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Maps" /v "AllowUntriggeredNetworkTrafficOnSettingsPage" /t REG_DWORD /d "0" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Microsoft\OneDrive" /v "PreventNetworkTrafficPreUserSignIn" /t REG_DWORD /d "1" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f >nul 2>&1
    reg add "HKLM\zNTUSER\Software\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "1" /f >nul 2>&1
    reg add "HKLM\zSOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f >nul 2>&1
)
echo.

:: Unload Registry Hive
echo [+] Unloading Registry Hive [+] 
reg unload HKLM\zNTUSER >nul 2>&1
reg unload HKLM\zSOFTWARE >nul 2>&1
reg unload HKLM\zSYSTEM >nul 2>&1
echo.

:: Copy License and Activation Scripts to Image
echo [+] Copying files [+] 
mkdir mount\Windows\Setup\Scripts >nul 2>&1
copy files\License\license.rtf mount\Windows\System32\Licenses\neutral\_Default\EnterpriseG\license.rtf >nul 2>&1
copy files\Scripts\MAS_AIO.cmd mount\Windows\Setup\Scripts\MAS_AIO.cmd >nul 2>&1
copy files\Scripts\SetupComplete.cmd mount\Windows\Setup\Scripts\SetupComplete.cmd >nul 2>&1
echo.

:: Save all Changes and unmount Image
echo [+] Saving and unmounting EnterpriseG Image [+] 
dism /unmount-wim /mountdir:mount /commit || exit /b 1 >nul 2>&1
echo.

:: Optimize new Install.wim Image containing EnterpriseG
echo [+] Optimizing EnterpriseG Image [+] 
files\wimlib-imagex optimize install.wim >nul 2>&1
echo.

:: Set WIM infos
echo [+] Setting appropriate WIM Infos [+] 
files\wimlib-imagex info install.wim 1 --image-property NAME="Windows 11 EnterpriseG" --image-property DESCRIPTION="Windows 11 EnterpriseG" --image-property FLAGS="EnterpriseG" --image-property DISPLAYNAME="Windows 11 Enterprise G" --image-property DISPLAYDESCRIPTION="Windows 11 Enterprise G" >nul 2>&1
echo.

:: If set to true, WIM will be compressed to ESD to save storage
if "%WimToESD%"=="True" (
    echo [+] Converting WIM to ESD [+]
    dism /Export-Image /SourceImageFile:install.wim /SourceIndex:1 /DestinationImageFile:install.esd /Compress:Recovery >nul 2>&1
    if exist install.wim del install.wim >nul 2>&1
)

:: Clean-Up - last touches
if exist mount rmdir /s /q mount >nul 2>&1
if exist temp rmdir /s /q temp >nul 2>&1
if exist "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" del "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.mum" >nul 2>&1
if exist "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" del "sxs\Microsoft-Windows-EnterpriseGEdition~31bf3856ad364e35~amd64~~%VERSION%.cat" >nul 2>&1
if exist "sxs\1.xml" del "sxs\1.xml" >nul 2>&1
echo.

:: Script end
echo [+] EnterpriseG is ready [+] 
pause
exit
