## Overview

The MF MINEDUDES IP Bot is an R script designed to monitor and notify changes in the public IP address of a server. It automates the process of checking the current public IP and compares it with a previously recorded IP. If a change is detected, the script sends a notification message to a specified Discord channel with the updated IP information. This is particularly useful for servers with dynamic IP addresses where regular updates are necessary.

This R utility is intended to be scheduled as a cron job on a Minecraft server. 

## Features
- **IP Monitoring:** Automatically retrieves the current public IP from `opendns.com`.
- **Change Detection:** Compares the current IP with the last known IP and detects changes.
- **Discord Notifications:** Sends notifications to a Discord channel when the IP changes.
- **Logging:** Maintains logs of operations and potential issues.
- **Log Management:** Automatically cleans up old log files based on a specified duration.

## Prerequisites
- R environment
- Required R packages: `pacman`, `lubridate`, `purrr`, `magrittr`, `glue`, `logger`, `devtools`
- `discordr` package (available on GitHub)
- An active Discord webhook to send notifications

## Installation
1. **Install R Packages:** Run the script to install and load required CRAN packages using `pacman`.
2. **Install `discordr`:** Since `discordr` is a GitHub package, it is installed using `devtools::install_github("EriqLaplus/discordr")`.
3. **Set Environment Variables:** Define the following environment variables:
   - `MF_MINEDUDES_WEBHOOK`: The Discord webhook URL.
   - `MF_MINEDUDES_USER`: The username for the bot.
   - `MF_MINEDUDES_CHANNEL`: The Discord channel name.
   - `MF_MINEDUDES_PORT`: The port number for your server.

## Usage
- **Running the Script:** Execute the script to start the IP monitoring process. The script will check the current IP and compare it with the last known IP (stored in `ip.RDS`).
- **Notifications:** If a change in IP is detected, a message is sent to the specified Discord channel with the new IP and port information.
- **Logs:** The script generates logs for each operation, stored in the `./log` directory.

## Helper Functions
- `validate_ip()`: Validates the format of the IP address.
- `remove_old_logs()`: Cleans up log files that are older than a specified number of days.

## Error Handling
The script includes `tryCatch` blocks for error handling. In case of an error or warning, logs are generated, and in certain cases, notifications are sent via Discord.

## Final Steps
After running the script, ensure that the environment variables are correctly set and that the Discord webhook is functioning. Regularly check the logs for any potential issues or notifications of IP changes.
