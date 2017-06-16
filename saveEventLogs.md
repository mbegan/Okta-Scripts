# saveEventLogs.ps1 How-To

- [Setting Up Your Environment](#setting-up-your-environment)
- [Running the script](#running-the-script)
- [Scheduling the script](#scheduling-the-script)

saveEventLogs is a powershell script written to collect and store logs from [Okta](https://www.okta.com/).  In theory it should run on any platform capable of running powershell, i have tested it on OS-X and Windows 10.

- The script relies on my powershell module for Okta, [Okta-PSModule](https://github.com/mbegan/Okta-PSModule)
- events are saved in a text file using the [JSON Lines format](http://jsonlines.org/)
    - events are saved in a datestamped file based on the published time of the event
    - a datestamped file is only created if an event occured on that day
    ```bash
     1264 -rwxr--r--  1 matt  staff  644199 Jun 16 06:58 OktaEvent_matt_2017-06-01.jsonl
      112 -rwxr--r--  1 matt  staff   57055 Jun 16 06:58 OktaEvent_matt_2017-06-02.jsonl
       16 -rwxr--r--  1 matt  staff    6001 Jun 16 06:58 OktaEvent_matt_2017-06-05.jsonl
        8 -rwxr--r--  1 matt  staff    3958 Jun 16 06:58 OktaEvent_matt_2017-06-07.jsonl
        8 -rwxr--r--  1 matt  staff    3861 Jun 16 06:58 OktaEvent_matt_2017-06-09.jsonl
        8 -rwxr--r--  1 matt  staff    3946 Jun 16 06:58 OktaEvent_matt_2017-06-13.jsonl
    ```
- Feedback is welcome

## Setting Up Your Environment

1. Follow these instructions to download and configure the [Okta-PSModule](https://github.com/mbegan/Okta-PSModule/blob/master/README.md)
    - Make note of the org name you use
    - Mine is called 'matt'
2. Download and Save the [saveEventLogs.ps1](https://github.com/mbegan/Okta-Scripts/blob/master/saveEventLogs.ps1) to your computer
    - Mine lives in `C:\Users\username\Documents\WindowsPowerShell\Modules\Okta-Scripts`
3. Create a directory where you'd like to store your logs
    - Mine lives in `C:\logs\`

## Running the Script

1. Open a command prompt or terminal window
2. Change to the directory you want to store you logs in
    ```
    cd C:\logs
    ```
3. Execute the script (replace script location, orgname and startDate with your values)
    ```
    powershell -file C:\Users\username\Documents\WindowsPowerShell\Modules\Okta-Scripts\saveEvents.ps1 -oOrg matt -startDate 2017-01-01
    ```

### Important file
* **.state_org** The first time you run the script a file will be created called `.state_<orgname>`.  This file is used for ongoing collection and is used to keep track of the date and eventId of the last event retrieved.

#### Ongoing Collection
When the script executes it will look in its current directory for a .state_<orgname> file, if found the startDate is retrieved from that file and the command line argument startDate value is ignored

#### Creating symlinks
You may find it convienient to create a link to the script file

1. Linux/Mac
    ```bash
    cd /logs
    ln -s /users/username/.local/share/powershell/Modules/Okta-Scripts/saveEvents.ps1 .
    ```
2. Windows
    ```
    cd C:\logs
    mklink saveEvents.ps1 C:\Users\username\Documents\WindowsPowerShell\Modules\Okta-Scripts\saveEvents.ps1
    ```
    
## Scheduling the Script

1. Windows

2. Linux/Mac
