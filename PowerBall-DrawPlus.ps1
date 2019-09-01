#Author: Carlos Martinez  GitHub @cmartinezone

#Power Ball Lottery Number Generator 
#The numbers randomly choosen are picked in base of the high (hots) numbers played since the last powerball rule changed on 2015

########################################## SETTINGS VARIABLES ############################################
#Today Date
$TodayDate = Get-Date -Format  "MM-dd-yyyy"
#Next Draw Date
$NextDrawdate = Get-Date
while ($NextDrawdate.DayOfWeek -notin 'Wednesday', 'Saturday') { $NextDrawdate = $NextDrawdate.AddDays(1) }
$NextDrawdate = $NextDrawdate.ToString('MM-dd-yyyy')

#Local Data files path
$LocalDataSetsPath = ".\Datasets"
$LocalPickedNumbersPath = ".\PickedNumbers"
$LocalWebData = "$LocalDataSetsPath\WebData.csv"
$LocalAllWhiteBalls = "$LocalDataSetsPath\AllFrom1To5.csv"
$LocalAllRedBalls = "$LocalDataSetsPath\AllRedBall.csv"
$WhiteBallsDaysStadistic = "$LocalDataSetsPath\WhiteBallsDaysStadistic.csv"
$RedBallsDaysStadistic = "$LocalDataSetsPath\RedBallsDaysStadistic.csv"
$LocalHistoryResults = "$LocalDataSetsPath\HistoryResults.csv"
$VerifyLocalDataSets = Test-Path -Path  $LocalDataSetsPath , $LocalWebData, $LocalHistoryResults, $LocalAllWhiteBalls, $LocalAllRedBalls, $WhiteBallsDaysStadistic, $RedBallsDaysStadistic

#Nuber of days for refreshing data sets equal or grether then 
$RefreshDayNumber = 4
########################################## END SETTINGS VARIABLES ############################################

##########################################! MEAN, MEDIAN, MODE FUNCTION ###################################!
function Get-Mean {
    param(
        # The numbers to average
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]
        $Number
    )
    
    begin {
        $numberSeries = @()
    }
    
    process {
        $numberSeries += $number
    }
    
    end {
        ($numberSeries | Measure-Object -Average).Average
    }
} 
function Get-Median {
    param(
        # The numbers to average
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]
        $Number
    )
    
    begin {
        $numberSeries = @()
    }
    
    process {
        $numberSeries += $number
    }
    
    end {
        $sortedNumbers = @($numberSeries | Sort-Object)
        if ($numberSeries.Count % 2) {
            # Odd, pick the middle
            $sortedNumbers[($sortedNumbers.Count / 2) - 1]
        }
        else {
            # Even, average the middle two
            ($sortedNumbers[($sortedNumbers.Count / 2)] + $sortedNumbers[($sortedNumbers.Count / 2) - 1]) / 2
        }                        
    }
} 
function Get-Mode {
    param(
        # The numbers to average
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]
        $Number
    )
    
    begin {
        $numberSeries = @()
    }
    
    process {
        $numberSeries += $number
    }
    
    end {
        $data = $numberSeries

        $i = 0
        $modevalue = @()
        foreach ($group in ($data | Group-Object | Sort-Object -Descending count)) {
            if ($group.count -ge $i) {
                $i = $group.count
                $modevalue += $group.Name
            }
            else {
                break
            }
        }

        $modevalue
       
    }
} 

#####################################! END: MEAN, MEDIAN, MODE FUNCTION ###################################!

#Function to Refresh local Datasets.

