# systemcheck
system health check for linux

- config file  : systemcheck.conf 
- execute file : systemcheck.sh 


Installation 
1. clone this proeject to your linux system 
2. change mode to execute of systemcheck.sh
  localhost ]# chmod o+x systemcheck.sh
3. change Log output directory and filename at systemcheck.conf
4. execute systemcheck script 
 localhost ]#./systemcheck.sh
 

Execution Parameter
Usage   : check_sys.sh [--save {filename}  |  --print]
Options : --save filename" will save log to filename
          --save " will save log to systemchk_{TODAY}.log
          --print" will print log on screen
          --help" show this help screen


Config Parameter 
\# OUPUT_DIR is define for directory of logfile.
\# default value is /tmp directory, you can chack to another directory if you need.
\# CAUTION : You should put full directory path with last slash(/)
\# ex)  /tmp/ , /var/log/system/
OUTPUT_DIR=/tmp/

\# OUTPUT_FILE is basename of result file.
\# default value is value of hostname command and current date format with Y-m-d
OUTPUT_FILE=`hostname`_$(date '+%Y-%m-%d').log


