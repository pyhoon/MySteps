B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
'#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'#Macro: Title, Sync Files, ide://run?File=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region
#Region Macros
#Macro: Title, Export, ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip
#Macro: Title, GitHub, ide://run?File=%WINDIR%\System32\cmd.exe&Args=/c&Args=github&Args=..\..\
#Macro: Title, JsonLayouts folder, ide://run?File=%WINDIR%\explorer.exe&Args=%PROJECT%\JsonLayouts
#Macro: After Save, Sync Layouts, ide://run?File=%ADDITIONAL%\..\B4X\JsonLayouts.jar&Args=%PROJECT%&Args=%PROJECT_NAME%
#End Region
Sub Class_Globals
	Private xui As XUI
	Private Root As B4XView
	'Private smiley As Bitmap
	Private kvs As KeyValueStore
	'Private ps As PhoneSensors
	Private lblSteps As B4XView
	Private lblTarget As B4XView
	Private lblDailyTarget As B4XView
	Private ProgressBar1 As B4XProgressBar ' Requires XUI Views library
	' Target Constants / Keys
	Private const KEY_DAILY_TARGET As String = "daily_target_steps"
	Private const DEFAULT_TARGET As Int = 10000
	Private dailyTarget As Int
	'Private initialSteps As Int = -1
	'Private currentSessionSteps As Int = 0
	'Private const KEY_DAY_START As String = "day_start_steps"
	'Private const KEY_LAST_DATE As String = "last_saved_date"
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
	' Initialize KVS in XUI.DefaultFolder
	kvs.Initialize(xui.DefaultFolder, "step_data.dat")
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "MySteps")
	'smiley = LoadBitmapResize(File.DirAssets, "smiley.png", 24dip, 24dip, False)
	'ProgressBar1.Progress = 0
	
	' Load target setting (default to 10,000 steps)
	dailyTarget = kvs.GetDefault(KEY_DAILY_TARGET, DEFAULT_TARGET)
	
	' Force the daily target to 5 steps for testing
	'SetDailyTarget(5) ' uncomment for testing
	
	'Step Counter vs. Step Detector:
	'TYPE_STEP_COUNTER (19) returns total steps since last boot And Is Power-efficient.
	'TYPE_STEP_DETECTOR (18) fires an event on every single Step taken (higher Power draw).

	'StepService handles the PhoneSensors listener independently.
	' TYPE_STEP_COUNTER = 19
	'ps.Initialize(19)
    
	'CheckAndStartSensor
	' Start StepService instead of listening directly on the activity
	'CheckAndStartStepService
	
	'Wait For (CheckAndRequestNotificationPermission) Complete (HasPermission As Boolean)
	'If HasPermission Then
	'	'CallSub(Me, "Simple_Notification")
	'Else
	'	ToastMessageShow("No permission to show notification", True)
	'End If
	
	' Request both permissions back-to-back before starting the service
	Wait For (RequestAllPermissions) Complete (Success As Boolean)
	If Success Then
		StartService(StepService)
	Else
		ToastMessageShow("Activity permission is required for step tracking.", True)
	End If
End Sub

'Called whenever the page becomes visible. Note that in B4J the Appear and Disappear events are only raised when the page is opened and closed. Not when the focus changes to a different window.
Private Sub B4XPage_Appear
	'Dim stepsToday As Int = kvs.GetDefault("steps_today", 0)
	'lblSteps.Text = "Steps Today: " & stepsToday
	' Refresh display on app focus
	Dim stepsToday As Int = kvs.GetDefault("steps_today", 0)
	UpdateStepDisplay(stepsToday)
End Sub

'Called whenever a visible page disappear.
Private Sub B4XPage_Disappear
	'ps.StopListening
End Sub

#If B4A
Private Sub B4XPage_CloseRequest As ResumableSub
	Return True
End Sub

Private Sub B4XPage_KeyPress (KeyCode As Int) As Boolean 'ignore
	Select KeyCode
		Case KeyCodes.KEYCODE_BACK
			'code to handle back key
		Case Else
			Return False 'Pass to Android System
	End Select
End Sub
#End If

'Sub Simple_Notification
'	Dim n As NB6
'	n.Initialize("default", Application.LabelName, "DEFAULT").AutoCancel(True).SmallIcon(smiley)
'	n.Build("Title", "Content", "tag1", Main).Notify(4) 'It will be Main (or any other activity) instead of Me if called from a service.
'End Sub

'Private Sub CheckAndStartSensor
'    Dim rp As RuntimePermissions
'    rp.CheckAndRequest(rp.PERMISSION_ACTIVITY_RECOGNITION)
'    Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
'    
'    If Result Then
'        If ps.StartListening("Sensor") = False Then
'            Log("Step counter sensor not available on this device.")
'        End If
'    Else
'        Log("Activity Recognition permission denied.")
'	End If
'End Sub

'Private Sub CheckAndStartSensor
'    Dim rp As RuntimePermissions
'    
'    ' Pass the explicit permission string directly
'    rp.CheckAndRequest("android.permission.ACTIVITY_RECOGNITION")
'    Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
'    
'    If Result Then
'        If ps.StartListening("Sensor") = False Then
'            Log("Step counter sensor not available on this device.")
'        End If
'    Else
'        Log("Activity Recognition permission denied.")
'    End If
'End Sub

