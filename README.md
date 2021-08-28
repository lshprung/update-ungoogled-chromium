## Introduction

**update-ungoogled-chromium** is a bash script that can help to automate installation and updating of [ungoogled-chromium](https://github.com/Eloston/ungoogled-chromium). The script parses the [atom feed](https://raw.githubusercontent.com/ungoogled-software/ungoogled-chromium-binaries/master/feed.xml) to check if a newer version of ungoogled-chromium is available, and prompts the user whether they would like to install it if there is.

*Note: update-ungoogled-chromium sources contributor binaries, which are not necessarily reproducible. For more information, see the note [here](https://github.com/Eloston/ungoogled-chromium#downloads)*

## Dependencies

- bash
- curl
- xml2

## Supported Platforms

Currently, update-ungoogled-chromium can target the following platforms:

- Portable Linux 64-bit
