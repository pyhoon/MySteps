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
	Private btn7Days As B4XView
	Private btn30Days As B4XView
    
	Private currentDaysMode As Int = 7 ' Default to 7 days
End Sub

Public Sub Initialize
End Sub

' Runs once when page is first initialized
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("PageHistory") ' Load layout containing lblStats and pnlChart
	B4XPages.SetTitle(Me, "Step History & Reports")
	
	UpdateToggleUI
	
	kvs.Initialize(xui.DefaultFolder, "step_data.dat")
End Sub

' Runs every time the user navigates to this page
Private Sub B4XPage_Appear
	RenderHistoryView
End Sub

Private Sub btn7Days_Click
	currentDaysMode = 7
	UpdateToggleUI
	RenderHistoryView
End Sub

Private Sub btn30Days_Click
	currentDaysMode = 30
	UpdateToggleUI
	RenderHistoryView
End Sub

Private Sub UpdateToggleUI
	' Highlight active toggle button
	If currentDaysMode = 7 Then
		btn7Days.SetColorAndBorder(xui.Color_RGB(56, 184, 255), 0, 0, 8dip)
		btn7Days.TextColor = xui.Color_White
		btn30Days.SetColorAndBorder(xui.Color_RGB(230, 230, 230), 0, 0, 8dip)
		btn30Days.TextColor = xui.Color_RGB(80, 80, 80)
	Else
		btn30Days.SetColorAndBorder(xui.Color_RGB(56, 184, 255), 0, 0, 8dip)
		btn30Days.TextColor = xui.Color_White
		btn7Days.SetColorAndBorder(xui.Color_RGB(230, 230, 230), 0, 0, 8dip)
		btn7Days.TextColor = xui.Color_RGB(80, 80, 80)
	End If
End Sub

Private Sub GetSettings As Map
    Return kvs.GetDefault("app_settings", CreateMap("target": 10000, "notified_date": "", "day_start": -1, "last_date": "", "steps_today": 0))
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
    
	' 3. Draw chart on layout panel according to selected toggle mode
	DrawChart(pnlChart, currentDaysMode, B4XPages.MainPage.dailyTarget)
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

