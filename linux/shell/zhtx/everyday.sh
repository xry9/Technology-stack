#!bin/bash
log=/home/fengkai/test/every.txt
exec 1>>$log
exec 2>>$log
bash -x /home/fengkai/shell/one/wc.sh
