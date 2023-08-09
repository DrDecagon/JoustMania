#!/bin/bash

#this is for development purposes only, to stop the automattically
#running piparty scripts
sudo supervisorctl stop joustmania
sudo kill $(ps aux | grep 'piparty' | awk '{print $2}')
sleep 2
sudo kill -9 $(ps aux | grep 'piparty' | awk '{print $2}')