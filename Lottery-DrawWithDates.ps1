#Author: Carlos Martinez  GitHub @cmartinezone

#Power Ball Lottery Number Generator 
#The numbers randomly choosen are picked in base of the high (hots) numbers played during the past 10 years.

########################################## SETTINGS VARIABLES ############################################
#Today Date
$TodayDate = Get-Date -Format  "MM-dd-yyyy"

#Local Data files path
$LocalDataSetsPath = ".\Datasets"
$LocalPickedNumbersPath  = ".\PickedNumbers"
$LocalWebData = "$LocalDataSetsPath\WebData.csv"
$LocalAllWhiteBalls = "$LocalDataSetsPath\AllFrom1To5.csv"
$LocalAllRedBalls = "$LocalDataSetsPath\AllRedBall.csv"
$LocalHistoryResults = "$LocalDataSetsPath\HistoryResults.csv"
$VeryLocalDataSets = Test-Path -Path  $LocalDataSetsPath , $LocalWebData, $LocalHistoryResults, $LocalAllWhiteBalls, $LocalAllRedBalls

#Nuber of days for refreshing data sets equal or grether then 
$FreshDayNumber = 3

########################################## SETTINGS VARIABLES ############################################

#Function to Refresh local Datasets.

##################### REFRESH LOCAL DATA FUNCTION #######################
function Get-RefreshLocalDataSets ($Date) {
    

    if ( $false -notin $VeryLocalDataSets ) {    
        $LastUpdateDate = Import-Csv  $LocalWebData | Select-Object -Property DATE -First 1  
       
        #Get the total of days of the last draw date. 
        $LastUpdate = New-TimeSpan -Start $LastUpdateDate.DATE -End $TodayDate | Select-Object -Property TotalDays    
    }
    else {
        #Create directory for datasets
        New-Item -ItemType Directory -Force -Path $LocalDataSetsPath | Out-Null     
    }
    
    #Refresh Datasets if the date of the last Draw is equal or greather then the number of days set.
    if ( ( $false -in $VeryLocalDataSets ) -or ( $LastUpdate.TotalDays -ge $FreshDayNumber )) {
    
        try {
            #PowerBall Lottery API Get Request From data.ny.gov public API 10 years records.
            $UrlEncode = "aAB0AHQAcABzADoALwAvAGQAYQB0AGEALgBuAHkALgBnAG8AdgAvAHIAZQBzAG8AdQByAGMAZQAvAGQANgB5AHkALQA1ADQAbgByAC4AagBzAG8AbgA="
            $Url = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($UrlEncode))
            $OnlineData = Invoke-RestMethod -Method 'Get' -Uri $Url  -ErrorAction Stop 
            $APIOnline = $true
        }
        catch {
            $APIOnline = $false
            if ($false -notin $VeryLocalDataSets) {
                Write-Host "Status: API Ofline - Unable to Refresh Local Data Sets"  -ForegroundColor Red
                Write-Host "You Will continue using the Current Local Data Sets" -ForegroundColor Green
            }else{
                Write-Host "Status: API Ofline - Unable to Create Local Data Sets"  -ForegroundColor Red
            }    
        }
        
        if ($true -eq $APIOnline) {
            #EXPORT: Parsin Data from API Response to CSV and Adding commas to API Response. 
            $WiningNumbersToCSV = $OnlineData | ForEach-Object { $Date = [datetime]$_.draw_date ; $Date = $Date.ToString('MM-dd-yyyy'); 
                Write-Output  (($_.winning_numbers -replace (" ", ",")) + "," + $Date) }
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
            $AllFrom1To5 = $NFrom1To5 | ForEach-Object { Write-Output ( $_.N1 + "," + $_.DATE) } 
            $AllFrom1To5 += $NFrom1To5 | ForEach-Object { Write-Output ( $_.N2 + "," + $_.DATE) } 
            $AllFrom1To5 += $NFrom1To5 | ForEach-Object { Write-Output ( $_.N3 + "," + $_.DATE) } 
            $AllFrom1To5 += $NFrom1To5 | ForEach-Object { Write-Output ( $_.N4 + "," + $_.DATE) } 
            $AllFrom1To5 += $NFrom1To5 | ForEach-Object { Write-Output ( $_.N5 + "," + $_.DATE) } 

            #Creating CSV File with all the numbers from the position 1 to 5 (White Balls)
            Write-Output "All,DATE" | Out-File    $LocalAllWhiteBalls -Force
            $AllFrom1To5 | Add-Content $LocalAllWhiteBalls -Force

            #Selecting All Red Ball numbers (PowerBall) with Date included
            #Creating CSV File with all the Red Ball numbers (Power Ball) with Date inlcuded 
            $AllRedBall = $AllWebDataFromCSV | Select-Object -Property RB, DATE
            $AllRedBall = $AllRedBall | ForEach-Object { Write-Output ( $_.RB + "," + $_.DATE) } 
            Write-Output "RB,DATE" | Out-File    $LocalAllRedBalls -Force
            $AllRedBall | Add-Content $LocalAllRedBalls -Force
        }
    }
}
################### END REFRESH LOCAL DATA FUNCTION #####################

