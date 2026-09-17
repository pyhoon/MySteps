B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=14
@EndOfDesignText@
#Region  Service Attributes
    #StartAtBoot: True
#End Region

Sub Process_Globals
	Private xui As XUI
    Private ps As PhoneSensors
    Private kvs As KeyValueStore
	Private smiley As Bitmap
	Private lastTotalSteps As Int = -1
    Private const NOTIFICATION_ID As Int = 1001
End Sub

Sub Service_Create
    ' Initialize KVS
    kvs.Initialize(xui.DefaultFolder, "step_data.dat")
	
	smiley = LoadBitmapResize(File.DirAssets, "smiley.png", 24dip, 24dip, False)
	
    ' TYPE_STEP_COUNTER = 19
    ps.Initialize(19)
End Sub

Sub Service_Start (StartingIntent As Intent)
    ' 1. Start Foreground Service with Persistent Notification (Required on modern Android)
	Dim nb As NB6 ' Requires NB6 or NotificationBuilder library
	nb.Initialize("default", Application.LabelName, "DEFAULT").AutoCancel(True).SmallIcon(smiley)
	'nb.Build("Title", "Content", "tag1", Me).Notify(4) 'It will be Main (or any other activity) instead of Me if called from a service.
	nb.Build("Hi Aeric", "Keep walking!", "tag1", Main).Notify(4)
	
    ' Set Service to Foreground
	Dim n As Notification = nb.Build("Step Counter", "Tracking steps in background...", "tag1", Main)
	Service.StartForeground(NOTIFICATION_ID, n)
	
    ' 2. Start Listening to Sensor
    If ps.StartListening("Sensor") = False Then
        Log("Step counter sensor not available on this device.")
    End If
    
    ' Ensure service stays alive
    Service.StopAutomaticForeground 
End Sub

Sub Service_Destroy
	ps.StopListening
End Sub

Private Sub Sensor_SensorChanged (Values() As Float)
	lastTotalSteps = Values(0) ' Store latest hardware sensor reading
    Dim todayDate As String = DateTime.Date(DateTime.Now)
    Dim m As Map = GetSettings
    
    Dim dayStart As Int = m.Get("day_start")
    Dim lastDate As String = m.Get("last_date")
    
    ' Reset on midnight or initial run
    If todayDate <> lastDate Or dayStart = -1 Then
		dayStart = lastTotalSteps
        m.Put("day_start", dayStart)
        m.Put("last_date", todayDate)
    End If
    
    ' Reset on device reboot
	If lastTotalSteps < dayStart Then
        dayStart = 0
        m.Put("day_start", dayStart)
    End If
    
	' Check for Daily Goal Achievement
	Dim target As Int = m.Get("target")
	Dim notifiedDate As String = m.Get("notified_date")
	
    ' Calculate & Save Steps
	Dim stepsToday As Int = lastTotalSteps - dayStart
    m.Put("steps_today", stepsToday)
    SaveSettings(m)
	
    If stepsToday >= target And notifiedDate <> todayDate Then
        m.Put("notified_date", todayDate)
        SaveSettings(m)
        ShowGoalNotification(target)
    End If
	
    ' Update UI if active
    CallSubUtils_UpdateUI(stepsToday)
End Sub

Private Sub ShowGoalNotification (target As Int)
	Dim nbGoal As NB6
	nbGoal.Initialize("goal_channel", "Goal Achievements", "HIGH").SmallIcon(smiley)
    
	Dim nGoal As Notification = nbGoal.Build( _
        "🎉 Goal Reached!", _
        "Congratulations! You hit your goal of " & target & " steps today!", _
        "goal_tag", _
        Main)
        
	nGoal.Notify(2001) ' Separate notification ID from foreground service
End Sub

Private Sub CallSubUtils_UpdateUI (steps As Int)
	If B4XPages.IsInitialized Then
		If B4XPages.GetManager.IsForeground Then
			CallSub2(B4XPages.MainPage, "UpdateStepDisplay", steps)
		End If
	End If
End Sub

' Load or initialize settings Map
Private Sub GetSettings As Map
	Return kvs.GetDefault("app_settings", CreateMap("target": 10000, "notified_date": "", "day_start": -1, "last_date": ""))
End Sub

Private Sub SaveSettings (m As Map)
	kvs.Put("app_settings", m)
End Sub

' Call this to manually override today's step count
Public Sub OverrideStepsToday (manualSteps As Int)
    If lastTotalSteps = -1 Then 
        Log("Sensor has not reported a reading yet.")
		ToastMessageShow("Sensor has not reported a reading yet.", False)
        Return
    End If
    
    Dim m As Map = GetSettings
	
	' 1. Calculate adjusted baseline
    Dim newDayStart As Int = lastTotalSteps - manualSteps
	lastTotalSteps = newDayStart
	Dim pd As Period : pd.Initialize
	pd.Days = -1
	Dim current As String = DateTime.Date(DateTime.Now)
	Dim yesterday As String = DateTime.Date(DateUtils.AddPeriod(DateTime.Now, pd))
    m.Put("day_start", newDayStart)
	m.Put("last_date", current)
	m.Put("notified_date", yesterday)
    m.Put("steps_today", manualSteps)
	
	' 2. Persist updated settings
    SaveSettings(m)
    
	' 3. Refresh UI
    CallSubUtils_UpdateUI(manualSteps)
End Sub