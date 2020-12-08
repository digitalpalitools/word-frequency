[![Continuous Deployment](https://github.com/digitalpalitools/wordFreq/workflows/Continuous%20Deployment/badge.svg)](https://github.com/digitalpalitools/wordFreq/actions?query=workflow%3A%22Continuous+Deployment%22)

# Tipitaka Word Frequency data

Inclusion and exclusion data for generating the Pāli word frequency. Also contains the scripts to regenerate them.

# Instructions

## Refresh files

- ```.\process-files.ps1 D:\src\dpt\cst\ D:\src\dpt\wf\```

## Run unit tests

- ```npm i nodemon -g```
- ```nodemon --ext ps1,psm1 --ignore .\cscd --exec 'pwsh.exe -NoProfile -NoLogo -NonInteractive -Command \"& { Invoke-Pester -Path . }\"'```
