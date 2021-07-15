#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Outfile=SdbaParser32.exe
#AutoIt3Wrapper_Outfile_x64=SdbaParser64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_Comment=Sdba pool tag parser
#AutoIt3Wrapper_Res_Description=Sdba pool tag parser
#AutoIt3Wrapper_AU3Check_Parameters=-w 3 -w 5
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/sf /sv /rm /pe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <FontConstants.au3>
#include <ButtonConstants.au3>
#Include <WinAPIEx.au3>

Global $de = "|", $sTimestamp, $filepathLength, $isX64, $blocksizetimestamp
Global $csv_columns = "offset"&$de&"source"&$de&"size_previous"&$de&"size_current"&$de&"timestamp"&$de&"filepath"
Global $stringArray2[] = ["[\x06]Sdba"]

Global $hexRegExArray2[] = ["[\x03|\x06]\x53\x64\x62\x61"]
Global $arr_hits[0][0]

Global $blocksize, $charmove, $tagSdba

Global $DateTimeFormat = 6
Global $TimestampPrecision = 3 ; 3=nansec, 2=millisec, 1=sec
Global $PrecisionSeparator = ".", $PrecisionSeparator2 = ""
Global $_COMMON_KERNEL32DLL=DllOpen("kernel32.dll")
Global $TimestampErrorVal = "0000-00-00 00:00:00"
Global $tDelta = _WinTime_GetUTCToLocalFileTimeDelta()

Global $AdlibInterval = 5000 ;Millisec for the script to halt and update progress bar
Global $ProgressBar2, $CurrentProgress2 = 0, $ProgressTotal2 = 0
Global $ProgressBar3, $CurrentProgress3 = 0, $ProgressTotal3 = 0

Global $ButtonColor = 0x2f4e57, $active = False
Global $myctredit, $ButtonCancel, $ButtonStart, $ButtonOpenOutput, $LabelProgress3, $ButtonOutput, $OutputField, $LabelOutput
Global $ButtonInput, $InputField, $Form, $radio32,$radio64
Global $file_input, $folder_output = @ScriptDir, $OutPutPath = @ScriptDir
Global $CommandlineMode, $mainlogfile, $TargetInput, $hCsv

If $cmdline[0] > 0 Then
	$CommandlineMode = 1
	_GetInputParams()
	_Init()
	Exit
