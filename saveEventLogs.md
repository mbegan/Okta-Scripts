# saveEventLogs.ps1 and saveEventLogsV2.ps1 How-To

- [Setting Up Your Environment](#setting-up-your-environment)
- [Running the script](#running-the-script)
- [Scheduling the script](#scheduling-the-script)

1. saveEventLogs.ps1 is a powershell script written to collect and store [events](https://developer.okta.com/docs/api/resources/events.html) from [Okta](https://www.okta.com/)
1. saveEventLogsV2.ps1 is a powershell script written to collect and store [logs](https://developer.okta.com/docs/api/resources/system_log.html) from [Okta](https://www.okta.com/)

>In theory These should run on any platform capable of running powershell (pwsh), i have tested it on OS-X and Windows 10

- The script relies on my powershell module for Okta, [Okta-PSModule](https://github.com/mbegan/Okta-PSModule)
- events/logs are saved in a text file using the [JSON Lines format](http://jsonlines.org/)
  - events/logs are saved in a datestamped file based on the published time of the event
  - a datestamped file is only created if an event occured on that day
    ```bash
    128 -rw-r--r--  1 matt  staff   64917 Nov 10 06:51 OktaLog_matt_2017-11-01.jsonl
     32 -rw-r--r--  1 matt  staff   14243 Nov 10 06:51 OktaLog_matt_2017-11-02.jsonl
    176 -rw-r--r--  1 matt  staff   87505 Nov 10 06:51 OktaLog_matt_2017-11-03.jsonl
     16 -rw-r--r--  1 matt  staff    6708 Nov 10 06:51 OktaLog_matt_2017-11-04.jsonl
      8 -rw-r--r--  1 matt  staff    2208 Nov 10 06:51 OktaLog_matt_2017-11-05.jsonl
      8 -rw-r--r--  1 matt  staff    1247 Nov 10 06:51 OktaLog_matt_2017-11-06.jsonl
    912 -rw-r--r--  1 matt  staff  453712 Nov 10 06:51 OktaLog_matt_2017-11-07.jsonl
     88 -rw-r--r--  1 matt  staff   41084 Nov 10 06:51 OktaLog_matt_2017-11-08.jsonl
      8 -rw-r--r--  1 matt  staff    1247 Nov 10 06:51 OktaLog_matt_2017-11-09.jsonl
     24 -rw-r--r--  1 matt  staff   10998 Nov 10 07:06 OktaLog_matt_2017-11-10.jsonl
    ```
- Feedback is welcome

## Setting Up Your Environment

1. Follow these instructions to download and configure the [Okta-PSModule](https://github.com/mbegan/Okta-PSModule/blob/master/README.md)
    - Make note of the org name you use
    - Mine is called 'matt'
1. Download and Save the [saveEventLogs.ps1](https://raw.githubusercontent.com/mbegan/Okta-Scripts/master/saveEventLogs.ps1) or [saveEventLogsV2.ps1](https://raw.githubusercontent.com/mbegan/Okta-Scripts/master/saveEventLogsV2.ps1)to your computer
    - Mine lives in `C:\Users\username\Documents\WindowsPowerShell\Modules\Okta-Scripts`
1. Create a directory where you'd like to store your logs
    - Mine lives in `C:\logs\`

## Running the Script

1. Open a command prompt or terminal window
1. Change to the directory you want to store you logs in
    ```bat
    cd C:\logs
    ```
1. Execute the script (replace script location, orgname and startDate with your values)
    ```bat
    # save events on windows
    powershell -file C:\Users\username\Documents\WindowsPowerShell\Modules\Okta-Scripts\saveEvents.ps1 -oOrg matt -startDate 2017-01-01
    # save system logs on mac
    powershell -file /Users/username/.local/share/powershell/Modules/Okta-Scripts/saveEventLogsV2.ps1 -oOrg matt -startDate 2017-01-01
    ```

### Important file

1. **.state_orgname** (V1) or **.logState_orgname** (V2) The first time you run the script a file will be created called `.state_<orgname>` (V1) or `.logState_<orgname>` (V2).  This file is used for ongoing collection and is used to keep track of the date and eventId of the last event retrieved.

#### Ongoing Collection

When the script executes it will look in its current directory for a .state__orgname_ file, if found the startDate is retrieved from that file and the command line argument startDate value is ignored

#### Creating symlinks

You may find it convienient to create a link to the script file

1. Linux/Mac
    ```bash
    cd /logs
    ln -s /users/username/.local/share/powershell/Modules/Okta-Scripts/saveEvents.ps1 .
    ```
1. Windows
    ```bat
    cd C:\logs
    mklink saveEvents.ps1 C:\Users\username\Documents\WindowsPowerShell\Modules\Okta-Scripts\saveEvents.ps1
    ```

## Scheduling the Script

### Windows

>see: windows task scheduler

### Linux/Mac

>see: crontab