##################### TODO: REFRESH LOCAL DATA FUNCTION #######################
function Get-RefreshLocalDataSets ($Date) {
    

    if ( $false -notin $VerifyLocalDataSets ) {    
        $LastUpdateDate = Import-Csv  $LocalWebData | Select-Object -Property DATE -First 1  
       
        #Get the total of days of the last draw date. 
        $LastUpdate = New-TimeSpan -Start $LastUpdateDate.DATE -End $TodayDate | Select-Object -Property TotalDays    
    }
    else {
        #Create directory for datasets
        New-Item -ItemType Directory -Force -Path $LocalDataSetsPath | Out-Null     
    }
    
    #Refresh Datasets if the date of the last Draw is equal or greather then the number of days set.
    if ( ( $false -in $VerifyLocalDataSets ) -or ( $LastUpdate.TotalDays -gt $RefreshDayNumber )) {
    
        try {
            #PowerBall Lottery API Get Request From data.ny.gov public API 10 years records.
            $Url = "https://data.ny.gov/resource/d6yy-54nr.json"
            $OnlineData = Invoke-RestMethod -Method 'Get' -Uri $Url  -ErrorAction Stop 
            $APIOnline = $true
        }
        catch {
            $APIOnline = $false
            if ($false -notin $VerifyLocalDataSets) {
                Write-Host "Status: API Ofline - Unable to Refresh Local Data Sets"  -ForegroundColor Red
                Write-Host "You Will continue using the Current Local Data Sets" -ForegroundColor Green
            }
            else {
                Write-Host "Status: API Ofline - Unable to Create Local Data Sets"  -ForegroundColor Red
            }    
        }
        
        if ($true -eq $APIOnline) {
            
            #EXPORT: Parsin Data from API Response to CSV and Adding commas to API Response. 
            $Progress = 0
            $RulesChanged = "10-07-2015"
            $RulesChanged = [datetime]$RulesChanged
            $RulesChanged = $RulesChanged.ToString()
            $WiningNumbersToCSV = $OnlineData | ForEach-Object { $Date = [datetime]$_.draw_date ; $Date = $Date.ToString('MM-dd-yyyy'); 
                Write-Progress -Activity 'Parsing Data From API:' -Status "Creating Local Dataset..." -PercentComplete (($Progress / $OnlineData.Count) * 100)  
                if ((Get-Date $Date ) -ge (Get-Date $RulesChanged)) { Write-Output  (($_.winning_numbers -replace (" ", ",")) + "," + $Date) }; $Progress ++ }
            $CSVHeaders = "N1,N2,N3,N4,N5,RB,DATE" 
            Write-Output  $CSVHeaders | Out-File    $LocalWebData  -Force
            $WiningNumbersToCSV | Add-Content $LocalWebData  -Force 
        
            #History Results to CSV without spaces 
            $HistoryResults = $OnlineData | ForEach-Object { Write-Output  ($_.winning_numbers -replace (" ", "")) }
            Write-Output "All" | Out-File    $LocalHistoryResults -Force
            $HistoryResults | Add-Content $LocalHistoryResults -Force
         
            #IMPORT: Data from local Webdata.CSV to create one object with the wining number from N1 TO N5 (White Balls)
            $AllWebDataFromCSV = Import-Csv  $LocalWebData
            #Selecting the all the number in position 1 to 5 (White Balls)
            $NFrom1To5 = $AllWebDataFromCSV | Select-Object -Property N1, N2, N3, N4, N5, DATE 
            #Adding all the numbers from position 1 to 5 (White Balls) in one object 
            $AllFrom1To5 = $NFrom1To5 | ForEach-Object { 
                Write-Output ( $_.N1 + "," + $_.DATE);
                Write-Output ( $_.N2 + "," + $_.DATE); 
                Write-Output ( $_.N3 + "," + $_.DATE);
                Write-Output ( $_.N4 + "," + $_.DATE);
                Write-Output ( $_.N5 + "," + $_.DATE); } 
    
            #Creating CSV File with all the numbers from the position 1 to 5 (White Balls)
            Write-Output "All,DATE" | Out-File    $LocalAllWhiteBalls -Force
            $AllFrom1To5 | Add-Content $LocalAllWhiteBalls -Force

            #Selecting All Red Ball numbers (PowerBall) with Date included
            #Creating CSV File with all the Red Ball numbers (Power Ball) with Date inlcuded 
            $AllRedBall = $AllWebDataFromCSV | Select-Object -Property RB, DATE
            $AllRedBall = $AllRedBall | ForEach-Object { Write-Output ( $_.RB + "," + $_.DATE) } 
            Write-Output "RB,DATE" | Out-File    $LocalAllRedBalls -Force
            $AllRedBall | Add-Content $LocalAllRedBalls -Force

            #Calculate White Balls and Save Local, number, totalplay  Mean, Media, Moda, lastdate  
            $WhiteBalls = Import-Csv $LocalAllWhiteBalls 
            $WhiteBallsRange = (1..69)
            Write-Output "NUMBER,TOTALPLAY,MEAN,MEDIAN,MODE,LASTDATE,TOTALDAYS" | Out-File $WhiteBallsDaysStadistic
            $WhiteBallsRange = $WhiteBallsRange | ForEach-Object { if ($_ -le 9) { $_ = ("0" + $_) }; Write-Output $_ } 
           
            foreach ( $WhiteBallNumber in $WhiteBallsRange) {
                $AllFound = $WhiteBalls | Where-Object { $_.ALL -eq $WhiteBallNumber }
                $AllFound = $AllFound | Sort-Object { $_.DATE -as [datetime] }
                
                $GetNumberOfDays = @()
                $ProgressBarText = "Calculating: Mean, Median and Mode between number of days for WhiteBalls... N:"
                $StartDateIndex = 0 ; $EndDateIndex = 1
                
                do {
                    $TotalDays = New-TimeSpan -Start $AllFound[$StartDateIndex].DATE -End  $AllFound[$EndDateIndex].DATE | Select-Object -Property TotalDays 
                    Write-Progress -Activity "$ProgressBarText $WhiteBallNumber" -Status ("From: " + $AllFound[$StartDateIndex].DATE + " To " + $AllFound[$EndDateIndex].DATE + " Total days: " + $TotalDays.TotalDays) -PercentComplete (( $WhiteBallNumber / 69 ) * 100) 
                  
                    $GetNumberOfDays += $TotalDays                
                    $StartDateIndex ++ ; $EndDateIndex ++
                } until ($null -eq $AllFound[$EndDateIndex].DATE)
             
                $Median = Get-Median $GetNumberOfDays.TotalDays
                $Mode = Get-Mode $GetNumberOfDays.TotalDays
                $Mean = Get-Mean $GetNumberOfDays.TotalDays

                $LastPlayed = $AllFound | Select-Object -Last 1
                $ToTaldays = New-TimeSpan -Start $LastPlayed.DATE -End $NextDrawdate | Select-Object -Property TotalDays 

                Write-Output ("$WhiteBallNumber," + $AllFound.count + "," + [int]$Mean + "," + [int]$Median + "," + $Mode + "," + $LastPlayed.DATE + "," + $TotalDays.TotalDays) | Add-Content $WhiteBallsDaysStadistic -Force
            }

            #Calculate Red Balls and Save Local, number, totalplay  Mean, Media, Moda, lastdate  
            $RedBalls = Import-Csv $LocalAllRedBalls
            $RedBallsRange = (1..26)
            Write-Output "NUMBER,TOTALPLAY,MEAN,MEDIAN,MODE,LASTDATE,TOTALDAYS" | Out-File $RedBallsDaysStadistic
            $RedBallsRange = $RedBallsRange | ForEach-Object { if ($_ -le 9) { $_ = ("0" + $_) }; Write-Output $_ } 

            foreach ( $RedBallNumber in  $RedBallsRange ) {

                $AllFound = $RedBalls | Where-Object { $_.RB -eq $RedBallNumber }
                $AllFound = $AllFound | Sort-Object { $_.DATE -as [datetime] }
                 
                $GetNumberOfDays = @()
                $ProgressBarText = "Calculating: Mean, Median and Mode between number of days for RedBalls... N:"
                $StartDateIndex = 0 ; $EndDateIndex = 1
                 
                do {
                    $TotalDays = New-TimeSpan -Start $AllFound[$StartDateIndex].DATE -End  $AllFound[$EndDateIndex].DATE | Select-Object -Property TotalDays 
                    Write-Progress -Activity "$ProgressBarText $RedBallNumber" -Status ("From: " + $AllFound[$StartDateIndex].DATE + " To " + $AllFound[$EndDateIndex].DATE + " Total days: " + $TotalDays.TotalDays) -PercentComplete (( $RedBallNumber / 26 ) * 100) 
                    $GetNumberOfDays += $TotalDays                
                    $StartDateIndex ++ ; $EndDateIndex ++
                } until ($null -eq $AllFound[$EndDateIndex].DATE)

                $Median = Get-Median $GetNumberOfDays.TotalDays
                $Mode = Get-Mode   $GetNumberOfDays.TotalDays
                $Mean = Get-Mean   $GetNumberOfDays.TotalDays

                $LastPlayed = $AllFound | Select-Object -Last 1
                $ToTaldays = New-TimeSpan -Start $LastPlayed.DATE -End $NextDrawdate | Select-Object -Property TotalDays 

                Write-Output ("$RedBallNumber," + $AllFound.count + "," + [int]$Mean + "," + [int]$Median + "," + $Mode + "," + $LastPlayed.DATE + "," + $TotalDays.TotalDays) | Add-Content $RedBallsDaysStadistic -Force
            }
            Write-Host "Local DataSets Successfully Refreshed" -ForegroundColor Green
        }
    }
}
################### TODO: END REFRESH LOCAL DATA FUNCTION #####################

