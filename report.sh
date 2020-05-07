#!/bin/sh
clear

#####################################################################
#                                                                   #
# INSPIRATION                                                       #
# -----------                                                       #
# https://gist.github.com/em92/795db8b67a87725a32122b36ada71115     #
#                                                                   #
# S.Incze (05-05-2020) v1.0.1                                       #
#                                                                   #
# Report IP's to AbuseIPDB based on outcome of docker               #
#                                                                   #
# Changelog:                                                        #
# v1.0.0 Initial Release 05-05-2020                                 #
# v1.0.1 Added Telegram Bot Notification, small 'grep' bugfixes     #
#                                                                   #
# Created for ALPINE Linux base System                              #
# USAGE: Add file to cronjob 'crontab -e'                           #
#                                                                   #
#####################################################################
# Logfilename
# -----------
LOG="honeypotip.log"

# Set your dockername here
# ------------------------
DOCKERNAME="ssh-honeypot"

# Set your AbuseIPDB key value here
# ---------------------------------
API_KEY="****"

# Set your Telegram token and id here, TELEGRAMBOT=true means you will receive a telegram message
# --------------------------------------------------------------------------------------------------------
TOKEN="bot****"
CHATID="****"
TELEGRAMBOT=true

# Current Date and Time variables
# -------------------------------
MONTH=$(date +%b)
DAY=$(date +%-d)
YEAR=$(date +%Y)
TIME=$(date +"%H:%M")

# Welcome banner and counter reporting categories
# -----------------------------------------------
WELCOME="Today is Month: $MONTH and Day: $DAY in the year $YEAR Time $TIME"
COUNTER=1
CAT=18,22

# Function for filing reports
# ---------------------------

function report {
 REPORT=$(curl --silent '-H' "Accept: application/json" '-H' "Key: $API_KEY" --data-urlencode "categories=$CAT" --data-urlencode comment="$COMMENT" --data-urlencode "ip=$IP" https://api.abuseipdb.com/api/v2/report | jq -r '.data' | jq -r '.ipAddress')
 if [ "$REPORT" == "$IP" ] ; then
    printf "The report has been submitted successfully. The following data was submitted to the abuse database:\nIP: $IP\nCategory: $CAT\nComment:$COMMENT\n"
 else
    echo "Error: The report could not be submitted. This may be due to an error in the syntax, revoked API-key or a previously reported hostname."
 fi
}

function telegram  {
 RESULT=$(curl --silent --data chat_id="$CHATID" --data-urlencode text="$MESSAGE" "https://api.telegram.org/"$TOKEN"/sendMessage" | jq -r .'ok')
 if [ "RESULT == true" ] ; then 
    echo "Telegram Successful"
 else
    echo "Telegram Not Successful"
 fi
}


# Main Scrpt Execute the following
# --------------------------------

echo "-----------------------------------------------------------"
#echo "Today is Month: $MONTH and Day: $DAY in the year $YEAR Time $TIME"
echo $WELCOME
echo "-----------------------------------------------------------"
echo ""

docker logs $DOCKERNAME | grep $MONTH | grep $DAY | grep $YEAR | awk 'NR!=1 {print $6 }' | sort | uniq -c | ( while read line ; do
 AMOUNT=$(echo $line | awk -v col1=1 -v col2=2 '{print $col1}')
 IP=$(echo $line | awk -v col1=1 -v col2=2 '{print $col2}')
 COMMENT="$COUNTER. On $MONTH $DAY $YEAR experienced a Brute Force SSH login attempt -> $AMOUNT unique times by $IP."
 echo $COMMENT
 COUNTER=$((COUNTER+1))
 report
done

MESSAGE="Reported $COUNTER IP's on $DAY $MONTH $YEAR at $TIME"

# Telegram message necessary?
# ---------------------------
if [ "$TELEGRAMBOT" = true ] ; then
   telegram
fi

echo $MESSAGE >> /root/$LOG)
echo "-----------------------------------------------------------"
