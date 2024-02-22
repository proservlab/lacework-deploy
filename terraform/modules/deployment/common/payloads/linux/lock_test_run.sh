#!/bin/bash

TEST_SCRIPTNAME="test"
TEST_LOCKFILE="/tmp/lacework_deploy_$TEST_SCRIPTNAME.lock"
TEST_LOCKLOG=/tmp/lock_$TEST_SCRIPTNAME.log
TEST_SCRIPTLOG=/tmp/lacework_deploy_$TEST_SCRIPTNAME.log
TEST_PAYLOADFILE=/tmp/payload_$TEST_SCRIPTNAME
TEST_TESTSCRIPT="/tmp/lock_test.sh"

function cleanup_processes {
    echo "Termining any running test scripts..."
    kill -9 $(pgrep -f "\| tee $TEST_PAYLOADFILE \| base64 -d \| gunzip \| /bin/bash") 2>/dev/null || echo "No running processes found"
}

function cleanup_filesystem {
    echo "Removing previous run log files..."
    rm -rf "${TEST_SCRIPTLOG}*" "$TEST_LOCKFILE" "$TEST_LOCKLOG" "$TEST_PAYLOADFILE" 2>/dev/null || echo "No previous run log files found"
}

cleanup_processes
cleanup_filesystem

echo "Starting first run..."
nohup /bin/sh -c "echo -n \"$(cat $TEST_TESTSCRIPT | gzip | base64)\" | tee $TEST_PAYLOADFILE | base64 -d | gunzip | /bin/bash -" > /dev/null 2>&1 &
echo "First run started..."

while ! grep "LOCKCHECK: " $TEST_LOCKLOG 2> /dev/null; do
    echo "Waiting for lock log..."
    sleep 10
done

echo "TEST_LOCKLOG exists and LOCKCHECK FOUND"

if grep "No lock file and no running process found - creating lock file" $TEST_LOCKLOG; then
    echo "First run execution succeeded"
else
    echo "First run failed - exiting"
    exit 1
fi

truncate -s0 $TEST_LOCKLOG

sleep 30

echo "Starting second run..."
nohup /bin/sh -c "echo -n \"$(cat $TEST_TESTSCRIPT | gzip | base64)\" | tee $TEST_PAYLOADFILE | base64 -d | gunzip | /bin/bash -" > /dev/null 2>&1 &
echo "Second run started..."

while ! grep "LOCKCHECK: " $TEST_LOCKLOG 2> /dev/null; do
    echo "Waiting for lock log..."
    sleep 10
done

grep "LOCKCHECK: " $TEST_LOCKLOG
echo "TEST_LOCKLOG exists and LOCKCHECK FOUND"

if grep "Another instance of the script is already running. Exiting..." $TEST_LOCKLOG; then
    echo "Second run execution succeeded"
else
    echo "Second run failed - exiting"
    exit 1
fi

echo "Killing all process..."
kill -9 $(pgrep -f "\| tee $TEST_PAYLOADFILE \| base64 -d \| gunzip \| /bin/bash") > /dev/null 2>&1 || echo "No running processes found"

truncate -s0 $TEST_LOCKLOG

sleep 30

echo "Creating lock file..."
touch /tmp/lacework_deploy_$TEST_SCRIPTNAME.lock

echo "Starting third run..."
nohup /bin/sh -c "echo -n \"$(cat $TEST_TESTSCRIPT | gzip | base64)\" | tee $TEST_PAYLOADFILE | base64 -d | gunzip | /bin/bash -" > /dev/null 2>&1 &
echo "Third run started..."

while ! grep "LOCKCHECK: " $TEST_LOCKLOG 2> /dev/null; do
    echo "Waiting for lock log..."
    sleep 10
done

grep "LOCKCHECK: " $TEST_LOCKLOG
echo "TEST_LOCKLOG exists and LOCKCHECK FOUND"

sleep 30

if grep "Lock file with no running process found - updating lock file time and starting process" $TEST_LOCKLOG; then
    echo "Third run execution succeeded"
else
    echo "Third run failed - exiting"
    exit 1
fi

echo "Killing all process..."
kill -9 $(pgrep -f "\| tee $TEST_PAYLOADFILE \| base64 -d \| gunzip \| /bin/bash") > /dev/null 2>&1 || echo "No running processes found"

echo "Done."