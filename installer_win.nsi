; pdf2svg for windows install NSIS script
;
; Home page of code is: https://github.com/textext/pdf2svg-windows
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2, or (at your option)
; any later version.
;
; You should have received a copy of the GNU General Public License
; (for example COPYING); If not, see <http://www.gnu.org/licenses/>.
;
; Usage:
; - Installer script assumes that the files to be installed are found
;   in build/dist-32bits or build/dist-64bits directories
; - Use the Python 2 command python create_installer_file_lists.py 
;   to create the file list for the installer
; - Set the architecture flag ARCHITECTURE to 32 or 64, respectively

; Product name and version information
!define PRODUCT_NAME "pdf2svg for windows"
!define PRODUCT_VERSION "0.2.3"
!define PRODUCT_REGKEY "${PRODUCT_NAME} ${PRODUCT_VERSION}"
!define ARCHITECTURE "64"

; Names of the installer executable
!define INSTALLER_NAME "Install-pdf2svg-${PRODUCT_VERSION}-${ARCHITECTURE}bit.exe"
!define UNINSTALLER_NAME "UnInstall-pdf2svg-${PRODUCT_VERSION}-${ARCHITECTURE}bit.exe"

; Basic registry keys (required by uninstall)
!define INSTDIR_REG_ROOT "SHCTX"
!define INSTDIR_REG_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_REGKEY}"

; List of files (autogenerated from Python script "create_installer_file_lists.py")
; calling command: python create_installer_file_lists.py
!define FILES_SOURCE_PATH "build\dist-${ARCHITECTURE}bits"
!define INST_FILE_LIST "inst_file_list_${ARCHITECTURE}bits.txt"
!define UNINST_FILE_LIST "uninst_file_list_${ARCHITECTURE}bits.txt"

; Enable machine or per user installation
; http://nsis.sourceforge.net/Docs/MultiUser/Readme.html
; http://nsis.sourceforge.net/Add_uninstall_information_to_Add/Remove_Programs
!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR "pdf2svg"
!if ${ARCHITECTURE} == "64"
  !define MULTIUSER_USE_PROGRAMFILES64
!endif
!include MultiUser.nsh

; Use modern user interface
!include "MUI2.nsh"

; MUI Settings
!define MUI_ABORTWARNING

; Welcome page (with detailed information what is going to be installed)
!define MUI_WELCOMEPAGE_TITLE "Welcome to the installation of ${PRODUCT_NAME} ${PRODUCT_VERSION}!"
!define MUI_TEXT_WELCOME_INFO_TEXT "You can always uninstall all files of this intallation using the provided uninstaller which can be invoked via the well known Windows control panel.$\n$\n\
Now, Setup will guide you through the installation of ${PRODUCT_NAME}.$\n$\n"
!define MUI_PAGE_CUSTOMFUNCTION_SHOW MyWelcomeShowCallback
!insertmacro MUI_PAGE_WELCOME

; License page
!insertmacro MUI_PAGE_LICENSE "COPYING"

; Machine wide or user installation ?
!insertmacro MULTIUSER_PAGE_INSTALLMODE

; Directory page
!define MUI_DIRECTORYPAGE_TEXT_TOP "Please select the folder you would like to install ${PRODUCT_NAME} into"
!define MUI_DIRECTORYPAGE_TEXT_DESTINATION "pdf2svg installation directory"
!insertmacro MUI_PAGE_DIRECTORY

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
!insertmacro MUI_PAGE_FINISH

; Uninstaller welcome page
!insertmacro MUI_UNPAGE_WELCOME

; Uninstaller confirmation page
!insertmacro MUI_UNPAGE_CONFIRM

; Define what is going to be uninstalled
!insertmacro MUI_UNPAGE_INSTFILES

; Uninstaller finish page
!insertmacro MUI_UNPAGE_FINISH

; Language files
!insertmacro MUI_LANGUAGE "English"
; MUI end ------


