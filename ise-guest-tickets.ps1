. .\functions.ps1

#ISE Variables
[string]$sponsor_user="tbd"
[string]$sponsor_pw="tbd"
[string]$ise_url="tbd"
[int]$ise_port=9060

[string]$guest_type="tbd"
[string]$portal_id="tbd"
[string]$guest_location="tbd"
[string]$wifi_name="tbd"

[string]$guest_user_prefix="tbd"
#Source variables from variable file (this one is in .gitignore) 
. .\variables.ps1

[int]$guest_accounts=Invoke-GetInput -Question "Wie viele Gastaccounts sollen erstellt werden (max. 100)" -Suggestion "10"
while ($guest_accounts -gt 100) {
    $guest_accounts=Invoke-GetInput -Question "Wie viele Gastaccounts sollen erstellt werden (max. 100)" -Suggestion "10"
}
[int]$guest_lifetime=Invoke-GetInput -Question "Fuer viele Tage (ab heute) soll der Interetzugriff erlaubt werden? (max. 5 Tage)" -Suggestion "1"



$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $sponsor_user,$sponsor_pw)))
$req=Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo);"Content-Type"="application/json";"Accept"="application/json";"Accept-Encoding"="gzip, deflate"} -Method "GET" -Uri "$ise_url`:$ise_port/ers/config/guestuser?size=100"
$all_guest_users=$req.SearchResult.resources

#Pagination of API (100 is size limit)
while ($req.SearchResult.nextPage) {
    $req=Invoke-RestMethod -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo);"Content-Type"="application/json";"Accept"="application/json";"Accept-Encoding"="gzip, deflate"} -Method "GET" -Uri $req.SearchResult.nextPage.href
    $all_guest_users+=$req.SearchResult.resources
}

#Write-Host "All Users on ISE:`n $($all_guest_users.name)"

$all_guest_accounts=@()
for ($i=0; $i -le $guest_accounts-1; $i++){
    #Declaring variables here because self-referencing on instantiation is not possible is PowerShell
    $creation=Get-Date
    $expiration=$($creation.AddDays($guest_lifetime))
    
    #Make sure that the randomly generated user does not exist on ISE already...if so, create new users until there is a unique one generated.
    $guest_username="$guest_user_prefix$(10000..99999 | Get-Random)"
    while (($all_guest_users.name) -Contains $guest_username ) {
        $guest_username="$guest_user_prefix$(10000..99999 | Get-Random)"
    }

    $all_guest_accounts+=[PSCustomObject]@{
        username= $guest_username
        password=Get-RandomPassword 8
        creation= $creation
        expiration= $expiration
        lifetime = $guest_lifetime
    }

    $html_user_content+="
    <div id=`"container`">
    <img id=`"image`" src=`"images/logo.png`" width=`"450`" height=`"250`">
    <p id=`"name`">NTS Example Gastwlan</p>
    <p id=`"wifi`"> WLAN-Name: $wifi_name <br>
    Username: $($all_guest_accounts[$i].username) <br>
    Passwort: $($all_guest_accounts[$i].password) <br>
    G&uuml;ltig bis: $(($all_guest_accounts[$i].expiration).ToString('dd\/MM\/yyyy hh:mm'))
    </p>
    </div>
    <br>
    <div class=`"linebreak`"></div>
    <div class=`"pagebreak`"> </div>"
        
    Invoke-WebRequest -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo);"Content-Type"="application/json";"Accept"="application/json";"Accept-Encoding"="gzip, deflate"} -Method "POST" -Uri "$ise_url`:$ise_port/ers/config/guestuser" -Body $(Get-GuestData -guest_type $guest_type -portal_id $portal_id -guest_location $guest_location -guest_username $($all_guest_accounts[$i].username) -guest_password $($all_guest_accounts[$i].password) -guest_lifetime $($all_guest_accounts[$i].lifetime) -valid_from $(($all_guest_accounts[$i].creation).ToString('MM\/dd\/yyyy hh:mm')) -valid_to $(($all_guest_accounts[$i].expiration).ToString('MM\/dd\/yyyy hh:mm'))) | Out-Null
}

#Cut off the last page break to prevent printers from printing last empty sheet 
$asdf=$html_user_content.Split("`n")
$html_user_content=[string]::Join("`n",$asdf, 0, $(($asdf.Length)-1))
    
#Create the HTML and insert the previous generated html with the user variables

"<!DOCTYPE html>
<html>
	<head>
		<title>Gasttickets</title>
		<meta charset=`"utf-8`">
        <!-- CSS einbinden -->
        <style>
        .linebreak {
        padding-top: 500px;
        }
        #container {
        width: 450px;
        height: 250px;
        position: absolute;
        }

        #wifi {
        position: absolute;
        top: 20px;
        left: 20px;
        font-size: small;
        color: transparent;
        text-shadow: 0 0 0px #fff;
        font-weight: bold;
        font-family: Arial, Helvetica, sans-serif
        }

        #name {
        position: absolute;
        top: -10px;
        left: 20px;
        font-size: large;
        color: transparent;
        text-shadow: 0 0 0px #fff;
        font-weight: bold;
        font-family: Arial, Helvetica, sans-serif
        }

        @media print {
        .pagebreak { page-break-before: always; } /* page-break-after works, as well */
        }

        @page 
        {
            size: auto;   /* auto is the initial value */
            margin: 0mm;  /* this affects the margin in the printer settings */
        }
    </style
	</head>
	<body>
    $html_user_content
	</body>
</html>" | Out-File -FilePath ".\guest-tickets.html"


#Run the HTML with the default browser
Invoke-Item ".\guest-tickets.html"