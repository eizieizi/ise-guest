function Invoke-GetInput {

    #Forces User to specify details unless a default value is suggested. If a defautl value is suggested, and no User input is provided, the default value is used.
    param (
        [parameter(Mandatory=$true)]
        [String]$Question,
        [String]$Suggestion,
        [Switch]$SecureString
    )
        $prompt=""
        while (-Not($prompt)) {
            if ($suggestion) {
                $prompt=Read-Host -Prompt "$Question, default value is [$Suggestion]"
                if (-Not($prompt)) {
                    return $Suggestion
                }
            }
            else {
                $prompt = Read-Host -Prompt $Question
            }
        }

        if ($SecureString) {
            
            $prompt = ConvertTo-SecureString $prompt -AsPlainText -Force
        }
        return $prompt
    }
    function Get-RandomPassword {
        param (
            [Parameter(Mandatory)]
            [int] $length
        )
        #$charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{]+-[*=@:)}$^%;(_!&amp;#?>/|.'.ToCharArray()
        $charSet = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ123456789'.ToCharArray()
        $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $bytes = New-Object byte[]($length)
     
        $rng.GetBytes($bytes)
     
        $result = New-Object char[]($length)
     
        for ($i = 0 ; $i -lt $length ; $i++) {
            $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
        }
     
        return (-join $result)
    }

    function Get-GuestData {
        param (
            [parameter(Mandatory=$true)]
            [string]$guest_type,
            [parameter(Mandatory=$true)]
            [string]$portal_id,
            [parameter(Mandatory=$true)]
            [string]$guest_location,
            [parameter(Mandatory=$true)]
            [string]$guest_lifetime,
            [parameter(Mandatory=$true)]
            [string]$guest_username,
            [parameter(Mandatory=$true)]
            [string]$guest_password,
            [parameter(Mandatory=$true)]
            [string]$valid_from,
            [parameter(Mandatory=$true)]
            [string]$valid_to
        )
        #Create Body with variables
        [string]$new_guest_body="{
            `"GuestUser`": {
                `"guestType`": `"$guest_type`",
                `"reasonForVisit`": `"ISE Guest API`",
                `"portalId`" : `"$portal_id`",
                
                `"guestInfo`": {
                    `"enabled`": `"true`",
                    `"userName`": `"$guest_username`",
                    `"password`": `"$guest_password`"
                },
                `"guestAccessInfo`": {
                    `"validDays`": $guest_lifetime,
                    `"fromDate`": `"$valid_from`",
                    `"toDate`": `"$valid_to`",
                    `"location`": `"$guest_location`"
                }
            }
        }
        "
        return $new_guest_body
    }