Public Sub DrawChart (pnlCanvas As B4XView, daysCount As Int, dailyTarget As Int)
	Dim cvsChart As B4XCanvas
	cvsChart.Initialize(pnlCanvas)
	cvsChart.ClearRect(cvsChart.TargetRect)
    
	' 1. Background & Border
	Dim rectChart As B4XRect
	rectChart.Initialize(0, 0, pnlCanvas.Width, pnlCanvas.Height)
	cvsChart.DrawRect(rectChart, xui.Color_RGB(250, 250, 250), True, 0)
	cvsChart.DrawRect(rectChart, xui.Color_RGB(220, 220, 220), False, 1dip)
    
	Dim history As Map = kvs.GetDefault("step_history", CreateMap())
    
	' Adjust bottom padding dynamically
	Dim topPadding As Float = 25dip
	Dim bottomPadding As Float = IIf(daysCount = 7, 48dip, 30dip)
	Dim sidePadding As Float = 12dip
	Dim barWidth As Float = (pnlCanvas.Width - (sidePadding * 2)) / daysCount
	Dim maxHeight As Float = pnlCanvas.Height - topPadding - bottomPadding
	Dim baselineY As Float = pnlCanvas.Height - bottomPadding
    
	' Fonts
	Dim fntLabel As B4XFont = xui.CreateDefaultFont(IIf(daysCount = 7, 9, 8))
	Dim fntDayLabel As B4XFont = xui.CreateDefaultBoldFont(9)
	Dim fntValue As B4XFont = xui.CreateDefaultBoldFont(IIf(daysCount = 7, 10, 8))
    
	Dim dayNames() As String = Array As String("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
    
	Dim originalDateFormat As String = DateTime.DateFormat
	DateTime.DateFormat = "dd/MM"
    
	' Scan for Peak Day step count (to highlight in 30-day mode)
	Dim maxStepInPeriod As Int = 0
	Dim pdScan As Period
	For k = daysCount - 1 To 0 Step -1
		pdScan.Days = -k
		Dim scanDate As String = DateTime.Date(DateUtils.AddPeriod(DateTime.Now, pdScan))
		Dim scanCount As Int = history.GetDefault(scanDate, 0)
		If k = 0 Then
			Dim mSettings As Map = GetSettings
			scanCount = mSettings.GetDefault("steps_today", 0)
		End If
		If scanCount > maxStepInPeriod Then maxStepInPeriod = scanCount
	Next
    
	Dim pd As Period
	For i = daysCount - 1 To 0 Step -1
		pd.Days = -i
        
		Dim targetTicks As Long = DateUtils.AddPeriod(DateTime.Now, pd)
		Dim dateLabel As String = DateTime.Date(targetTicks)
		Dim tickDate As String = DateTime.Date(targetTicks)
        
		Dim dayOfWeek As Int = DateTime.GetDayOfWeek(targetTicks) ' 1 = Sun, 7 = Sat
		Dim dayName As String = dayNames(dayOfWeek - 1)
		Dim isWeekend As Boolean = (dayOfWeek = 1 Or dayOfWeek = 7)
        
		Dim daySteps As Int = history.GetDefault(tickDate, 0)
		If i = 0 Then
			Dim m As Map = GetSettings
			daySteps = m.GetDefault("steps_today", 0)
		End If
        
		' Bar Height Calculation
		Dim barHeight As Float = (daySteps / (dailyTarget * 1.2)) * maxHeight
		If barHeight > maxHeight Then barHeight = maxHeight
		If barHeight < 3dip And daySteps > 0 Then barHeight = 3dip
        
		Dim centerX As Float = sidePadding + (daysCount - 1 - i) * barWidth + (barWidth / 2)
		Dim topY As Float = baselineY - barHeight
        
		' Bar Color (Green = Target Met, Blue = Pending)
		Dim barColor As Int = xui.Color_RGB(56, 184, 255)
		If daySteps >= dailyTarget Then barColor = xui.Color_RGB(76, 175, 80)
        
		' 2. Draw Step Bar
		If daySteps > 0 Then
			Dim strokeThickness As Float = Max(1dip, barWidth - IIf(daysCount = 7, 8dip, 2dip))
			cvsChart.DrawLine(centerX, baselineY, centerX, topY, barColor, strokeThickness)
		End If
        
		' Text Color (Red for Weekends)
		Dim labelColor As Int = IIf(isWeekend, xui.Color_RGB(239, 68, 68), xui.Color_RGB(100, 100, 100))
        
		' 3. Render Bottom Labels
		If daysCount = 7 Then
			' 7-Day Mode: Full details (dd/MM + Day Name + Red Weekend text)
			cvsChart.DrawText(dateLabel, centerX, pnlCanvas.Height - 26dip, fntLabel, labelColor, "CENTER")
			cvsChart.DrawText(dayName, centerX, pnlCanvas.Height - 10dip, fntDayLabel, labelColor, "CENTER")
		Else
			' 30-Day Mode: Print date every 6 days or today to prevent collision
			If i Mod 6 = 0 Or i = 0 Then
				cvsChart.DrawText(dateLabel, centerX, pnlCanvas.Height - 10dip, fntLabel, labelColor, "CENTER")
			End If
		End If
        
		' 4. Render Step Count Above Bar
		If daySteps > 0 Then
			Dim stepText As String = IIf(daySteps >= 1000, NumberFormat(daySteps / 1000, 0, 1) & "k", NumberFormat(daySteps, 0, 0))
            
			If daysCount = 7 Then
				' 7-Day Mode: Label all bars
				cvsChart.DrawText(stepText, centerX, topY - 4dip, fntValue, xui.Color_RGB(50, 50, 50), "CENTER")
			Else
				' 30-Day Mode: Label ONLY Peak Day and Today
				If (daySteps = maxStepInPeriod And maxStepInPeriod > 0) Or i = 0 Then
					cvsChart.DrawText(stepText, centerX, topY - 4dip, fntValue, xui.Color_RGB(50, 50, 50), "CENTER")
				End If
			End If
		End If
	Next
    
	DateTime.DateFormat = originalDateFormat
	cvsChart.Invalidate
End Sub