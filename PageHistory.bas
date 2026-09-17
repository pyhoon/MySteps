B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=14
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private kvs As KeyValueStore
	Private lblStats As B4XView
	Private pnlChart As B4XView
End Sub

Public Sub Initialize
End Sub

' Runs once when page is first initialized
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("PageHistory") ' Load layout containing lblStats and pnlChart
	B4XPages.SetTitle(Me, "Step History & Reports")
    
	kvs.Initialize(xui.DefaultFolder, "step_data.dat")
End Sub

' Runs every time the user navigates to this page
Private Sub B4XPage_Appear
	RenderHistoryView
End Sub

Private Sub GetSettings As Map
	Return kvs.GetDefault("app_settings", CreateMap("target": 10000, "notified_date": "", "day_start": -1, "last_date": ""))
End Sub

Public Sub RenderHistoryView
	' 1. Fetch statistics
	Dim weeklyStats As Map = GetHistoryStats(7)
	Dim monthlyStats As Map = GetHistoryStats(30)
    
	' 2. Update summary text
	Dim sb As StringBuilder
	sb.Initialize
	
	' 7-Day Summary
	sb.Append("📊 7-DAY SUMMARY").Append(CRLF)
	sb.Append("• Total: ").Append(NumberFormat(weeklyStats.Get("total"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Daily Avg: ").Append(NumberFormat(weeklyStats.Get("avg"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Peak Day: ").Append(NumberFormat(weeklyStats.Get("max"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Days Logged: ").Append(weeklyStats.Get("days")).Append(" / 7").Append(CRLF).Append(CRLF)
    
	' 30-Day Summary
	sb.Append("📅 30-DAY SUMMARY").Append(CRLF)
	sb.Append("• Total: ").Append(NumberFormat(monthlyStats.Get("total"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Daily Avg: ").Append(NumberFormat(monthlyStats.Get("avg"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Peak Day: ").Append(NumberFormat(monthlyStats.Get("max"), 0, 0)).Append(" steps").Append(CRLF)
	sb.Append("• Days Logged: ").Append(monthlyStats.Get("days")).Append(" / 30")
    
	lblStats.Text = sb.ToString
    
	' 3. Draw chart on layout panel
	DrawWeeklyChart(pnlChart, B4XPages.MainPage.dailyTarget)
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

'Public Sub DrawWeeklyChart
'	Dim cvsChart As B4XCanvas
'	cvsChart.Initialize(pnlChart)
'	cvsChart.ClearRect(cvsChart.TargetRect)
'    
'	Dim rectChart As B4XRect
'	rectChart.Initialize(0, 0, pnlChart.Width, pnlChart.Height)
'	cvsChart.DrawRect(rectChart, xui.Color_RGB(220, 220, 220), True, 0) ' Solid White/Light Fill
'	cvsChart.DrawRect(rectChart, xui.Color_RGB(180, 180, 180), False, 2dip) ' 2dip Border Outline
'	
'	Dim history As Map = kvs.GetDefault("step_history", CreateMap())
'	Dim barWidth As Float = (pnlChart.Width - 40dip) / 7
'	Dim maxHeight As Float = pnlChart.Height - 30dip
'    
'	Dim pd As Period
'	For i = 6 To 0 Step -1
'		pd.Days = -i
'		Dim tickDate As String = DateTime.Date(DateUtils.AddPeriod(DateTime.Now, pd))
'		Dim daySteps As Int = history.GetDefault(tickDate, 0)
'        
'		' If checking today, grab current active session steps
'		If tickDate = DateTime.Date(DateTime.Now) Then
'			Dim m As Map = kvs.GetDefault("app_settings", CreateMap())
'			daySteps = m.GetDefault("steps_today", 0)
'		End If
'        
'		Dim mainPage As B4XMainPage = B4XPages.MainPage
'		Dim dailyTarget As Int = mainPage.dailyTarget
'		
'		' Calculate Bar Height relative to target
'		Dim barHeight As Float = (daySteps / (dailyTarget * 1.2)) * maxHeight
'		If barHeight > maxHeight Then barHeight = maxHeight
'        
'		Dim x As Float = 20dip + (6 - i) * barWidth
'		Dim y As Float = pnlChart.Height - 20dip - barHeight
'        
'		' Bar color: Green if target met, Blue if under
'		Dim barColor As Int = xui.Color_RGB(56, 184, 255)
'		If daySteps >= dailyTarget Then barColor = xui.Color_RGB(76, 175, 80)
'        
'		' Draw Bar
'		cvsChart.DrawLine(x + barWidth / 2, pnlChart.Height - 20dip, x + barWidth / 2, y, barColor, barWidth - 6dip)
'	Next
'    
'	cvsChart.Invalidate
'End Sub

'Public Sub DrawWeeklyChart
'    Dim cvsChart As B4XCanvas
'	cvsChart.Initialize(pnlChart)
'    cvsChart.ClearRect(cvsChart.TargetRect)
'    
'    ' 1. Draw Optional Background & Border
'    Dim rectChart As B4XRect
'	rectChart.Initialize(0, 0, pnlChart.Width, pnlChart.Height)
'    cvsChart.DrawRect(rectChart, xui.Color_RGB(250, 250, 250), True, 0)
'    cvsChart.DrawRect(rectChart, xui.Color_RGB(220, 220, 220), False, 1dip)
'    
'    Dim history As Map = kvs.GetDefault("step_history", CreateMap())
'    
'    ' Dimensions and Layout Padding
'    Dim topPadding As Float = 25dip    ' Space for step count text above bars
'    Dim bottomPadding As Float = 35dip ' Space for date text below bars
'	Dim barWidth As Float = (pnlChart.Width - 30dip) / 7
'	Dim maxHeight As Float = pnlChart.Height - topPadding - bottomPadding
'	Dim baselineY As Float = pnlChart.Height - bottomPadding
'    
'    ' Fonts for Chart Text
'    Dim fntLabel As B4XFont = xui.CreateDefaultFont(10)
'    Dim fntValue As B4XFont = xui.CreateDefaultBoldFont(10)
'    
'    ' Save current DateFormat and temporarily switch to dd/MM
'    Dim originalDateFormat As String = DateTime.DateFormat
'    DateTime.DateFormat = "dd/MM"
'    
'	Dim mainPage As B4XMainPage = B4XPages.MainPage
'	Dim dailyTarget As Int = mainPage.dailyTarget
'	
'    Dim pd As Period
'    For i = 6 To 0 Step -1
'        pd.Days = -i
'        
'        ' Format Date for Label (dd/MM)
'        Dim dateLabel As String = DateTime.Date(DateUtils.AddPeriod(DateTime.Now, pd))
'        Dim tickDate As String = DateTime.Date(DateUtils.AddPeriod(DateTime.Now, pd)) ' Standard lookup date
'        
'        Dim daySteps As Int = history.GetDefault(tickDate, 0)
'        
'        ' Check if day is today to read live session steps
'        If i = 0 Then
'            Dim m As Map = GetSettings
'            daySteps = m.GetDefault("steps_today", 0)
'        End If
'        
'        ' Calculate Bar Height relative to target
'        Dim barHeight As Float = (daySteps / (dailyTarget * 1.2)) * maxHeight
'        If barHeight > maxHeight Then barHeight = maxHeight
'        If barHeight < 4dip And daySteps > 0 Then barHeight = 4dip ' Minimum bar visibility
'        
'        Dim centerX As Float = 15dip + (6 - i) * barWidth + (barWidth / 2)
'        Dim topY As Float = baselineY - barHeight
'        
'        ' Bar Color Logic (Green if target met, Blue if under)
'        Dim barColor As Int = xui.Color_RGB(56, 184, 255)
'        If daySteps >= dailyTarget Then barColor = xui.Color_RGB(76, 175, 80)
'        
'        ' Draw Bar Line
'        If daySteps > 0 Then
'            cvsChart.DrawLine(centerX, baselineY, centerX, topY, barColor, barWidth - 8dip)
'        End If
'        
'        ' 2. Draw Date Text Below Bar
'		cvsChart.DrawText(dateLabel, centerX, pnlChart.Height - 12dip, fntLabel, xui.Color_RGB(100, 100, 100), "CENTER")
'        
'        ' 3. Draw Total Steps Count Above Bar (Only if steps > 0)
'        If daySteps > 0 Then
'            Dim stepText As String
'            If daySteps >= 10000 Then
'                stepText = NumberFormat(daySteps / 1000, 0, 1) & "k" ' Compact format (e.g. 10.5k)
'            Else
'                stepText = NumberFormat(daySteps, 0, 0)
'            End If
'            
'            cvsChart.DrawText(stepText, centerX, topY - 5dip, fntValue, xui.Color_RGB(50, 50, 50), "CENTER")
'        End If
'    Next
'    
'    ' Restore original DateFormat
'    DateTime.DateFormat = originalDateFormat
'    
'    cvsChart.Invalidate
'End Sub

Public Sub DrawWeeklyChart (pnlCanvas As B4XView, dailyTarget As Int)
	Dim cvsChart As B4XCanvas
	cvsChart.Initialize(pnlCanvas)
	cvsChart.ClearRect(cvsChart.TargetRect)
    
	' 1. Draw Background & Border
	Dim rectChart As B4XRect
	rectChart.Initialize(0, 0, pnlCanvas.Width, pnlCanvas.Height)
	cvsChart.DrawRect(rectChart, xui.Color_RGB(250, 250, 250), True, 0)
	cvsChart.DrawRect(rectChart, xui.Color_RGB(220, 220, 220), False, 1dip)
    
	Dim history As Map = kvs.GetDefault("step_history", CreateMap())
    
	' Layout Padding
	Dim topPadding As Float = 25dip    ' Space for step count text above bars
	Dim bottomPadding As Float = 48dip ' Expanded space for two-line bottom text
	Dim barWidth As Float = (pnlCanvas.Width - 30dip) / 7
	Dim maxHeight As Float = pnlCanvas.Height - topPadding - bottomPadding
	Dim baselineY As Float = pnlCanvas.Height - bottomPadding
    
	' Chart Fonts
	Dim fntLabel As B4XFont = xui.CreateDefaultFont(9)
	Dim fntDayLabel As B4XFont = xui.CreateDefaultBoldFont(9)
	Dim fntValue As B4XFont = xui.CreateDefaultBoldFont(10)
    
	' Day Names Lookup Array (1 = Sunday, 7 = Saturday)
	Dim dayNames() As String = Array As String("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
    
	' Temporary Date Format
	Dim originalDateFormat As String = DateTime.DateFormat
	DateTime.DateFormat = "dd/MM"
    
	Dim pd As Period
	For i = 6 To 0 Step -1
		pd.Days = -i
        
		Dim targetTicks As Long = DateUtils.AddPeriod(DateTime.Now, pd)
		Dim dateLabel As String = DateTime.Date(targetTicks)
		Dim tickDate As String = DateTime.Date(targetTicks)
        
		' Determine Day of Week & Weekend Status
		Dim dayOfWeek As Int = DateTime.GetDayOfWeek(targetTicks) ' 1 = Sun, 7 = Sat
		Dim dayName As String = dayNames(dayOfWeek - 1)
		Dim isWeekend As Boolean = (dayOfWeek = 1 Or dayOfWeek = 7)
        
		Dim daySteps As Int = history.GetDefault(tickDate, 0)
        
		' Fetch live steps if day is today
		If i = 0 Then
			Dim m As Map = GetSettings
			daySteps = m.GetDefault("steps_today", 0)
		End If
        
		' Calculate Bar Height
		Dim barHeight As Float = (daySteps / (dailyTarget * 1.2)) * maxHeight
		If barHeight > maxHeight Then barHeight = maxHeight
		If barHeight < 4dip And daySteps > 0 Then barHeight = 4dip
        
		Dim centerX As Float = 15dip + (6 - i) * barWidth + (barWidth / 2)
		Dim topY As Float = baselineY - barHeight
        
		' Bar Color (Green = Target Met, Blue = Target Pending)
		Dim barColor As Int = xui.Color_RGB(56, 184, 255)
		If daySteps >= dailyTarget Then barColor = xui.Color_RGB(76, 175, 80)
        
		' Draw Step Bar
		If daySteps > 0 Then
			cvsChart.DrawLine(centerX, baselineY, centerX, topY, barColor, barWidth - 8dip)
		End If
        
		' Text Color: Red for Weekends, Gray for Weekdays
		Dim labelColor As Int
		If isWeekend Then
			labelColor = xui.Color_RGB(239, 68, 68) ' Red
		Else
			labelColor = xui.Color_RGB(100, 100, 100) ' Slate Gray
		End If
        
		' 2. Draw Date (dd/MM)
		cvsChart.DrawText(dateLabel, centerX, pnlCanvas.Height - 26dip, fntLabel, labelColor, "CENTER")
        
		' 3. Draw Day Name (e.g. Sat / Sun / Mon)
		cvsChart.DrawText(dayName, centerX, pnlCanvas.Height - 10dip, fntDayLabel, labelColor, "CENTER")
        
		' 4. Draw Step Count Above Bar
		If daySteps > 0 Then
			Dim stepText As String
			If daySteps >= 10000 Then
				stepText = NumberFormat(daySteps / 1000, 0, 1) & "k"
			Else
				stepText = NumberFormat(daySteps, 0, 0)
			End If
            
			cvsChart.DrawText(stepText, centerX, topY - 5dip, fntValue, xui.Color_RGB(50, 50, 50), "CENTER")
		End If
	Next
    
	DateTime.DateFormat = originalDateFormat
	cvsChart.Invalidate
End Sub