Else
	DllCall("kernel32.dll", "bool", "FreeConsole")
	$CommandlineMode = 0
	OnAutoItExitRegister("_GuiExitMessage")

	Opt("GUIOnEventMode", 1)
	$Form = GUICreate("Sdba parser", 830, 500, -1, -1)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_HandleExit")

	$LabelInput = GUICtrlCreateLabel("Select input file:", 20, 20, 120, 20)
	$InputField = GUICtrlCreateInput("", 140, 20, 510, 20)
	GUICtrlSetState($InputField, $GUI_DISABLE)
	$ButtonInput = GUICtrlCreateButton("Browse", 700, 20, 100, 30)
	GUICtrlSetOnEvent($ButtonInput, "_HandleEvent")
	GUICtrlSetBkColor(-1, $ButtonColor)
	GUICtrlSetFont(-1, 9, $FW_SEMIBOLD,  $GUI_FONTNORMAL, "",  $CLEARTYPE_QUALITY)
	GUICtrlSetColor(-1, 0xFFFFFF)


	$LabelOutput = GUICtrlCreateLabel("Select output folder:", 20, 70, 120, 20)
	$OutputField = GUICtrlCreateInput("Optional. Defaults to program directory", 140, 70, 510, 20)
	GUICtrlSetState($OutputField, $GUI_DISABLE)
	$ButtonOutput = GUICtrlCreateButton("Browse", 700, 70, 100, 30)
	GUICtrlSetOnEvent($ButtonOutput, "_HandleEvent")
	GUICtrlSetBkColor(-1, $ButtonColor)
	GUICtrlSetFont(-1, 9, $FW_SEMIBOLD,  $GUI_FONTNORMAL, "",  $CLEARTYPE_QUALITY)
	GUICtrlSetColor(-1, 0xFFFFFF)

	$radio32 = GUICtrlCreateRadio("Source is x32", 30, 110, 100, 20)
	$radio64 = GUICtrlCreateRadio("Source is x64", 30, 140, 100, 20)

	$LabelProgress2 = GUICtrlCreateLabel("Progress regex scan:", 10, 210, 200, 20)
	$ProgressBar2 = GUICtrlCreateProgress(10, 230, 810, 30)
	$LabelProgress3 = GUICtrlCreateLabel("Progress tag parsing:", 10, 270, 200, 20)
	$ProgressBar3 = GUICtrlCreateProgress(10, 290, 810, 30)

	$ButtonStart = GUICtrlCreateButton("Start Parsing", 20, 450, 150, 40, $BS_BITMAP)
	GUICtrlSetOnEvent($ButtonStart, "_HandleEvent")
	GUICtrlSetBkColor(-1, $ButtonColor)
	GUICtrlSetFont(-1, 9, $FW_SEMIBOLD,  $GUI_FONTNORMAL, "",  $CLEARTYPE_QUALITY)
	GUICtrlSetColor(-1, 0xFFFFFF)
	$ButtonCancel = GUICtrlCreateButton("Exit", 175, 450, 150, 40)
	GUICtrlSetOnEvent($ButtonCancel, "_HandleCancel")
	GUICtrlSetBkColor(-1, $ButtonColor)
	GUICtrlSetFont(-1, 9, $FW_SEMIBOLD,  $GUI_FONTNORMAL, "",  $CLEARTYPE_QUALITY)
	GUICtrlSetColor(-1, 0xFFFFFF)
	$ButtonOpenOutput = GUICtrlCreateButton("Open Output", 330, 450, 150, 40)
	GUICtrlSetOnEvent($ButtonOpenOutput, "_HandleOpenOutput")
	GUICtrlSetBkColor(-1, $ButtonColor)
	GUICtrlSetFont(-1, 9, $FW_SEMIBOLD,  $GUI_FONTNORMAL, "",  $CLEARTYPE_QUALITY)
	GUICtrlSetColor(-1, 0xFFFFFF)

	$myctredit = GUICtrlCreateEdit("", 0, 330, 830, 100, BitOR($ES_AUTOVSCROLL,$WS_VSCROLL))
	_GUICtrlEdit_SetLimitText($myctredit, 128000)

	GUISetState(@SW_SHOW)

	While Not $active
		;Wait for event. The $active variable is set when parsing and reset when done in order for multiple parsing executions to run subsequently

		Sleep(500)
		If $active Then
			_HandleParsing()
			$active = False
		EndIf
	WEnd

EndIf

