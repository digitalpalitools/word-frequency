[![Continuous Integration](https://github.com/digitalpalitools/pure-machine-readable-corpus/workflows/Continuous%20Integration/badge.svg)](https://github.com/digitalpalitools/pure-machine-readable-corpus/actions?query=workflow%3A%22Continuous+Integration%22) [![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

# Pure Machine Readable Corpus

Rule driven generation of pure machine readable corpus from the various tipiṭaka sources (VRI, BJT, TT).

Additionally generate word frequency and related data from the above.

# Instructions

## Refresh files

- ```.\process-files.ps1 D:\src\dpt\cst\ D:\src\dpt\wf\```

## Run unit tests

- ```npm i nodemon -g```
- ```nodemon --ext ps1,psm1 --ignore .\cscd --exec 'pwsh.exe -NoProfile -NoLogo -NonInteractive -Command \"& { Invoke-Pester -Path . }\"'```
