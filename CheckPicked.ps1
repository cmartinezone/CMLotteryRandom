#Project https://github.com/rcotter/lottery-ticket

$url = "https://games.api.lottery.com/api/v2.0/results?game=59bc2b6031947b9daf338d32" 
$OnlineData = Invoke-RestMethod -Method 'Get' -Uri $url 

$GetLastResult = $OnlineData.results | Select-Object -First 1

#Import Picked numbers
$PickedNumbers = Import-Csv ".\PickedNumbers.csv"
$WonNumbers = $null
$PowerBall  = $null
$GetLastResult.values | ForEach-Object {
    
    if ( ($_.name -ne "Powerball") -and ($_.name -ne "Power Play") ) {
       
       $WonNumbers +=  " "+$_.value 
      
    }

    if ( $_.name -eq "Powerball" ) {
        
        $PowerBall = $_.value 
    }
  
}

Write-Host $WonNumbers -ForegroundColor Green -NoNewline
Write-Host " $PowerBall"  -ForegroundColor Red
$date = $GetLastResult.asOfDate
$date = [datetime]$date
Write-Host  " Last Result:"+ $date.ToString('MM-dd-yyyy') -ForegroundColor Magenta