; Set some variables

; Since we install into the progam files directory we need administrator privileges
;RequestExecutionLevel admin

; The full name of the product
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"

; Define where the installer is built
OutFile "build\${INSTALLER_NAME}"

; For details
ShowInstDetails show

; Provide if, else, etc
;!include LogicLib.nsh

; Functions
Function .onInit
  !insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

; Fill welcome page
Function MyWelcomeShowCallback
SendMessage $mui.WelcomePage.Text ${WM_SETTEXT} 0 "STR:$(MUI_TEXT_WELCOME_INFO_TEXT)"
FunctionEnd


!include "WinMessages.nsh"
!define Environ 'HKCU "Environment"'
; AddToPath - Appends dir to PATH
;   (does not work on Win9x/ME)
;
; Usage:
;   Push "dir"
;   Call AddToPath
;
; Taken from http://www.smartmontools.org/browser/trunk/smartmontools/os_win32/installer.nsi?rev=4110#L636
Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4

  ; NSIS ReadRegStr returns empty string on string overflow
  ; Native calls are used here to check actual length of PATH

  ; $4 = RegOpenKey(HKEY_CURRENT_USER, "Environment", &$3)
  System::Call "advapi32::RegOpenKey(i 0x80000001, t'Environment', *i.r3) i.r4"
  IntCmp $4 0 0 done done
  ; $4 = RegQueryValueEx($3, "PATH", (DWORD*)0, (DWORD*)0, &$1, ($2=NSIS_MAX_STRLEN, &$2))
  ; RegCloseKey($3)
  System::Call "advapi32::RegQueryValueEx(i $3, t'PATH', i 0, i 0, t.r1, *i ${NSIS_MAX_STRLEN} r2) i.r4"
  System::Call "advapi32::RegCloseKey(i $3)"

  IntCmp $4 234 0 +4 +4 ; $4 == ERROR_MORE_DATA
    DetailPrint "AddToPath: original length $2 > ${NSIS_MAX_STRLEN}"
    MessageBox MB_OK "PATH not updated, original length $2 > ${NSIS_MAX_STRLEN}"
    Goto done

  IntCmp $4 0 +5 ; $4 != NO_ERROR
    IntCmp $4 2 +3 ; $4 != ERROR_FILE_NOT_FOUND
      DetailPrint "AddToPath: unexpected error code $4"
      Goto done
    StrCpy $1 ""

  ; Check if already in PATH
  Push "$1;"
  Push "$0;"
  Call StrStrEx
  Pop $2
  StrCmp $2 "" 0 done
  Push "$1;"
  Push "$0\;"
  Call StrStrEx
  Pop $2
  StrCmp $2 "" 0 done

  ; Prevent NSIS string overflow
  StrLen $2 $0
	  StrLen $3 $1
  IntOp $2 $2 + $3
  IntOp $2 $2 + 2 ; $2 = strlen(dir) + strlen(PATH) + sizeof(";")
  IntCmp $2 ${NSIS_MAX_STRLEN} +4 +4 0
    DetailPrint "AddToPath: new length $2 > ${NSIS_MAX_STRLEN}"
    MessageBox MB_OK "PATH not updated, new length $2 > ${NSIS_MAX_STRLEN}."
    Goto done

  ; Append dir to PATH
  DetailPrint "Add to PATH: $0"
  StrCpy $2 $1 1 -1
  StrCmp $2 ";" 0 +2
    StrCpy $1 $1 -1 ; remove trailing ';'
  StrCmp $1 "" +2   ; no leading ';'
    StrCpy $0 "$1;$0"
  WriteRegExpandStr ${Environ} "PATH" $0
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

done:
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd


; RemoveFromPath - Removes dir from PATH
;
; Usage:
;   Push "dir"
;   Call RemoveFromPath
; Taken from http://www.smartmontools.org/browser/trunk/smartmontools/os_win32/installer.nsi?rev=4110#L713
Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6

  ReadRegStr $1 ${Environ} "PATH"
  StrCpy $5 $1 1 -1
  StrCmp $5 ";" +2
    StrCpy $1 "$1;" ; ensure trailing ';'
  Push $1
  Push "$0;"
  Call un.StrStrEx
  Pop $2 ; pos of our dir
  StrCmp $2 "" done

  DetailPrint "Remove from PATH: $0"
  StrLen $3 "$0;"
  StrLen $4 $2
  StrCpy $5 $1 -$4 ; $5 is now the part before the path to remove
  StrCpy $6 $2 "" $3 ; $6 is now the part after the path to remove
  StrCpy $3 "$5$6"
  StrCpy $5 $3 1 -1
  StrCmp $5 ";" 0 +2
    StrCpy $3 $3 -1 ; remove trailing ';'
  WriteRegExpandStr ${Environ} "PATH" $3
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

done:
  Pop $6
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd


; StrStrEx - find substring in a string
;
; Usage:
;   Push "this is some string"
;   Push "some"
;   Call StrStrEx
;   Pop $0 ; "some string"
; Taken from http://www.smartmontools.org/browser/trunk/smartmontools/os_win32/installer.nsi?rev=4110#L761
!macro StrStrEx un
Function ${un}StrStrEx
  Exch $R1 ; $R1=substring, stack=[old$R1,string,...]
  Exch     ;                stack=[string,old$R1,...]
  Exch $R2 ; $R2=string,    stack=[old$R2,old$R1,...]
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=substring, $R2=string, $R3=strlen(substring)
  ; $R4=count, $R5=tmp
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1 ; $R1=old$R1, stack=[result,...]
FunctionEnd
!macroend
!insertmacro StrStrEx ""
!insertmacro StrStrEx "un."


; Installer section
Section "Hauptgruppe" SEC_INSTALL
	; Our stuff goes into the base directory of the Inkscape installation directory

	SetOutPath $INSTDIR
	SetOverwrite ifnewer

	; The files we want to pack in the installer
	!include ${INST_FILE_LIST}

	; Uninstaller is put into the Inkscape installation directory
	WriteUninstaller "$INSTDIR\${UNINSTALLER_NAME}"

	; Some Registry strings for proper uninstallation
	WriteRegStr ${INSTDIR_REG_ROOT} "${INSTDIR_REG_KEY}" "DisplayName" "${PRODUCT_NAME} ${PRODUCT_VERSION}"
	WriteRegStr ${INSTDIR_REG_ROOT} "${INSTDIR_REG_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
	WriteRegStr ${INSTDIR_REG_ROOT} "${INSTDIR_REG_KEY}" "InstallDir" "$INSTDIR"
	WriteRegStr ${INSTDIR_REG_ROOT} "${INSTDIR_REG_KEY}" "UninstallString" "$INSTDIR\${UNINSTALLER_NAME}"

	; Determine how many bytes we have installed (displayed later in the windows control panel)
	Push $0
	SectionGetSize ${SEC_INSTALL} $0
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD ${INSTDIR_REG_ROOT} "${INSTDIR_REG_KEY}" "EstimatedSize" "$0"
	Pop $0

    ; Set Path
    Push $INSTDIR
    Call AddToPath
SectionEnd


; Uninstaller Section
; $INSTDIR is the directory in which the uninstaller resides!
Section "Uninstall"

	; Delete Files
	!include ${UNINST_FILE_LIST}

	; Delete all registry keys
	DeleteRegKey ${INSTDIR_REG_ROOT} "${INSTDIR_REG_KEY}"

	; Delete the installer
	Delete "$INSTDIR\${UNINSTALLER_NAME}"

    ; Delete the directory
    RMDir $INSTDIR

    ; Delete path
    Push $INSTDIR
    CALL un.RemoveFromPath

SectionEnd