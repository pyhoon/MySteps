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
	Private kvs As KeyValueStore
	Private lblSteps As B4XView
	Private lblTarget As B4XView
	Private lblDailyTarget As B4XView
	Private btnOverrideSteps As Button
	Private ProgressBar1 As B4XProgressBar
	Private dailyTarget As Int
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
	kvs.Initialize(xui.DefaultFolder, "step_data.dat")
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "MySteps")
	
	' REMINDER: Don't cheat your wife! Remember to Hide this button!
	'btnOverrideSteps.Visible = True
	
	' Load target from central Map settings
	Dim m As Map = GetSettings
	dailyTarget = m.Get("target")

	' Force the daily target for testing
	SetDailyTarget(10000)

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
	' Load current steps from central Map settings
	Dim m As Map = GetSettings
	Dim stepsToday As Int = m.Get("steps_today")
	UpdateStepDisplay(stepsToday)
End Sub

'Called whenever a visible page disappear.
Private Sub B4XPage_Disappear

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

' Called from StepService or local UI refresh
Public Sub UpdateStepDisplay (steps As Int)
	lblSteps.Text = "Steps Today: " & NumberFormat(steps, 0, 0)
    
    ' Calculate progress percentage
    Dim progress As Float = steps / dailyTarget
    If progress > 1.0 Then progress = 1.0 ' Cap bar at 100%
    
    ' Update B4XProgressBar (Value ranges from 0 to 100 or 0.0 to 1.0 depending on properties)
	ProgressBar1.Progress = progress * 100
    
    ' Update target display label
    Dim pct As Int = Floor((steps / dailyTarget) * 100)
	lblTarget.Text = NumberFormat(steps, 0, 0) & " / " & NumberFormat(dailyTarget, 0, 0) & " steps (" & pct & "%)"
End Sub

Public Sub SetDailyTarget (newTarget As Int)
    dailyTarget = newTarget
	
	' Update target inside the Map and persist
	Dim m As Map = GetSettings
	m.Put("target", newTarget)
	SaveSettings(m)

    If lblDailyTarget.IsInitialized Then
        lblDailyTarget.Text = "Daily target " & NumberFormat(newTarget, 0, 0) & " steps"
    End If
    
	Dim stepsToday As Int = m.Get("steps_today")
    UpdateStepDisplay(stepsToday)
End Sub

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

' Load or initialize settings Map
Private Sub GetSettings As Map
	Return kvs.GetDefault("app_settings", CreateMap("target": 10000, "notified_date": "", "day_start": -1, "last_date": ""))
End Sub

Private Sub SaveSettings (m As Map)
	kvs.Put("app_settings", m)
End Sub

' Set today's steps to 5 steps less than dailyTarget to test the goal notification
Private Sub btnOverrideSteps_Click
	CallSub2(StepService, "OverrideStepsToday", dailyTarget - 5)
End Sub

Private Sub btnShowReport_Click
	ShowStepReport
End Sub

' Generates and displays weekly and monthly step performance
Private Sub ShowStepReport
	Dim weeklyStats As Map = GetHistoryStats(7)
	Dim monthlyStats As Map = GetHistoryStats(30)
    
	Dim sb As StringBuilder
	sb.Initialize
    
	sb.Append("📊 7-DAY SUMMARY (WEEKLY)").Append(CRLF)
	sb.Append("• Total Steps: ").Append(NumberFormat(weeklyStats.Get("total"), 0, 0)).Append(CRLF)
	sb.Append("• Daily Average: ").Append(NumberFormat(weeklyStats.Get("avg"), 0, 0)).Append(CRLF)
	sb.Append("• Peak Day: ").Append(NumberFormat(weeklyStats.Get("max"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Days Logged: ").Append(weeklyStats.Get("days")).Append(" / 7").Append(CRLF).Append(CRLF)
    
	sb.Append("📅 30-DAY SUMMARY (MONTHLY)").Append(CRLF)
	sb.Append("• Total Steps: ").Append(NumberFormat(monthlyStats.Get("total"), 0, 0)).Append(CRLF)
	sb.Append("• Daily Average: ").Append(NumberFormat(monthlyStats.Get("avg"), 0, 0)).Append(CRLF)
	sb.Append("• Peak Day: ").Append(NumberFormat(monthlyStats.Get("max"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Days Logged: ").Append(monthlyStats.Get("days")).Append(" / 30")
    
	xui.MsgboxAsync(sb.ToString, "Activity History & Performance")
End Sub

' Returns a Map with summary stats for the last N days
Public Sub GetHistoryStats (daysCount As Int) As Map
	Dim history As Map = kvs.GetDefault("step_history", CreateMap())
	Dim totalSteps As Long = 0
	Dim daysLogged As Int = 0
	Dim maxSteps As Int = 0
    
	Dim todayStr As String = DateTime.Date(DateTime.Now)
	Dim m As Map = GetSettings
	Dim currentTodaySteps As Int = m.GetDefault("steps_today", 0)
    
	Dim pd As Period
	For i = 0 To daysCount - 1
		pd.Days = -i
		Dim targetDate As String = DateTime.Date(DateUtils.AddPeriod(DateTime.Now, pd))
        
		Dim count As Int = 0
		If targetDate = todayStr Then
			count = currentTodaySteps
		Else If history.ContainsKey(targetDate) Then
			count = history.Get(targetDate)
		End If
        
		If count > 0 Or history.ContainsKey(targetDate) Or targetDate = todayStr Then
			totalSteps = totalSteps + count
			daysLogged = daysLogged + 1
			If count > maxSteps Then maxSteps = count
		End If
	Next
    
	Dim avgSteps As Int = 0
	If daysLogged > 0 Then avgSteps = totalSteps / daysLogged
    
	Return CreateMap("total": totalSteps, "avg": avgSteps, "max": maxSteps, "days": daysLogged)
End Sub

Public Sub DrawWeeklyChart (pnlChart As B4XView)
	Dim cvsChart As B4XCanvas
	cvsChart.Initialize(pnlChart)
	cvsChart.ClearRect(cvsChart.TargetRect)
    
	Dim history As Map = kvs.GetDefault("step_history", CreateMap())
	Dim barWidth As Float = (pnlChart.Width - 40dip) / 7
	Dim maxHeight As Float = pnlChart.Height - 30dip
    
	Dim pd As Period
	For i = 6 To 0 Step -1
		pd.Days = -i
		Dim tickDate As String = DateTime.Date(DateUtils.AddPeriod(DateTime.Now, pd))
		Dim daySteps As Int = history.GetDefault(tickDate, 0)
        
		' If checking today, grab current active session steps
		If tickDate = DateTime.Date(DateTime.Now) Then
			Dim m As Map = kvs.GetDefault("app_settings", CreateMap())
			daySteps = m.GetDefault("steps_today", 0)
		End If
        
		' Calculate Bar Height relative to target
		Dim barHeight As Float = (daySteps / (dailyTarget * 1.2)) * maxHeight
		If barHeight > maxHeight Then barHeight = maxHeight
        
		Dim x As Float = 20dip + (6 - i) * barWidth
		Dim y As Float = pnlChart.Height - 20dip - barHeight
        
		' Bar color: Green if target met, Blue if under
		Dim barColor As Int = xui.Color_RGB(56, 184, 255)
		If daySteps >= dailyTarget Then barColor = xui.Color_RGB(76, 175, 80)
        
		' Draw Bar
		cvsChart.DrawLine(x + barWidth / 2, pnlChart.Height - 20dip, x + barWidth / 2, y, barColor, barWidth - 6dip)
	Next
    
	cvsChart.Invalidate
End Sub