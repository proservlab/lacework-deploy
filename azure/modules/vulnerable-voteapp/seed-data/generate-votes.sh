#!/bin/sh

# create 3000 votes (2000 for option a, 1000 for option b)
ab -n 1000 -c 50 -p posta -T "application/x-www-form-urlencoded" http://a336ba81c30ed4eef87ad622cac023fd-1389079655.us-east-1.elb.amazonaws.com:5000/
ab -n 1000 -c 50 -p postb -T "application/x-www-form-urlencoded" http://a336ba81c30ed4eef87ad622cac023fd-1389079655.us-east-1.elb.amazonaws.com:5000/
ab -n 1000 -c 50 -p posta -T "application/x-www-form-urlencoded" http://a336ba81c30ed4eef87ad622cac023fd-1389079655.us-east-1.elb.amazonaws.com:5000/