Func _Init()

	$sTimestamp = ""
	$filepathLength = 0
	$CurrentProgress3 = 0
	ReDim $arr_hits[0][0]
	_ResetProgress($ProgressBar2)
	_ResetProgress($ProgressBar3)

	Local $sTimestampStart = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC
	$OutPutPath = $folder_output & "\SdbaParser-" & $sTimestampStart
	If DirCreate($OutputPath) = 0 Then
		_DisplayWrapper("Error creating: " & $OutputPath & @CRLF)
		Return
	EndIf
	$mainlogfile = FileOpen($OutPutPath & "\" & "logfile.txt", 2+32)
	If @error Then
		_DisplayWrapper("Error: Could not open logfile" & @CRLF)
		Return
	EndIf
	_DumpOut("Parsing " & $TargetInput & @CRLF)
	_DisplayWrapper("Parsing " & $TargetInput & @CRLF)

	_DisplayWrapper("Writing output to: " & $OutPutPath & @CRLF)

	$hCsv = FileOpen($OutPutPath & "\sdba.csv", 2)
	FileWriteLine($hCsv, $csv_columns)

	; set some variables used in _main that depends on arch
	If $isX64 Then
		$blocksize = 16
		$charmove = 13
		$tagSdba = "byte;byte;byte;byte;char[4];byte[56];ushort;ushort;byte[12];uint64;uint;uint;byte[8]"
		$blocksizetimestamp = 7
		_DumpOut("Architecture: x64 " & @CRLF)
	Else
		$blocksize = 8
		$charmove = 5
		$tagSdba = "byte;byte;byte;byte;char[4];byte[24];ushort;ushort;byte[4];uint64;uint;uint;byte[8]"
		$blocksizetimestamp = 8
		_DumpOut("Architecture: x32 " & @CRLF)
	EndIf

	Local $Timerstart = TimerInit()

	Global $coreFileName = _GetFilenameFromPath($TargetInput)

	Global $arr_hits[0][2]
	Local $matches, $totalMatches

	_DisplayWrapper("Searching for signatures..." & @CRLF)

	For $i = 0 To UBound($hexRegExArray2) - 1
		$matches = _Signature2Array_v2($TargetInput, $arr_hits, $stringArray2[$i], $hexRegExArray2[$i])
		$totalMatches += $matches
	Next

	GUICtrlSetData($ProgressBar2, 100)

	AdlibRegister("_UpdateProgress3", $AdlibInterval)

	Local $hFile = _WinAPI_CreateFile($TargetInput, 2, 6, 7)
	If Not $hFile Then
		ConsoleWrite("Error in CreateFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Exit
	EndIf

	Global $fileSize = _WinAPI_GetFileSizeEx($hFile)
	_DumpOut("fileSize: " & $fileSize & @CRLF)

	_DumpOut("found signatures: " & $totalMatches & @CRLF)
	_DisplayWrapper("found signatures: " & $totalMatches & @CRLF)

	;Local $nBytes
	_WinAPI_SetFilePointerEx($hFile, 0, $FILE_BEGIN)

	$ProgressTotal3 = UBound($arr_hits)

	For $i = 0 To UBound($arr_hits) - 1
		$CurrentProgress3 = $i
		_main($hFile, $i)
	Next


	_DumpOut("Job took " & _WinAPI_StrFromTimeInterval(TimerDiff($Timerstart)) & @CRLF)
	_DisplayWrapper("Job took " & _WinAPI_StrFromTimeInterval(TimerDiff($Timerstart)) & @CRLF)

	_WinAPI_CloseHandle($hFile)
	FileClose($mainlogfile)
	FileClose($hCsv)

	GUICtrlSetData($ProgressBar3, 100)
	AdlibUnRegister("_UpdateProgress3")
EndFunc

Func _GetInputParams()
	Local $TmpInputPath, $TmpOutPath, $TmpArch
	For $i = 1 To $cmdline[0]
		;ConsoleWrite("Param " & $i & ": " & $cmdline[$i] & @CRLF)
		If StringLeft($cmdline[$i],2) = "/?" Or StringLeft($cmdline[$i],2) = "-?" Or StringLeft($cmdline[$i],2) = "-h" Then _PrintHelp()
		If StringLeft($cmdline[$i],7) = "/Input:" Then $TmpInputPath = StringMid($cmdline[$i],8)
		If StringLeft($cmdline[$i],8) = "/Output:" Then $TmpOutPath = StringMid($cmdline[$i],9)
		If StringLeft($cmdline[$i],6) = "/Arch:" Then $TmpArch = StringMid($cmdline[$i],7)
	Next

	If StringLen($TmpOutPath) > 0 Then

		If FileExists($TmpOutPath) Then
			$folder_output = $TmpOutPath
		Else
			ConsoleWrite("Warning: The specified Output path could not be found: " & $TmpOutPath & @CRLF)
			ConsoleWrite("Relocating output to current directory: " & @ScriptDir & @CRLF)
			$folder_output = @ScriptDir
		EndIf
	EndIf

	If StringLen($TmpInputPath) > 0 Then

		If Not FileExists($TmpInputPath) And StringInStr($TmpInputPath, "*") = 0 Then
			ConsoleWrite("Error: Could not find input: " & $TmpInputPath & @CRLF)
			Exit
		EndIf
		$TargetInput = $TmpInputPath
	Else
		ConsoleWrite("Error: missing input" & @CRLF)
		Exit
	EndIf

	If StringLen($TmpArch) > 0 Then

		Select
			Case $TmpArch = "32"
				$isX64 = 0
			Case $TmpArch = "64"
				$isX64 = 1
			Case Else
				ConsoleWrite("Error: Could not validate arch: " & $TmpArch & @CRLF)
				Exit
		EndSelect
	Else
		ConsoleWrite("Error: missing arch" & @CRLF)
		Exit
	EndIf


EndFunc

Func _HandleCancel()
	Exit
EndFunc

Func _HandleExit()
	Exit
EndFunc

Func _ResetProgress($ProgressBar)
	GUICtrlSetData($ProgressBar, 0)
EndFunc


Func _UpdateProgress3()
    GUICtrlSetData($ProgressBar3, 100 * $CurrentProgress3 / $ProgressTotal3)
EndFunc

Func _PrintBeforeExit($input)
	_DumpOut($input)
	_DisplayWrapper($input)
EndFunc

Func _DisplayWrapper($input)

	If $CommandlineMode Then
		ConsoleWrite($input)
	Else
		_DisplayInfo($input)
	EndIf

EndFunc

Func _DumpOut($text)
;	ConsoleWrite($text)
	If $mainlogfile Then FileWrite($mainlogfile, $text)
EndFunc

Func _DisplayInfo($DebugInfo)
	GUICtrlSetData($myctredit, $DebugInfo, 1)
EndFunc

Func _GuiExitMessage()
	If Not $CommandlineMode Then
		If @exitCode Then
			MsgBox(0, "Error", "An error was triggered. Check the output buffer.")
		EndIf
	EndIf
EndFunc

Func _HandleEvent()
	If Not $active Then
		Switch @GUI_CtrlId
			Case $ButtonInput
				_HandleFileInput()
;			Case $ButtonFolder
;				_HandleFolderInput()
			Case $ButtonOutput
				_HandleOutput()
			Case $ButtonStart
				$active = True
			Case $ButtonCancel
				_HandleCancel()
			Case $ButtonOpenOutput
				_HandleOpenOutput()
			Case $GUI_EVENT_CLOSE
				_HandleExit()
		EndSwitch
	EndIf
EndFunc

Func _HandleFileInput()
	$file_input = FileOpenDialog("Select input file", @ScriptDir, "All (*.*)")
	If $file_input Then
		GUICtrlSetData($InputField, $file_input)
	EndIf

	_ResetProgress($ProgressBar2)
	_ResetProgress($ProgressBar3)
EndFunc


Func _HandleOpenOutput()
	Run("explorer.exe " & $OutPutPath)
EndFunc

Func _HandleOutput()
	$folder_output = FileSelectFolder("Select output folder", @ScriptDir)
	If $folder_output Then
		GUICtrlSetData($OutputField, $folder_output)
	EndIf

	_ResetProgress($ProgressBar2)
	_ResetProgress($ProgressBar3)
EndFunc

Func _HandleParsing()
	_ResetProgress($ProgressBar2)
	_ResetProgress($ProgressBar3)
	If _GuiGetSettings() Then
		_Init()
	EndIf
EndFunc

Func _GuiGetSettings()

	If Int(GUICtrlRead($radio32) + GUICtrlRead($radio64)) <> 5 Then
		_DisplayInfo("Error: You must configure source architecture (x32 or x64)" & @CRLF)
		Return
	EndIf

	Select
		Case Int(GUICtrlRead($radio32)) = 1
			$isX64 = 0
			_DisplayInfo("Architecture: x32" & @CRLF)
		Case Int(GUICtrlRead($radio64)) = 1
			$isX64 = 1
			_DisplayInfo("Architecture: x64" & @CRLF)
	EndSelect

	$TargetInput = $file_input
	If Not FileExists($TargetInput) Then
		_DisplayInfo("Error: input not found: " & $TargetInput & @CRLF)
		Return
	EndIf

	If Not FileExists($OutPutPath) Then
		_DisplayInfo("Error: output directory not found: " & $OutPutPath & @CRLF)
		Return
	EndIf

	Return 1

EndFunc

Func _GUI_Disable_Control()
	GUICtrlSetData($myctredit, "Processing started.." & @CRLF)
	GUICtrlSetState($ButtonInput, $GUI_DISABLE)
	GUICtrlSetState($ButtonOutput, $GUI_DISABLE)
	GUICtrlSetState($ButtonStart, $GUI_DISABLE)
EndFunc

Func _GUI_Enable_Controls()
	GUICtrlSetState($ButtonInput, $GUI_ENABLE)
	GUICtrlSetState($ButtonOutput, $GUI_ENABLE)
	GUICtrlSetState($ButtonStart, $GUI_ENABLE)
EndFunc

Func _main($hFile, $row)

	Local $nBytes
	Local $startOffset = $arr_hits[$row][0]

	_DumpOut("Trying signature " & $row & " at 0x" & Hex($startOffset, 8) & @CRLF)

	Local $pTmpBuff1 = DllStructCreate($tagSdba)

	_WinAPI_SetFilePointerEx($hFile, $startOffset - 3, $FILE_BEGIN)
	_WinAPI_ReadFile($hFile, DllStructGetPtr($pTmpBuff1), DllStructGetSize($pTmpBuff1), $nBytes)

	;Local $testChunk = DllStructGetData($pTmpBuff1, 1)
	;ConsoleWrite(_HexEncode($testChunk))

	Local $prevSize = DllStructGetData($pTmpBuff1, 1) ; prev_size
;	Local $unk1 = DllStructGetData($pTmpBuff1, 2)
	Local $currSize = DllStructGetData($pTmpBuff1, 3) ; curr_size
;	Local $fixedStartByte = DllStructGetData($pTmpBuff1, 4) ; 0x06
	Local $poolTag = DllStructGetData($pTmpBuff1, 5) ; signature - Sdba
;	Local $unk2 = DllStructGetData($pTmpBuff1, 6)
	Local $filepathSize1 = DllStructGetData($pTmpBuff1, 7); the filepath bytes
;	Local $filepathSize2 = DllStructGetData($pTmpBuff1, 8)
	Local $timestampVal = DllStructGetData($pTmpBuff1, 10) ; timestamp
;	Local $executableType = DllStructGetData($pTmpBuff1, 11) ; 7=exe, 6=admin/shortname, 5=dll, E=exe/office ?,
;	Local $unk3 = DllStructGetData($pTmpBuff1, 12)

	If $poolTag <> "Sdba" Then
;		ConsoleWrite("Error: Wrong signature" & @CRLF)
		Return
	EndIf

	Local $sFilePath

	If $currSize < 4 Then
		FileWriteLine($hCsv, "0x"&Hex($startOffset - 3, 8) & $de & $coreFileName & $de & $prevSize & $de & $currSize & $de & $sTimestamp & $de & $sFilePath & @CRLF)
		Return
	EndIf

	; sanity check on the tiemstamp to filter out corrupt or invalid data
	If $timestampVal < 112589990684262400 Or $timestampVal > 139611588448485376 Then
;		ConsoleWrite("Error: Bad timestamp" & @CRLF)
		$entrySize = $currSize * $blocksize
;		ConsoleWrite("Testing filepath with size: " & $entrySize & @CRLF)
		Local $pTmpBuff2 = DllStructCreate("byte[" & $entrySize & "]")
		_WinAPI_SetFilePointerEx($hFile, $startOffset + $charmove, $FILE_BEGIN)
		_WinAPI_ReadFile($hFile, DllStructGetPtr($pTmpBuff2), DllStructGetSize($pTmpBuff2), $nBytes)
		$pFilePath = DllStructCreate("wchar[" & ($entrySize - $blocksize) / 2 & "]", DllStructGetPtr($pTmpBuff2))
		$sFilePath = DllStructGetData($pFilePath, 1)
		If StringMid($sFilePath, 1, 4) <> "\??\" Then
			$sFilePath = ""
			FileWriteLine($hCsv, "0x"&Hex($startOffset - 3, 8) & $de & $coreFileName & $de & $prevSize & $de & $currSize & $de & $sTimestamp & $de & $sFilePath & @CRLF)
		Else
			If ($prevSize <> 1 And $prevSize <> $blocksizetimestamp And $prevSize <> 58) Or $filepathLength/2 <> StringLen($sFilePath)  Then
				; a check if the previous entry was a timestamp. if not then reset it
				$sTimestamp = ""
			EndIf
			FileWriteLine($hCsv, "0x"&Hex($startOffset - 3, 8) & $de & $coreFileName & $de & $prevSize & $de & $currSize & $de & $sTimestamp & $de & $sFilePath & @CRLF)
			$sTimestamp = ""
		EndIf
;		ConsoleWrite("$sFilePath: " & $sFilePath & @CRLF)
		Return
	Else
		$sTimestamp = _DecodeTimestampDecimal($timestampVal)
;		ConsoleWrite("$sTimestamp: " & $sTimestamp & @CRLF)
		$filepathLength = $filepathSize1
	EndIf

	FileWriteLine($hCsv, "0x"&Hex($startOffset - 3, 8) & $de & $coreFileName & $de & $prevSize & $de & $currSize & $de & $sTimestamp & $de & $sFilePath & @CRLF)

	Return

EndFunc


Func _Signature2Array_v2($FilePath, ByRef $arr, $TargetString, $RegexString)

	Local $sPSScript = '"' & @ScriptDir & "\sigscan.ps1" & '"'

	Local $sCMD = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File " & $sPSScript & " -hex " & $RegexString & " -filepath " & '"' & $FilePath & '"'

	Local $pid = Run($sCMD, @SystemDir, @SW_HIDE, $STDIN_CHILD + $STDOUT_CHILD + $STDERR_CHILD)
	If @error Then
		_DumpOut("Error: Could not execute external script" & @CRLF)
		Exit
	EndIf

	StdinWrite($pid)
	Local $AllOutput = "", $sOutput = ""
	Local $hTimer = TimerInit()
	While 1
		$sOutput = StdoutRead($pid)
		If @error Then ExitLoop
		If $sOutput <> "" Then $AllOutput &= $sOutput
		If Not ProcessExists($pid) Then ExitLoop
		; exit the loop if processing is +10 min
		If TimerDiff($hTimer) > 600000 Then ExitLoop
	WEnd

;	ConsoleWrite("$AllOutput" & @CRLF)
;	ConsoleWrite($AllOutput & @CRLF)

	If StringInStr($AllOutput, "Error") Then
		_DumpOut("Error: Something went wrong in the parsing of input" & @CRLF)
		Return 0
	EndIf


	Local $OutputArray = StringSplit($AllOutput, @CRLF)
	;_ArrayDisplay($OutputArray, "$OutputArray")

	Local $counter = 0
	Local $currentArraySize = UBound($arr)
	ReDim $arr[$currentArraySize + $OutputArray[0]][2]
	For $i = 1 To $OutputArray[0]
		If $OutputArray[$i] = "" Then
			ContinueLoop
		EndIf
		If StringLeft($OutputArray[$i], 2) <> "0x" Then
			ContinueLoop
		EndIf
		If StringLen($OutputArray[$i]) <> 18 Then
			ContinueLoop
		EndIf
		$arr[$currentArraySize + $counter][0] = Number($OutputArray[$i])
		$arr[$currentArraySize + $counter][1] = $TargetString
		$counter += 1
	Next

	ReDim $arr[$currentArraySize + $counter][2]
;	_ArrayDisplay($arr, "$arr")
	Return $counter
EndFunc

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc

Func _HexEncode($bInput)
    Local $tInput = DllStructCreate("byte[" & BinaryLen($bInput) & "]")
    DllStructSetData($tInput, 1, $bInput)
    Local $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", 0, _
            "dword*", 0)

    If @error Or Not $a_iCall[0] Then
        Return SetError(1, 0, "")
    EndIf
    Local $iSize = $a_iCall[5]
    Local $tOut = DllStructCreate("char[" & $iSize & "]")
    $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", DllStructGetPtr($tOut), _
            "dword*", $iSize)
    If @error Or Not $a_iCall[0] Then
        Return SetError(2, 0, "")
    EndIf
    Return SetError(0, 0, DllStructGetData($tOut, 1))
