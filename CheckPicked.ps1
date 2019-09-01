#Project https://github.com/rcotter/lottery-ticket

$url = "https://games.api.lottery.com/api/v2.0/results?game=59bc2b6031947b9daf338d32" 
$OnlineData = Invoke-RestMethod -Method 'Get' -Uri $url 

$GetLastResult = $OnlineData.results | Select-Object -First 1
#Import Picked numbers
$PickNumbers = Import-Csv  .\PickedNumbers\Picked-carlos-08-24-2019.csv
$WonNumbers = @()
$PowerBall = @()
$PowerPlay = @()
$GetLastResult.values | ForEach-Object {
    
    if ( ($_.name -ne "Powerball") -and ($_.name -ne "Power Play") ) {
       
        $WonNumbers += $_.value 
    }

    if ( $_.name -eq "Powerball" ) {    
        $PowerBall = $_.value 
    }

    if ($_.name -eq "Power Play") {
        
        $PowerPlay = $_.value 
    }
  
}
Write-Host $WonNumbers -ForegroundColor Green -NoNewline
Write-Host " $PowerBall"  -ForegroundColor Red
#Write-Host " $PowerPlay"  -ForegroundColor Red
$date = $GetLastResult.asOfDate
$date = [datetime]$date
Write-Host  "Last Result:" $date.ToString('MM-dd-yyyy') -ForegroundColor Magenta

Write-Host""
Write-Host "Checking your Tickets:" -ForegroundColor Yellow

foreach ( $PickNumber in $PickNumbers) {
    

    $count = 0
    foreach ($WonNumber in $WonNumbers) {
        
        if ( $PickNumber.N1 -eq $WonNumber ) {
            $count ++
        }
        if ( $PickNumber.N2 -eq $WonNumber ) {
            $count ++
        }
        if ( $PickNumber.N3 -eq $WonNumber ) {
            $count ++
        }
        if ( $PickNumber.N4 -eq $WonNumber ) {
            $count ++
        }
        if ( $PickNumber.N5 -eq $WonNumber ) {
            $count ++
        }
    }
    
    if ($PickNumber.RB -eq $PowerBall ) {
        $RedBall = 1
    }
    else {
        $RedBall = 0
    }
    
    
    if ($count -eq 5 -and $RedBall -eq 1) {
        $Money = '$$$ JackPot $$$'
    }
   elseif ($count -eq 5 -and $RedBall -eq 0) {
        $Money = "$ 1 Million"
    }
     
    elseif ($count -eq 4 -and $RedBall -eq 1) {
        $Money = "$ 50,000"
    }

    elseif ($count -eq 4 -and $RedBall -eq 0) {
        $Money = "$ 100"
    }
    elseif ($count -eq 3 -and $RedBall -eq 1) {
        $Money = "$ 100"
    }
    elseif ($count -eq 3 -and $RedBall -eq 0) {
        $Money = "$ 7"
    }
    elseif ($count -eq 2 -and $RedBall -eq 1) {
        $Money = "$ 7"
    }
    elseif ($count -eq 1 -and $RedBall -eq 1) {
        $Money = "$ 4"
    }
    elseif ($count -eq 0 -and $RedBall -eq 1) {
        $Money = "$ 4"
    }else{
        $Money = "$ 0"
    }

    
    Write-Host $PickNumber.N1 $PickNumber.N2 $PickNumber.N3 $PickNumber.N4 $PickNumber.N5 -ForegroundColor  Green -NoNewline
    Write-Host "" $PickNumber.RB  -ForegroundColor Red -NoNewline
    Write-Host " :::!!!Results!!!:::: White Balls:" $count "Power Ball:" $RedBall -ForegroundColor Gray -NoNewline
    Write-Host " :: Money:"  $Money  -ForegroundColor Green

}
