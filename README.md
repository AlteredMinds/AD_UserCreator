# Active Directory User Creation Script

This PowerShell script automates the creation of Active Directory (AD) user accounts. It generates random passwords, unique usernames, and provides options to save the list of created users to a file.

## Features

- **Random Password Generation**: Creates complex, random passwords combining adjectives, nouns, and numbers.
- **Unique Account and Login Name Generation**: Ensures unique `SamAccountName` and user display names by checking for existing users in Active Directory.
- **User Input**: Prompts the user to enter the first and last names, which are used to generate the `SamAccountName`, `UserPrincipalName`, and display name.
- **Interactive Menu**: Provides a simple text-based menu for creating users, listing created accounts, and saving the information to a file.

## Usage

### 1. Download the Latest Release

Go to the [Releases](https://github.com/AlteredMinds/AD_UserCreator/releases) page and download the latest version of the script.

### 2. Run the Script

Open PowerShell and navigate to the downloaded script directory:

```powershell
cd path\to\script
.\UserCreationScript.ps1
```

### 3. Script Interaction

- **Create User**: Follow the prompts to create a new user account. 
- **List Users**: After creating accounts, you can list them along with their credentials.
- **Save to File**: Save the list of created users and their passwords to a log file.

### 4. Script Flow

1. **Input Employee Name**: The script will prompt you to input the first and last name of the employee.
2. **User Account Creation**: Based on your input, a unique username and password will be generated, and the user account will be created in Active Directory.
3. **Repeat or Exit**: After creating a user, you can either create another user, list all created users, or exit the script.