EndFunc

Func _DecodeTimestamp($StampDecode)
	$StampDecode = _SwapEndian($StampDecode)
	$StampDecode_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $StampDecode)
	$StampDecode = _WinTime_UTCFileTimeFormat(Dec($StampDecode,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$StampDecode = $TimestampErrorVal
	ElseIf $TimestampPrecision = 3 Then
		$StampDecode = $StampDecode & $PrecisionSeparator2 & _FillZero(StringRight($StampDecode_tmp, 4))
	EndIf
	Return $StampDecode
EndFunc

Func _WinTime_GetUTCToLocalFileTimeDelta()
	Local $iUTCFileTime=864000000000		; exactly 24 hours from the origin (although 12 hours would be more appropriate (max variance = 12))
	$iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,-1)
	Return $iLocalFileTime-$iUTCFileTime	; /36000000000 = # hours delta (effectively giving the offset in hours from UTC/GMT)
EndFunc

Func _WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If $iUTCFileTime<0 Then Return SetError(1,0,-1)
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToLocalFileTime","uint64*",$iUTCFileTime,"uint64*",0)
	If @error Then Return SetError(2,@error,-1)
	If Not $aRet[0] Then Return SetError(3,0,-1)
	Return $aRet[2]
EndFunc

Func _WinTime_UTCFileTimeFormat($iUTCFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iUTCFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; First convert file time (UTC-based file time) to 'local file time'
	Local $iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,"")
	; Rare occassion: a filetime near the origin (January 1, 1601!!) is used,
	;	causing a negative result (for some timezones). Return as invalid param.
	If $iLocalFileTime<0 Then Return SetError(1,0,"")

	; Then convert file time to a system time array & format & return it
	Local $vReturn=_WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iLocalFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; Convert file time to a system time array & return result
	Local $aSysTime=_WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	If @error Then Return SetError(@error,@extended,"")

	; Return only the SystemTime array?
	If $iFormat=0 Then Return $aSysTime

	Local $vReturn=_WinTime_FormatTime($aSysTime[0],$aSysTime[1],$aSysTime[2],$aSysTime[3], _
		$aSysTime[4],$aSysTime[5],$aSysTime[6],$aSysTime[7],$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	Local $aRet,$stSysTime,$aSysTime[8]=[-1,-1,-1,-1,-1,-1,-1,-1]

	; Negative values unacceptable
	If $iLocalFileTime<0 Then Return SetError(1,0,$aSysTime)

	; SYSTEMTIME structure [Year,Month,DayOfWeek,Day,Hour,Min,Sec,Milliseconds]
	$stSysTime=DllStructCreate("ushort[8]")

	$aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToSystemTime","uint64*",$iLocalFileTime,"ptr",DllStructGetPtr($stSysTime))
	If @error Then Return SetError(2,@error,$aSysTime)
	If Not $aRet[0] Then Return SetError(3,0,$aSysTime)
	Dim $aSysTime[8]=[DllStructGetData($stSysTime,1,1),DllStructGetData($stSysTime,1,2),DllStructGetData($stSysTime,1,4),DllStructGetData($stSysTime,1,5), _
		DllStructGetData($stSysTime,1,6),DllStructGetData($stSysTime,1,7),DllStructGetData($stSysTime,1,8),DllStructGetData($stSysTime,1,3)]
	Return $aSysTime
EndFunc

Func _WinTime_FormatTime($iYear,$iMonth,$iDay,$iHour,$iMin,$iSec,$iMilSec,$iDayOfWeek,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
	Local Static $_WT_aMonths[12]=["January","February","March","April","May","June","July","August","September","October","November","December"]
	Local Static $_WT_aDays[7]=["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

	If Not $iFormat Or $iMonth<1 Or $iMonth>12 Or $iDayOfWeek>6 Then Return SetError(1,0,"")

	; Pad MM,DD,HH,MM,SS,MSMSMSMS as necessary
	Local $sMM=StringRight(0&$iMonth,2),$sDD=StringRight(0&$iDay,2),$sMin=StringRight(0&$iMin,2)
	; $sYY = $iYear	; (no padding)
	;	[technically Year can be 1-x chars - but this is generally used for 4-digit years. And SystemTime only goes up to 30827/30828]
	Local $sHH,$sSS,$sMS,$sAMPM

	; 'Extra precision 1': +SS (Seconds)
	If $iPrecision Then
		$sSS=StringRight(0&$iSec,2)
		; 'Extra precision 2': +MSMSMSMS (Milliseconds)
		If $iPrecision>1 Then
;			$sMS=StringRight('000'&$iMilSec,4)
			$sMS=StringRight('000'&$iMilSec,3);Fixed an erronous 0 in front of the milliseconds
		Else
			$sMS=""
		EndIf
	Else
		$sSS=""
		$sMS=""
	EndIf
	If $bAMPMConversion Then
		If $iHour>11 Then
			$sAMPM=" PM"
			; 12 PM will cause 12-12 to equal 0, so avoid the calculation:
			If $iHour=12 Then
				$sHH="12"
			Else
				$sHH=StringRight(0&($iHour-12),2)
			EndIf
		Else
			$sAMPM=" AM"
			If $iHour Then
				$sHH=StringRight(0&$iHour,2)
			Else
			; 00 military = 12 AM
				$sHH="12"
			EndIf
		EndIf
	Else
		$sAMPM=""
		$sHH=StringRight(0 & $iHour,2)
	EndIf

	Local $sDateTimeStr,$aReturnArray[3]

	; Return an array? [formatted string + "Month" + "DayOfWeek"]
	If BitAND($iFormat,0x10) Then
		$aReturnArray[1]=$_WT_aMonths[$iMonth-1]
		If $iDayOfWeek>=0 Then
			$aReturnArray[2]=$_WT_aDays[$iDayOfWeek]
		Else
			$aReturnArray[2]=""
		EndIf
		; Strip the 'array' bit off (array[1] will now indicate if an array is to be returned)
		$iFormat=BitAND($iFormat,0xF)
	Else
		; Signal to below that the array isn't to be returned
		$aReturnArray[1]=""
	EndIf

	; Prefix with "DayOfWeek "?
	If BitAND($iFormat,8) Then
		If $iDayOfWeek<0 Then Return SetError(1,0,"")	; invalid
		$sDateTimeStr=$_WT_aDays[$iDayOfWeek]&', '
		; Strip the 'DayOfWeek' bit off
		$iFormat=BitAND($iFormat,0x7)
	Else
		$sDateTimeStr=""
	EndIf

	If $iFormat<2 Then
		; Basic String format: YYYYMMDDHHMM[SS[MSMSMSMS[ AM/PM]]]
		$sDateTimeStr&=$iYear&$sMM&$sDD&$sHH&$sMin&$sSS&$sMS&$sAMPM
	Else
		; one of 4 formats which ends with " HH:MM[:SS[:MSMSMSMS[ AM/PM]]]"
		Switch $iFormat
			; /, : Format - MM/DD/YYYY
			Case 2
				$sDateTimeStr&=$sMM&'/'&$sDD&'/'
			; /, : alt. Format - DD/MM/YYYY
			Case 3
				$sDateTimeStr&=$sDD&'/'&$sMM&'/'
			; "Month DD, YYYY" format
			Case 4
				$sDateTimeStr&=$_WT_aMonths[$iMonth-1]&' '&$sDD&', '
			; "DD Month YYYY" format
			Case 5
				$sDateTimeStr&=$sDD&' '&$_WT_aMonths[$iMonth-1]&' '
			Case 6
				$sDateTimeStr&=$iYear&'-'&$sMM&'-'&$sDD
				$iYear=''
			Case Else
				Return SetError(1,0,"")
		EndSwitch
		$sDateTimeStr&=$iYear&' '&$sHH&':'&$sMin
		If $iPrecision Then
			$sDateTimeStr&=':'&$sSS
;			If $iPrecision>1 Then $sDateTimeStr&=':'&$sMS
			If $iPrecision>1 Then $sDateTimeStr&=$PrecisionSeparator&$sMS
		EndIf
		$sDateTimeStr&=$sAMPM
	EndIf
	If $aReturnArray[1]<>"" Then
		$aReturnArray[0]=$sDateTimeStr
		Return $aReturnArray
	EndIf
	Return $sDateTimeStr
EndFunc

Func _FillZero($inp)
	Local $out, $tmp = ""
	Local $inplen = StringLen($inp)
	For $i = 1 To 4 - $inplen
		$tmp &= "0"
	Next
	$out = $tmp & $inp
	Return $out
EndFunc

Func _DecodeTimestampDecimal($TheTime)
	$TheTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & Hex($TheTime,16))
	$TheTime = _WinTime_UTCFileTimeFormat($TheTime - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$TheTime = $TimestampErrorVal
	ElseIf $TimestampPrecision = 3 Then
		$TheTime = $TheTime & $PrecisionSeparator2 & _FillZero(StringRight($TheTime_tmp, 4))
	EndIf
	Return $TheTime
EndFunc

Func _GetFilenameFromPath($FileNamePath)
	$stringlength = StringLen($FileNamePath)
	If $stringlength = 0 Then Return SetError(1,0,0)
	$TmpOffset = StringInStr($FileNamePath, "\", 1, -1)
	If $TmpOffset = 0 Then Return $FileNamePath
	Return StringMid($FileNamePath,$TmpOffset+1)
EndFunc

Func _PrintHelp()
	ConsoleWrite("Syntax:" & @CRLF)
	ConsoleWrite("SdbaParser.exe /Input: /Output: /Arch:" & @CRLF)
	ConsoleWrite("   Input: Full path to the file to parse" & @CRLF)
	ConsoleWrite("   Output: Optionally set path for the output. Defaults to program directory." & @CRLF)
	ConsoleWrite("   Arch: The source architecture. Must be 32 or 64." & @CRLF & @CRLF)
	ConsoleWrite("Examples:" & @CRLF)
	ConsoleWrite("SdbaParser.exe /Input:D:\temp\ActiveMemory.bin /Output:D:\temp /Arch:32" & @CRLF)
	ConsoleWrite("SdbaParser.exe /Input:D:\temp\pagefile.sys /Arch:64" & @CRLF)
	Exit
EndFunc