#Refresh Local Data
Get-RefreshLocalDataSets($TodayDate)
  
if ( $false -notin $VerifyLocalDataSets) {
    
    #Importing Data From CSV as Objects 
    $AllFrom1To5 = Import-Csv  $WhiteBallsDaysStadistic
    $AllRedBall = Import-Csv  $RedBallsDaysStadistic

    ########################## TODO: DRAWWING  FUNCTION ###########################    
    function DrawWiningNumbers {
        #Object to storage number in position 1 to 5 (White Ball)
        $WiningNumbers = @()

        #Generating White Balls randomly 
        while ( $WiningNumbers.Count -lt 5 ) {

            do {
                $DrawNumber = (Get-Random -Minimum 01 -Maximum 69) #Get Random number between 1 to 69
        
                #Adding Zero if the number is less then or equal 9
                if ($DrawNumber -le 9) {
                    $DrawNumber = "0" + $DrawNumber
                }
        
                #Search for how many times the random number has been played since last powerball game rules changed
                #Organize the object item from older to newer
                $TotalFound = $AllFrom1To5 | Where-Object { $_.NUMBER -eq "$DrawNumber" } 
                #Create Mode object
                $ModeNumbers = $TotalFound.MODE | ConvertFrom-String -Delimiter " "
                $ModeNumbers = $ModeNumbers.PSObject.Properties
                $ModeNumbers = $ModeNumbers.Value 

                $LastGame = New-TimeSpan -Start $TotalFound.LASTDATE -End  $NextDrawdate | Select-Object -Property TotalDays
                
                if (($TotalFound.TOTALPLAY -ge 25 ) -and ($LastGame.TotalDays -in $ModeNumbers -or $LastGame.TotalDays -gt $TotalFound.MEDIAN -or $LastGame.TotalDays -ge $TotalFound.MEAN )) {
                
                    $Compliance = $true
                }
                else
                { $Compliance = $false }

            } until ( ( $DrawNumber -notin $WiningNumbers ) -and ( $true -eq $Compliance ))
            $WiningNumbers += $DrawNumber
        }
  
        #Generating Red Ball (Power Ball) randomly 
        do {
            $RedBall = (Get-Random -Minimum 01 -Maximum 26)
     
            #Adding Zero if the number is less then or equal 9
            if ($RedBall -le 9) {
                $RedBall = "0" + $RedBall
            }
    
            #Search for how many times the random number has been played during the past 10 year of data
            $TotalRedBallFound = $AllRedBall | Where-Object { $_.NUMBER -eq "$RedBall" } 
            
            #Create Mode object
            $ModeNumbers = $TotalRedBallFound.MODE | ConvertFrom-String -Delimiter " "
            $ModeNumbers = $ModeNumbers.PSObject.Properties
            $ModeNumbers = $ModeNumbers.Value 

            $LastGame = New-TimeSpan -Start $TotalRedBallFound.LASTDATE -End  $NextDrawdate | Select-Object -Property TotalDays
      
            if (( $TotalRedBallFound.TOTALPLAY -ge 14 ) -and ($LastGame.TotalDays -in $ModeNumbers -or $LastGame.TotalDays -gt $TotalRedBallFound.MEDIAN -or $LastGame.TotalDays -ge $TotalRedBallFound.MEAN ) ) {
                
                $Compliance = $true 
            }
            else
            { $Compliance = $false }

        } until ( $true -eq $Compliance)

        #Number randomly generated for White Ball 
        $WiningNumbers = $WiningNumbers | Sort-Object

        #Print number with Green color the White balls and with Red the (Power Ball)
        Write-Host $WiningNumbers -ForegroundColor Green -NoNewline | Sort-Object 
        Write-Host ""$RedBall  -ForegroundColor Red 

        #Returning White Balls numbers + Red ball (Power Ball) (Spaces between numbers removed)
        return  $WiningNumbers + $RedBall
    }

    ########################## TODO: END DRAWWING  FUNCTION #######################

    #loading History results   
    $HistoryDataResults = Import-Csv $LocalHistoryResults | Select-Object -Property All
    $WebDateResults = Import-Csv $LocalWebData  

    ##################################### USER INTERACTION #######################################
    Clear-Host
    Write-Host "!!!Welcome To PowerBall Draw Plus!!!" -BackgroundColor  DarkMagenta
    #Write-Host "Type your username:" -ForegroundColor Yellow
    $UserName = Read-Host "What is your username pick any?:"
    
    if (Test-Path ".\PickedNumbers") {

        $PreveusDrew = Get-ChildItem -Path ".\PickedNumbers" -File *$UserName*     
    }
    
    if (  $null -ne $PreveusDrew -and $null -ne $UserName ) { 
        Write-Host "We have found Preveus Drew in your name" -ForegroundColor Green

        $GetResult = Read-Host "Do you wan to check your tickets YES=1 NO=2?"
       
    }

    if ($GetResult -match '\d' -and $GetResult -eq 1 ) {
        Write-Host "Feature in Progress no Ready yet!" -ForegroundColor Yellow
        # Get-ChildItem -Path ".\PickedNumbers" -File *$UserName* | Select-Object Name | Sort-Object
    }
    else {
        Write-Host "$ Let's Draw your Numbers $" -ForegroundColor Yellow
        $PickNumbers = Read-Host "How many Numbers ?" #Capture Input
    
        #If the input are numbers
        if ($PickNumbers -match '\d' ) {
            
            $SaveResults = @()
            $SaveResultsToCSV = @()
            #Get the total of number input by the user
            for ($i = 0; $i -lt $PickNumbers; $i++) {
           
                #Get number that it is not equal to any of the preveus wining number in the past 10 years
                do {            
                    #Temp variable for Random number without spaces between numbers
                    $FullNumber = $null 
                    $ForCsvitems = $null
                    $Getnumbers = DrawWiningNumbers #Get Random numbers function 
                    $Getnumbers | ForEach-Object { $FullNumber += "$_"; $ForCsvitems += "$_," }
                   
                    if ( $FullNumber -in $SaveResults ) {
                        $Duplicated = $true
                    }
                    else {
                        $Duplicated = $false
                    }

                    
                    $N1Compliance = $WebDateResults | Where-Object { ($Getnumbers[0] -eq $_.N1) -and ($Getnumbers[1] -eq $_.N2) }
                    $N2Compliance = $WebDateResults | Where-Object { ($Getnumbers[1] -eq $_.N2) -and ($Getnumbers[2] -eq $_.N3) }
                    $N3Compliance = $WebDateResults | Where-Object { ($Getnumbers[2] -eq $_.N3) -and ($Getnumbers[3] -eq $_.N4) }
                    $N4Compliance = $WebDateResults | Where-Object { ($Getnumbers[3] -eq $_.N4) -and ($Getnumbers[4] -eq $_.N5) }

                    if (($N1Compliance.count -ge 1  -or $N2Compliance.count -ge 1) -and ($N3Compliance.count -ge 1 -or $N4Compliance.count -ge 2) ) {
                        $Compliance = $true
                    }
                       
                   # Write-Host   $N1Compliance.count
                   # Write-Host   $N2Compliance.count
                   # Write-Host   $N3Compliance.count
                   # Write-Host   $N4Compliance.count

                    $SaveResults += $FullNumber
                    #Write-Host $FullNumber  -and ($Compliance -eq $true)
                } until ( ($FullNumber -notin $HistoryDataResults.All) -and ($false -eq  $Duplicated) -and ($true -eq $Compliance))
                $SaveResultsToCSV += $ForCsvitems
            }
            
            #Creating PickedNumbers.CSV for saving the picked numbers in the end of the execution
            if ( (Test-Path $LocalPickedNumbersPath) -eq $false ) {
    
                New-Item -ItemType Directory -Force -Path $LocalPickedNumbersPath | Out-Null     
            }
            Write-Output "N1,N2,N3,N4,N5,RB,DATE" | Out-File "$LocalPickedNumbersPath\Picked-$UserName-$TodayDate.csv" -Force
            $SaveResultsToCSV | ForEach-Object { Write-Output ($_ + $TodayDate) } | Out-File "$LocalPickedNumbersPath\Picked-$UserName-$TodayDate.csv" -Append -Force
        }
    }
    ##################################### END USER INTERACTION #######################################
}

