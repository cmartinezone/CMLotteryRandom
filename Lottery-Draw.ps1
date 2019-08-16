#Author: Carlos Martinez  GitHub @cmartinezone

#Lottery PowerBall Numbers Generator
#The numbers randomly choosen are picked in base of the high (hots) numbers played during the past 10 years.

#Lottery API Get Request
$url = "https://data.ny.gov/resource/d6yy-54nr.json" 
$OnlineData = Invoke-RestMethod -Method 'Get' -Uri $url 


#Parsin Data from API Response to CSV 
#Adding commas to API Response 
$WiningNumbersToCSV = $OnlineData.winning_numbers | ForEach-Object { $_ -replace (" ", ",") }
$CSVHeader = "N1,N2,N3,N4,N5,RB" 
Write-Output $CSVHeader | Out-File ".\WebData.csv" -Force
$WiningNumbersToCSV | Add-Content -Path ".\WebData.csv" -Force


#Import data from the Webdata.CSV to create one object with the wining number from N1 TO N5 (White Balls)
$AllWebDataFromCSV = Import-Csv  -Path ".\WebData.csv" 
#Selecting the all the number in position 1 to 5 (White Balls)
$NFrom1To5 = $AllWebDataFromCSV | Select-Object -Property N1, N2, N3, N4, N5
#Adding all the numbers from position 1 to 5 (White Balls) in one object 
$AllFrom1To5 += $NFrom1To5.N1 
$AllFrom1To5 += $NFrom1To5.N2 
$AllFrom1To5 += $NFrom1To5.N3 
$AllFrom1To5 += $NFrom1To5.N4 
$AllFrom1To5 += $NFrom1To5.N5 
#Creating CSV File with all the numbers from the position 1 to 5 (White Balls)
$AllFrom1To5 |  Out-File ".\AllFrom1To5.csv" -Force

#Selecting All Red Ball numbers (PowerBall)
$AllRedBall = $AllWebDataFromCSV | Select-Object -Property RB
#Creating CSV File with all the Red Ball numbers (Power Ball)
$AllRedBall |  Out-File ".\AllRedBall.csv" -Force

#Creating PickedNumbers.CSV for saving the picked numbers in the end of the execution
Write-Output "N1,N2,N3,N4,N5,RB" | Out-File ".\PickedNumbers.csv" -Force

#Function For Drawing Random numbers
function DrawWiningNumbers {
    #Object to storage number in position 1 to 5 (White Ball)
    $WiningNumbers = @()
    
    #Generating White Balls randomly 
    while ( $WiningNumbers.Count -lt 5 ) {

        do { $DrawNumber = (Get-Random -Minimum 01 -Maximum 69) #Get Random number between 1 to 69
            
            #Adding Zero if the number is less then or equal 9
            if ($DrawNumber -le 9) {
                $DrawNumber = "0" + $DrawNumber
            }
            
            #Search for how many times the random number has been played during the past 10 year of data
            $TotalFound = $AllFrom1To5 | Where-Object { $_ -eq "$DrawNumber" }

           #The number generated must not be one of the preveus number generated 
           #The number must be played in the past 10 years 70 or more times or be any of the following numbers 61,64,69
        
        } until ( ($DrawNumber -notin $WiningNumbers) -and ($TotalFound.Count -ge 70 -or $DrawNumber -in "61", "64", "69"))
          
        $WiningNumbers += $DrawNumber
    }
     
    #Generating Red Ball (Power Ball) randomly 
    do { $RedBall = (Get-Random -Minimum 01 -Maximum 26)
         
        #Adding Zero if the number is less then or equal 9
        if ($RedBall -le 9) {
            $RedBall = "0" + $RedBall
        }
        
        #Search for how many times the random number has been played during the past 10 year of data
        $TotalRedBallFound = $AllRedBall |  Where-Object {$_ -match "$RedBall" }
        
        #The number must be played in the past 10 years 30 or more times
    } until ($TotalRedBallFound.Count -ge 30)
  
    
    #Saving Picked up numbers
    $PickedNumbers = $WiningNumbers | Sort-Object #Organize number from minor to mejor 
    $PickedNumbers += $RedBall  # Adding Red ball result 
    $AllPickedNumbers = "$PickedNumbers" | ForEach-Object { $_ -replace (" ", ",") } #adding commas for csv format
    Write-Output  $AllPickedNumbers | Out-File ".\PickedNumbers.csv" -Append -Force  #Saving to CSV the result 

    #Number randomly generated for White Ball 
    $WiningNumbers = $WiningNumbers | Sort-Object

    #Print number with Green color the White balls and with Red the (Power Ball)
    Write-Host $WiningNumbers -ForegroundColor Green -NoNewline | Sort-Object 
    Write-Host ""$RedBall  -ForegroundColor Red 
   
    #Returning White Balls numbers + Red ball (Power Ball) (Spaces between numbers removed)
    return  $WiningNumbers + $RedBall
}


#Getting Data from the API Response and Removing the spaces between numbers
$HistoryDataResults = $OnlineData.winning_numbers | ForEach-Object { $_ -replace (" ", "") }


##################################### USER INTERACTION #######################################
Write-Host 'Pick your Numbers $$$'
$PickNumbers = Read-Host "How many Numbers ?" #Capture Input

#If the input are numbers
if ($PickNumbers -match '\d' ) {
    
    #Get the total of number input by the user
    for ($i = 0; $i -lt $PickNumbers; $i++) {
       
        #Get number that it is not equal to any of the preveus wining number in the past 10 years
        do {
            #Temp variable for Random number without spaces between numbers
            $FullNumber = $null 
            $Getnumbers = DrawWiningNumbers #Get Random numbers function 
            $Getnumbers | ForEach-Object { $FullNumber += "$_" }
            
          #Write-Host $FullNumber #Test
        } until ( $FullNumber -notin $HistoryDataResults)
    }
}





