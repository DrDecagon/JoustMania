#!/bin/bash

#this is for development purposes only, to stop the automattically
#running piparty scripts
sudo supervisorctl stop joustmania
sudo kill -TERM $(ps aux | grep 'piparty' | awk '{print $2}')
sleep 1
sudo kill -QUIT $(ps aux | grep 'piparty' | awk '{print $2}')