'Private Sub Sensor_SensorChanged (Values() As Float)
'    ' TYPE_STEP_COUNTER returns total steps since device reboot
'    Dim totalStepsSinceReboot As Int = Values(0)
'    
'    If initialSteps = -1 Then
'        initialSteps = totalStepsSinceReboot
'    End If
'    
'    currentSessionSteps = totalStepsSinceReboot - initialSteps
'    lblSteps.Text = "Steps Today: " & currentSessionSteps
'End Sub

'Private Sub Sensor_SensorChanged (Values() As Float)
'    Dim totalStepsSinceReboot As Int = Values(0)
'    Dim todayDate As String = DateTime.Date(DateTime.Now)
'    
'    Dim lastSavedDate As String = kvs.GetDefault(KEY_LAST_DATE, "")
'    Dim dayStartSteps As Int = kvs.GetDefault(KEY_DAY_START, -1)
'    
'    ' 1. Handle Midnight Reset or First Run
'    If todayDate <> lastSavedDate Or dayStartSteps = -1 Then
'        dayStartSteps = totalStepsSinceReboot
'        kvs.Put(KEY_DAY_START, dayStartSteps)
'        kvs.Put(KEY_LAST_DATE, todayDate)
'    End If
'    
'    ' 2. Handle Device Reboot (Sensor value dropped below baseline)
'    If totalStepsSinceReboot < dayStartSteps Then
'        dayStartSteps = 0
'        kvs.Put(KEY_DAY_START, dayStartSteps)
'    End If
'    
'    ' 3. Calculate actual steps taken today
'    Dim stepsToday As Int = totalStepsSinceReboot - dayStartSteps
'    Log("Steps Today: " & stepsToday)
'	lblSteps.Text = "Steps Today: " & stepsToday
'End Sub

'Private Sub CheckAndStartStepService
'	Dim rp As RuntimePermissions
'	rp.CheckAndRequest("android.permission.ACTIVITY_RECOGNITION")
'	Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
'    
'	If Result Then
'		' Start the foreground service
'		StartService(StepService)
'	Else
'		Log("Permission denied. Step tracking disabled.")
'	End If
'End Sub

' Called from StepService when new steps are logged
'Public Sub UpdateStepDisplay (steps As Int)
'	lblSteps.Text = "Steps Today: " & steps
'End Sub

' Called from StepService or local UI refresh
Public Sub UpdateStepDisplay (steps As Int)
    lblSteps.Text = "Steps Today: " & steps
    
    ' Calculate progress percentage
    Dim progress As Float = steps / dailyTarget
    If progress > 1.0 Then progress = 1.0 ' Cap bar at 100%
    
    ' Update B4XProgressBar (Value ranges from 0 to 100 or 0.0 to 1.0 depending on properties)
	ProgressBar1.Progress = progress * 100
    
    ' Update target display label
    Dim pct As Int = Floor((steps / dailyTarget) * 100)
    lblTarget.Text = steps & " / " & dailyTarget & " steps (" & pct & "%)"
End Sub

' Optional: Add a Sub to change the target dynamically
'Public Sub SetDailyTarget (newTarget As Int)
'	dailyTarget = newTarget
'	kvs.Put(KEY_DAILY_TARGET, newTarget)
'    
'	Dim stepsToday As Int = kvs.GetDefault("steps_today", 0)
'	UpdateStepDisplay(stepsToday)
'End Sub

Public Sub SetDailyTarget (newTarget As Int)
    dailyTarget = newTarget
    kvs.Put(KEY_DAILY_TARGET, newTarget)
    
    If lblDailyTarget.IsInitialized Then
        lblDailyTarget.Text = "Daily target " & NumberFormat(newTarget, 0, 0) & " steps"
    End If
    
    Dim stepsToday As Int = kvs.GetDefault("steps_today", 0)
    UpdateStepDisplay(stepsToday)
End Sub

'Private Sub CheckAndRequestNotificationPermission As ResumableSub
'	Dim p As Phone
'	If p.SdkVersion < 33 Then Return True
'	Dim ctxt As JavaObject
'	ctxt.InitializeContext
'	Dim targetSdkVersion As Int = ctxt.RunMethodJO("getApplicationInfo", Null).GetField("targetSdkVersion")
'	If targetSdkVersion < 33 Then Return True
'	Dim NotificationsManager As JavaObject = ctxt.RunMethod("getSystemService", Array("notification"))
'	Dim NotificationsEnabled As Boolean = NotificationsManager.RunMethod("areNotificationsEnabled", Null)
'	If NotificationsEnabled Then Return True
'	Dim rp As RuntimePermissions
'	rp.CheckAndRequest(rp.PERMISSION_POST_NOTIFICATIONS)
'	Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean) 'change to Activity_PermissionResult if non-B4XPages.
'	Return Result
'End Sub

Private Sub RequestAllPermissions As ResumableSub
	Dim rp As RuntimePermissions
    
	' 1. Request Physical Activity Recognition
	rp.CheckAndRequest("android.permission.ACTIVITY_RECOGNITION")
	Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
	If Result = False Then
		Log("Activity Recognition permission denied.")
		Return False
	End If
    
	' 2. Request Post Notifications (Android 13+ / API 33+)
	Dim p As Phone
	If p.SdkVersion >= 33 Then
		rp.CheckAndRequest(rp.PERMISSION_POST_NOTIFICATIONS)
		Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
		If Result = False Then
			Log("Notification permission denied.")
			' We can still return True so step tracking starts even if notification popups are disabled
		End If
	End If
    
	Return True
End Sub