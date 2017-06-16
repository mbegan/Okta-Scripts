# saveEventLogs.ps1 How-To

- [Setting Up Your Environment](#setting-up-your-environment)
- [Running the script](#running-the-script)
- [Scheduling the script](#scheduling-the-script)

saveEventLogs is a powershell script written to collect and store logs from [Okta](https://www.okta.com/).  In theory it should run on any platform capable of running powershell, i have tested it on OS-X and Windows 10.

- The script relies on my powershell module for Okta, [Okta-PSModule](https://github.com/mbegan/Okta-PSModule)
- events are saved in a text file using the [JSON Lines format](http://jsonlines.org/)
- Feedback is welcome

## Setting Up Your Environment

1. Follow these instructions to download and configure the [Okta-PSModule](https://github.com/mbegan/Okta-PSModule/blob/master/README.md)
    #### Make note of the org name you use
2. Download and Save the [saveEventLogs.ps1](https://github.com/mbegan/Okta-Scripts/blob/master/saveEventLogs.ps1) to your computer
3. Create a directory where you'd like to store your logs

### Important things

* **bold words in a list** this is where things are
* **bold words in a list 2** other stuff to consider

## Running the Script

- [A link to a thing in a list using dash instaead of star](#http://www.google.com)

### Less immportant details

Blah blah blah

#### Even less important here

1. Look no hands

    ```powershell
    someCommand -option value -option2 value2
    ```
## Scheduling the Script

1. Look no hands

    ```powershell
    someCommand -option value -option2 value2
    ```
