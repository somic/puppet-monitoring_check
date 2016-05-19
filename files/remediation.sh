#!/bin/bash

# Takes a check command, and an action command
# If the action doesn't return a 0, the action is run and the output is returned

RETRIES=1
echo $1
while getopts "n:c:a:r:" arg; do
  case $arg in
  n)
    # The name of the check we're running
    NAME=$OPTARG
    ;;
  c)
    # The check that we're running
    CHECK=$OPTARG
    ;;
  a)
    # The action to take in the case of a non 0 exit
    ACTION=$OPTARG
    ;;
  r)
    # Number of times to retry the action
    RETRIES=$OPTARG
    ;;
  esac
done

CHECK_OUTPUT=$($CHECK)
CHECK_EXITCODE=$?
if [ $CHECK_EXITCODE -eq 2 ]; then
# The check failed. Lets try remediation
  if [ -f "/tmp/$NAME" ]; then
    # We've tried this before. Let's see if we have retries left
    ATTEMPTS=`cat /tmp/$NAME`
    if [ $ATTEMPTS -ge $RETRIES ]; then
      CHECK_EXITCODE=2
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    `echo $ATTEMPTS > /tmp/$NAME`
  else
    ACTION_OUTPUT=$($ACTION)
    ACTION_EXITCODE=$?
    ATTEMPTS=0
    if [ $RETRIES -eq 0 ]; then
      # We should alert if we don't want to retry
      # This case is when we want the remediation action output after 1 failed
      CHECK_EXITCODE=2
    else
      CHECK_EXITCODE=0
    fi

    `echo 1 > /tmp/$NAME`

   fi
  CHECK_OUTPUT="$CHECK \n \n$CHECK_OUTPUT \n \nAction Command: $ACTION \n \nRetry Attempt: $ATTEMPTS\n \n \n$ACTION_OUTPUT"
else
  # The check has succeeded. Let's clean up
  if [ -f /tmp/$NAME ]; then
    `rm /tmp/$NAME`
  fi
fi

echo -e "$CHECK_OUTPUT"
exit $CHECK_EXITCODE
