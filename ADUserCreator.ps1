##########################     INITIALIZATION     ##########################

## Reload with Elevate privileges if not Administrator ##
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) 
{
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) 
    {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

## Declare global domain variables ##
$global:dcName = "DC"
$global:domainName1 = "home"
$global:domainName2 = "local"
$global:ouName = "Employees"
$global:createdUserAccounts = @{}

############################     FUNCTIONS      ############################

## Function to create and return a new user object ##
function CreateUser()
{
    ##Create random passphrase for new user account ##
    $global:randomPassword = GeneratePassword

    ## User object template with predefined properties ##
    $user = @{
        Path = "OU=$ouName ,DC=$domainName1 ,DC=$domainName2"
        Server = $dcName
        ChangePasswordAtLogon = $true
        Enabled = $true
        AccountPassword = (ConvertTo-SecureString $global:randomPassword -AsPlainText -Force)
    }

    ## Array of user defined property names ##
    $properties = "First Name", "Last Name"

    ## Loop through each property name in the properties array ##
    foreach($property in $properties)
    {
        ## Ask user input for property value ##
        $propertyValue = Read-Host $property

        if ($property -eq "First Name")
        {
            $property = "GivenName"
        }
        elseif ($property -eq "Last Name")
        {
            $property = "Surname"
        }

        ## Add the Property and Value to the user object ##
        $user[$property] = $propertyValue
    }

    if ($user.GivenName -ne '' -and $user.Surname -ne '')
    {
        ## Generate user properties from input ##
        $global:userLogin  = GenerateLogin $user.GivenName $user.Surname
        $global:accountName  = GenerateAccountName $user.GivenName $user.Surname

        ## Add generated values to remaining user object properties ##
        $user['SamAccountName'] = $userLogin
        $user['UserPrincipalName'] = $userLogin + "@class.com"
        $user['Name'] = $global:accountName
    }
    else
    {
        $user = $false
    }

    return $user
}

## Function to create and return a random passphrase ##
function GeneratePassword()
{
    ## Arrays of words and numbers to be used for passphrase ##
    $numbers = 1000..9999
	$adj = @(
    "majestic", "scary", "charming", "breathtaking", "beautiful", "peaceful", "enchanted", 
    "alluring", "magical", "mystical", "dreamy", "legendary", "mysterious", "intriguing",
    "stunning", "extraordinary", "incredible", "fantastic", "amazing", "unbelievable",
    "burning", "groovy", "funky", "awesome", "quiet", "colorful"
    )
    $words = @(
    "apple", "banana", "cherry", "orange", "grape", "pineapple", "strawberry", "watermelon",
    "house", "apartment", "cabin", "mansion", "castle", "cottage", "tent",
    "dragon", "mermaid", "unicorn", "werewolf", "vampire", "goblin", "troll"
    "seagull", "goat", "rabbit", "hamster", "shark", "horse", "monkey", "turtle",
    "tree", "flower", "cloud", "rock", "river", "ocean", "mountain", "creek",
    "nebula", "moon", "star", "planet", "galaxy", "comet", "asteroid", "meteor",
    "volcano", "earthquake", "tornado", "hurricane", "storm", "rain",
    "fire", "smoke", "wind", "rainbow", "thunder", "lightning"
    )

    ## Shuffle the arrays for increased randomness##
    $adj = $adj | Get-Random -Count $adj.Count
    $words = $words | Get-Random -Count $words.Count

    ## Create a passphrase in the format "adj-word_num" ##
    for ($i=0; $i -lt 3; $i++)
    {
        if ($i -eq 0)
        {
            $passphrase = (Get-Random -InputObject $numbers)
        }
        elseif ($i -eq 2)
        {
            $passphrase = (Get-Random -InputObject $adj) + "-" + $passphrase
        }
        else
        {
            $passphrase = (Get-Random -InputObject $words) + "_" + $passphrase
        }
    }
    return $passphrase
}

## Function to Generate account name using first and last name ##
function GenerateAccountName($firstName, $lastName)
{
    $accountName = $firstName + " " + $lastName
    $userExists = Get-ADUser -Filter {Name -eq $accountName}
    $nameIndex = 2

    # Generate unique account name and check if the user exists in Active Directory ##
    while ($userExists)
    {
        if($nameIndex -lt 10)
        {
            $accountName = $firstName + " " + $lastName + "0" + $nameIndex
        }
        else
        {
            $accountName = $firstName + " " + $lastName + $nameIndex
        }
        $userExists = Get-ADUser -Filter {Name -eq $accountName}
        $nameIndex++
    }
    return $accountName
}

## Function to Generate login id using first and last name ##
function GenerateLogin($firstName, $lastName)
{
    ## Declare variables ## 
    $firstDefinedLength = 1
    $lastDefinedLength = 5
    $randomLetterLength = 2
    $userExists = $true

    ## Convert first name and last name to lowercase ##
    $firstNameLower = $firstName.ToLower()
    $lastNameLower = $lastName.ToLower()

    ## If last name is shorter then defined length, increase first initials to make up for missing last name characters, else shorten last name ##
    if ($lastNameLower.Length -lt $lastDefinedLength)
    {
        $firstDefinedLength = $lastDefinedLength - ($lastNameLower.Length - 1)
    }
    else
    {
        $lastNameLower = $lastNameLower.Substring(0, $lastDefinedLength)
    }

    ## Error checking for defined first name length to prevent invalid index ##
    if ($firstNameLower.Length -lt $firstDefinedLength)
    {
        $firstNameLower = $firstNameLower.Substring(0, $firstNameLower.Length)
    } 
    else 
    {
        $firstNameLower = $firstNameLower.Substring(0, $firstDefinedLength)
    }

    # Generate unique user id and check if the user exists in Active Directory ##
    while ($userExists)
    {
        $randomString = GenerateRandomString -length (8 - ($firstNameLower.Length + $lastNameLower.Length))
        $userName = $firstNameLower + $lastNameLower + $randomString
        $userExists = Get-ADUser -Filter {SamAccountName -eq $userName}
    }
    return $userName
}

## Function to capture key press ##
function KeyDown()
{
    ## Capture key press ##    
    $key = [Console]::ReadKey($true)

    ## Check the selected option based on key pressed ##
    switch ($key.KeyChar)
    {
        "`r"
        {
            $selectedOption = "CreateUser"
        }
        "l"
        {
            $selectedOption = "ListUsers"
        }
        "e"
        {
            $selectedOption = "Exit"
        }
        "s"
        {
            $selectedOption = "SavetoFile"
        }
        default
        {
            $selectedOption = "Undefined"
        }
    }
    return $selectedOption
}

## Generate random string ##
function GenerateRandomString($length)
{
    for ($i = 0; $i -lt $length; $i++)
    {
        $newString = $newString + [char](Get-Random -Minimum 97 -Maximum 123)
    }
    return $newString
}


############################      MAIN      ############################

$selectedOption = "Undefined"

## Loop until prompted to exit by the user ##
while($selectedOption -ne 'Exit')
{
    ## Clear powershell window and display prompt ##
    Clear-Host
    Write-Host "           _____  _    _                _____                _              " -ForegroundColor Red
    Write-Host "     /\   |  __ \| |  | |              / ____|              | |             " -ForegroundColor Red
    Write-Host "    /  \  | |  | | |  | |___  ___ _ __| |     _ __ ___  __ _| |_ ___  _ __  " -ForegroundColor Magenta    
    Write-Host "   / /\ \ | |  |" 																  -ForegroundColor Magenta -NoNewline
    Write-Host " | |  | / __|/ _ \ '__| |    | '__/ _ \/ _` | __ / _ \" 				  -ForegroundColor DarkMagenta -NoNewline
    Write-Host "| '__|" 																	  -ForegroundColor Magenta
    Write-Host "  / ____ \| |__| | |__| \__ \  __/ |  | |____| | |  __/ (_| | || (_) | |    " -ForegroundColor Magenta
    Write-Host " /_/    \_\_____/ \____/|___/\___|_|   \_____|_|  \___|\__,_|\__\___/|_|    " -ForegroundColor Red

    Write-Host " Please enter the name of the employee:" -ForegroundColor Yellow
    Write-Host ""

    ## Create user using the CreateUser function ##
    $newUser = CreateUser

    ## try to add the user to AD and create result, If there is an error then show error as result ##
    try
    {
        if($newUser -ne $false)
        {
            New-ADUser @newUser
            $newUserInfo = @{
                Account_Name = $accountName
                User_ID = $userLogin
                Password = $randomPassword
            }

            Write-Host ""
            Write-Host "New Employee Account:" -ForegroundColor Green
            Write-Host "---------" -ForegroundColor Green
        
            ## recursively loop through each dictionary pair in newUserInfo and display user information ##
            $newUserInfo.GetEnumerator() | ForEach-Object {
                Write-Host ("{0,-15} : {1}" -f $_.Key, $_.Value)
            }

            ## Add user information to global list of created users ##
            $global:createdUserAccounts.Add($accountName + "(" + $userLogin + ")    ", $randomPassword)
        }
    }
    catch
    {
        Write-Host $_
    }

    ## Prompt user to create another user or exit ##
    Write-Host ""
    Write-Host "Press any key to create another user, press L to list created users and passwords, or press E to leave."
    $selectedOption = KeyDown

    ## Display list of users and passwords if option is list or L ##
    if ($selectedOption -eq 'ListUsers')
    {
        ## Format list into a table and then format table to display users and passwords ##
        $formattedUserAccounts = $global:createdUserAccounts.GetEnumerator() | Select-Object @{Name="Account Name"; Expression={$_.Key}}, 
                                                                                 @{Name="Password"; Expression={$_.Value}} |
                                                                                 Sort-Object -Property "Account Name"
        $formattedUserAccounts | Format-Table -AutoSize 
       
        ## Ask user if exporting to file or exiting and export to script location if exporting ##
        Write-Host "Press any key to create another user or press S to save the list to a file."
        $exportOption = KeyDown
        
        ## save list to file if user inputs save or s ##
        if ($exportOption -eq 'SavetoFile')
        {
            ## Format log save location is same directory as script ##
            $scriptLocation = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
            $saveLocation = $scriptLocation + "/logs"
            
            $locationExists = Test-Path $saveLocation
            
            ## Test if logs directory exist and create one if it doesnt ##
            if ($locationExists -eq $false)
            {
                New-Item -ItemType Directory -Path $saveLocation
            }

            ## get the date formated as year-month-day and time ##
            $date = Get-Date -Format "y-M-d"
            $timeCreated = "---------- Created " + (Get-Date -DisplayHint Time).ToString() + " ----------"

            ## format file name with date and concat with save location ##
            $saveLocation = $saveLocation + "/" + $date + "_NewUsers.txt"
            
            ## Save file to location ##
            $timeCreated | Out-File -Append -FilePath $saveLocation
            $formattedUserAccounts | Format-Table -AutoSize | Out-File -Append -FilePath $saveLocation
            Write-Host "File saved to " $saveLocation
            Start-Sleep 4
        }
    }
}