#function to Get the median.

##########################GET MEDIAN FUNCTION ##########################
function Get-Median
{
    param(
    # The numbers to average
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
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
        } else {
            # Even, average the middle two
            ($sortedNumbers[($sortedNumbers.Count / 2)] + $sortedNumbers[($sortedNumbers.Count / 2) - 1]) / 2
        }                        
    }
} 
########################## END MEDIAN FUNCTION ##########################

    #Refresh Local Data
    Get-RefreshLocalDataSets($TodayDate)
  
if ( $false -notin $VeryLocalDataSets) {
    
    #Importing Data From CSV as Objects 
    $AllFrom1To5 = Import-Csv  $LocalAllWhiteBalls | Select-Object -Property All, DATE
    $AllRedBall = Import-Csv  $LocalAllRedBalls | Select-Object -Property RB, DATE

    ########################## DRAWWING  FUNCTION ###########################
    
    #Function to Draw Random number with high drawing rate.
    # Also calculate the median of days that the number play.
    #Function For Drawing Random numbers

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
        
            #Search for how many times the random number has been played during the past 10 year of data
            #Organize the object item from older to newer
            $TotalFound = $AllFrom1To5 | Where-Object { $_.All -eq $DrawNumber } | Sort-Object { $_.DATE -as [datetime] }
            
            #Test: Write-Host $TotalFound.Count

            ############## Calculate media  Total of the number played, dates of the number played, number of days between dates
            #Number of day between today and last played date #
            
            $GetNumberOfDays = @()

            for ($i = 0; $i -lt $TotalFound.Count; $i++) {
                $Nextdate = $i + 1
                if ( $null -ne $TotalFound[$Nextdate].DATE) {
                    $GetNumberOfDays += New-TimeSpan -Start $TotalFound[$i].DATE -End  $TotalFound[$Nextdate].DATE | Select-Object -Property TotalDays 
                }
            } 

            $LastPlayedNumberdate = $TotalFound | Select-Object -Last 1
            $Curentdays = New-TimeSpan -Start $LastPlayedNumberdate.DATE -End  $TodayDate | Select-Object -Property TotalDays            
            $Media = Get-Median  $GetNumberOfDays.TotalDays

            #############  Calculate media 

            #The number generated must not be one of the preveus number generated 
            #The number must be played in the past 10 years 70 or more times or be any of the following numbers 61,64,69
            
            ##Test Write-Host "White Ball:" "$DrawNumber" -ForegroundColor DarkCyan
            ##Test Write-Host  "Last play todal days:"  $Curentdays.TotalDays -ForegroundColor Yellow
            ##Test Write-Host "Media:" $Media -ForegroundColor Green

        } until ( ( $DrawNumber -notin $WiningNumbers ) -and ($TotalFound.Count -ge 70 -or $DrawNumber -in "61", "64", "69") -and ( $Curentdays.TotalDays -ge $Media ))
      
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
        $TotalRedBallFound = $AllRedBall | Where-Object { $_.RB -eq $RedBall }  | Sort-Object { $_.DATE -as [datetime] }
        
        ############# Calculate Media
        #Get all the number games of each number and get their median of playing days
        
           $GetNumberOfDays = @()

            for ($i = 0; $i -lt   $TotalRedBallFound.Count; $i++) {
                $Nextdate = $i + 1
                if ( $null -ne  $TotalRedBallFound[$Nextdate].DATE) {
                    $GetNumberOfDays += New-TimeSpan -Start $TotalFound[$i].DATE -End  $TotalFound[$Nextdate].DATE | Select-Object -Property TotalDays 
                }
            } 

            $LastPlayedNumberdate =   $TotalRedBallFound | Select-Object -Last 1
            $Curentdays = New-TimeSpan -Start $LastPlayedNumberdate.DATE -End  $TodayDate | Select-Object -Property TotalDays
            $Media = Get-Median  $GetNumberOfDays.TotalDays 

            ############# Calculate Media

          
        #The number must be played in the past 10 years 30 or more times
    } until (( $TotalRedBallFound.Count -ge 30 ) -and (  $Curentdays.TotalDays -ge $Media  ))

    ##Test Write-Host "Power Ball:"  "$RedBall" -ForegroundColor DarkCyan
    ##Test Write-Host  "Last play todal days:"  $Curentdays.TotalDays -ForegroundColor Yellow
    ##Test Write-Host "Media:" $Media -ForegroundColor Green
    ##Test Write-Host  $TotalRedBallFound.Count

    #Number randomly generated for White Ball 
    $WiningNumbers = $WiningNumbers | Sort-Object

    #Print number with Green color the White balls and with Red the (Power Ball)
    Write-Host $WiningNumbers -ForegroundColor Green -NoNewline | Sort-Object 
    Write-Host ""$RedBall  -ForegroundColor Red 

    #Returning White Balls numbers + Red ball (Power Ball) (Spaces between numbers removed)
    return  $WiningNumbers + $RedBall
    }

    ########################## END DRAWWING  FUNCTION #######################

    #loading History results   
    $HistoryDataResults = Import-Csv $LocalHistoryResults | Select-Object -Property All

    ##################################### USER INTERACTION #######################################
    
    Write-Host 'Pick your Numbers $$$' -ForegroundColor Yellow
    $PickNumbers = Read-Host "How many Numbers ?" #Capture Input

    #If the input are numbers
    if ($PickNumbers -match '\d' ) {
        
        $SaveResults=@()
        $SaveResultsToCSV =@()
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
                }else{
                     $SaveResultsToCSV += $ForCsvitems
                     $Duplicated = $false
                }

                $SaveResults += $FullNumber
                #Write-Host $FullNumber #Test
            } until ( ($FullNumber -notin $HistoryDataResults.All) -and ( $Duplicated -eq $false ) )
        }
        
        #Creating PickedNumbers.CSV for saving the picked numbers in the end of the execution
        if ( (Test-Path $LocalPickedNumbersPath) -eq $false ) {

            New-Item -ItemType Directory -Force -Path $LocalPickedNumbersPath | Out-Null     
        }
        Write-Output "N1,N2,N3,N4,N5,RB,DATE" | Out-File "$LocalPickedNumbersPath\Picked-$TodayDate.csv" -Force
        $SaveResultsToCSV | ForEach-Object {  Write-Output ($_ + $TodayDate)} | Out-File "$LocalPickedNumbersPath\Picked-$TodayDate.csv" -Append -Force
    }

    ##################################### END USER INTERACTION #######################################
}

