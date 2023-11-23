*** Settings ***
Documentation     https://docs.robotframework.org/docs/different_libraries/database
Library           DatabaseLibrary
Library           OperatingSystem
Library           Collections

*** Variables ***
${DBHost}         db.prod.hiorka.com
${DBName}         firmware
${DBPass}         35YouWeiZhiNeng
${DBPort}         5432
${DBUser}         evocolabsAdmin


*** Keywords ***
Connect User Log Database 
    Connect To Database    psycopg2    ${DBName}    ${DBUser}    ${DBPass}    ${DBHost}    ${DBPort}

Disconnect User Log Database 
    Disconnect From Database 

