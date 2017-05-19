#!/bin/sh

##############################
## To do 
## 1. make exception when has no lsb_release in kdumpchk
##############################

HOSTNAME=`hostname`
UNAME=`uname`  
if [ ${UNAME}  == "Linux" ]
then
	SYSLOG="/var/log/messages"
else  
	SYSLOG="/var/log/messages" 
fi   

RHELID="RedHatEnterpriseServer"
UBUNTUID="Ubuntu"
DEBIANID="Debian"
CENTOSID="CentOS" 
ORACOSID="OracleServer"
SUSEID="openSUSEproject"

# Default Variables
OUTPUT_DIR=`pwd`
OUTPUT_FILE=`hostname`_$(date '+%Y-%m-%d')

#echo $OUTPUT_DIR
#echo $OUTPUT_FILE 


line() 
{ 
 	eval printf %.0s\= '{1..'${COLUMNS:-$(tput cols)}'}'; echo    
 	#eval printf %.0s\= '{1..'${COLUMNS:-80}'}'; echo    
} 

section()
{ 
	line 
    printf "%*s\n" $(((${#1}+$(tput cols))/2)) "$1" 
    #printf "%*s\n" $(((${#1}+80)/2)) "$1" 
	line 
} 

checkenv()
{ 
	echo "CHECK ENVIRONMENT"
	#echo "1. Check config file" 
	checkconf 
	#echo "2. Check output directory / file"  
	#checkoutputdir	
	echo "3. Check require command"	  
	cmdset=( "hostname" "uname" "date" "awk" "crontab" "ifconfig" "route" "netstat" "df" "cat" "mount" "mpstat" "mktemp" "ps" "sort" "free" "vmstat" "swapon" "iostat" "lsb_release" "dmidecode"  ) 
	for cmd in "${cmdset[@]}"  
	do  
		checkcmd $cmd
	done
} 

checkconf()
{  
	CONF_FILE="./systemcheck.conf"
	if [ -f $CONF_FILE ]; then
		result="ok"
		source $CONF_FILE   
	else 
		result="fail"
	fi 
	echo "CONFIG FILE : $CONF_FILE ---------------------- [${result}]"
	
}

checkoutputdir()
{ 
	if [ -d $OUTPUT_DIR ]; then  
		result="ok"
	else
		result="fail"
	fi 
	echo "OUTPUT DIR : $OUTPUT_DIR  ---------------------- [${result}]"  
	#echo "!!! LOG FILE PATH : ${OUTPUT_DIR}${OUTPUT_FILE}"  

	touch ${OUTPUT_DIR}${OUTPUT_FILE}
	if [ -f ${OUTPUT_DIR}${OUTPUT_FILE} ]; then    
		result="ok"
	else 
		result="fail" 
		exit;
	fi  
 
	echo "!!! LOG FILE PATH : ${OUTPUT_DIR}${OUTPUT_FILE} -------------- [${result}]"  
	
}
checkcmd()
{ 
	if [ -x "$(command -v ${1})" ] ; then     
		result="ok" 
	else 
		result="fail" 
	fi   
	echo ${1} ------------------------------ [${result}]
}	
title()
{    
    eval printf %.0s\# '{1..'${COLUMNS:-$(tput cols)}'}'; echo    
    echo -e "" 
    ##printf "%*s\n" $(((${#TITLE}+$(tput cols))/2)) "$TITLE"
    section "CHLUX LINUX SERVER STATUS CHECK"
    echo -e "#### Version    : 0.5.1" 
    echo -e "#### Author     : Chlux Co,Ltd."
    echo -e "#### Release    : 04. Apr. 2017" 
    echo -e "#### Package    : CHLUX SERVER SUITE"
    echo -e "#### Require    : Root Permission"
    echo -e "#### copyright  : 2017, All rights reserved Chlux Co,Ltd."
    echo -e ""
    eval printf %.0s\# '{1..'${COLUMNS:-$(tput cols)}'}'; echo  
}

cur_date()
{ 
	echo `date`
} 

sysinfo()
{  
	echo "HOSTNAME   : " `hostname`  
	echo "CHECK DATE : " `date`  
	echo "SYSTEM     : " `uname -a`
	
} 
 
pmcheck()
{ 
	PMDATE=180
	UPTIME=`awk '{print int($1)}' /proc/uptime`  
	PMTIME=$((UPTIME / 86400)) 
	line
	echo 'UPTIME SINCE LAST REBOOT : ' $((${PMTIME}-${PMDATE})) 'days'
} 

croninfo()
{ 
	#CRONLINE=`crontab -l`
	section 'Crontab list'
	echo `for user in $(grep /bin/bash /etc/passwd | cut -f1 -d:); do crontab -u $user -l; done` 
	echo 'tab content check'

} 

kernelchk()
{ 
	line
	echo 'Kernel version : '`uname -o -r -v` 
} 

networkchk()
{  
	section 'Network Interface check' 
 	ifconfig 
}  

routechk()
{ 
	section 'Default route'
	route
}
 
protocolinfo()
{ 
	section 'Protocol statistics'
	 netstat -s
} 

fsinfo()
{ 
	section 'File system information (human readable)' 
	df -h 
	section 'File system information (Inode)' 
	df -i
	section 'Swap information' 
	swapon -s
}  

diskinfo()
{ 
	section "/etc/fstab entry"
	cat /etc/fstab
	section "Mounted disk"
	mount -l
} 

basicchk()
{     
	sysinfo
	runcmd pmcheck 
	runcmd kernelchk 
	runcmd kdumpchk
	runcmd croninfo
	runcmd networkchk	
	runcmd routechk
	runcmd protocolinfo 
	runcmd diskinfo
	runcmd fsinfo 
} 


cpuusage()
{ 
	section "CPU Usage"  
	index=0	 

	if [ -x "$(command -v mpstat)" ] ; then     
		mpstat -P ALL > ./cpu.txt  
	else  
		top -bH -n 1 | head -5
	fi

	while read line; do 
		if [ $index -gt 1 ]; then  
			echo "$line"
		fi
		index=$(($index+1)) 
	done < ./cpu.txt

    if [ -x "$(command -v mpstat)" ] ; then     
        section "CPU Idle alert"
        idle_limit=10.0
        cpu_idle=$(mpstat 1 5 | tail -n 1 | awk '{print $NF}') 
        is_alert=$(echo "$cpu_idle < $idle_limit" | bc) 

        if [ ${is_alert} -eq 1 ]; then 
            date_str=$(date '+%Y/%m/%d %H:%M:%S') 
	    echo "[$date_str] CPU %idle Alert : $cpu_idle (%)"
         else  
            echo "No Alert"
         fi 
         rm ./cpu.txt 
    fi 
} 

#memoryusage()
#{  
#	section "Memory Usage"
#	TOTAL=`free | grep ^Mem | awk '{print $2}'`
#	USED1=`free | grep ^Mem | awk '{print $3}'`
#	USED2=`free | grep ^-/+ | awk '{print $3}'`
#	NOMINAL=$((100*USED1/TOTAL))
#	ACTUAL=$((100*USED2/TOTAL))
#	echo NOMINAL=${NOMINAL}% ACTUAL=${ACTUAL}% 
#}


memoryusage()
{ 
	section "Memeory Usage"
	tmpfile=`mktemp /tmp/pslist_XXXXXX.tmp`
	#echo $tmpfile 
	ps aux --sort=-pmem > $tmpfile
	if [ ! -f $tmpfile ]; then   
		echo "No process file : "$tmpfile
		exit
	fi 
	declare VSS=0
	declare RSS=0
	
	while read line
	do
		VSS=$(($VSS + $(echo $line | awk '{print $5}')))
		RSS=$(($RSS + $(echo $line | awk '{print $6}')))

	done < $tmpfile

	echo Total Reserved Memory   : "$VSS" KiB
	echo Total Real Using Memory : "$RSS" KiB 
}

memorystatus()
{
	section "Process and Memory status"
	cat  $tmpfile

	section 'Free Memory Check'
	free -k
	
	section 'Swap status' 
	swapon -s 

	section "vmstat -d -S kb" 
	vmstat -d -Sm
}
swapstatus()
{ 
	section "Swap Usage Status" 
	ps ax -o pid,args | grep -v '^  PID'|sed -e 's,^ *,,' > ./ps_ax.output
	echo -n > ./check_swap.output

	for swappid in $(grep -l Swap /proc/[1-9]*/smaps ); do
        	swapusage=0
        	for x in $( grep Swap $swappid 2>/dev/null |grep -v '\W0 kB'|awk '{print $2}' ); do
                	let swapusage+=$x
        	done
        	pid=$(echo $swappid| cut -d' ' -f3|cut -d'/' -f3)
        	if ( [ $swapusage -ne 0 ] ); then
                	echo -ne "$swapusage kb\t\t" >>/tmp/results
                	egrep "^$pid " ./ps_ax.output |sed -e 's,^[0-9]* ,,' >>./check_swap.output
        	fi
	done

	echo "Top 10 swap using processes which are still running:"
	sort -nr ./check_swap.output | head -n 10 
	rm -rf ./ps_ax.output
	rm -rf ./check_swap.output
}
iostatus()
{ 
	section "iostate"

	index=0
	iostat ALL  > ./ios.txt

	while read line; do 
		if [ $index -gt 1 ]; then  
			echo "$line"
		fi
		index=$(($index+1)) 
	done < ./ios.txt 

	rm -rf ./ios.txt

} 

#vmstatchk()
#{ 
#	section "vmstat -d -S kb" 
#	vmstat -d -Sm
#}
lastchk()
{ 
	section "Last log"
	td=`date +"%a %b %e"`
	echo $td 
	last | grep -i "$td" 
}  

pschk()
{ 
	section "Process status tree"
	pstree
} 

errorchk()
{  
	section "${SYSLOG} error check"
	`cat ${SYSLOG} | grep -i '(fail|error|warn)'`
} 

kdumpchk()
{ 
	#cat /proc/cmdline 
	
	section "Kernel dump check"	
	if dmesg | grep -q "EFI v" ; then 
		mode="efi"	  
		grubconfsuffix="-efi"
	else
		mode="bios" 
		grubconfsuffix=""
	fi 

	if [ -x /usr/bin/lsb_release ]; then
		OSID=`/usr/bin/lsb_release -i` 
		OSRELEASE=`/usr/bin/lsb_release -r`  
		OSID=${OSID:16}  
		OSID=${OSID// /}

		case $OSID in  
			${RHELID} | ${CENTOSID} | ${ORACOSID})    
				#OS=${RHELID} 
				RN=${OSRELEASE##Release:}
				#echo ${RN:1:1} 

				case ${RN:1:1} in  
					6) 
						#grubcfg="/etc/grub/grub.conf" 
						grubcfg="/etc/grub"${grubconfsuffix}".conf" 
						statuschk=`service kdump status`
						;;
					7)
						grubcfg="/etc/grub2"${grubconfsuffix}".cfg"
						statuschk=`systemctl status kdump | grep Active`
					;;
					*)	
					echo ${RN} "NOT support Yet "
					;;
				esac 

			;;
			${DEBIANID})
				OS=${DEBIANID} 
				echo $OS
				echo "NOT support Yet "
			;;
			${UBUNTUID})
				OS=${UBUNTUID}
				echo $OS
				echo "NOT support Yet "
			;;
			"${SUSEID}")
				OS=${SUSEID}  
				RN=${OSRELEASE##Release:}
				case ${RN:1:2} in  
					12)
						grubcfg="/boot/grub2/grub"${grubconfsuffix}".cfg"
						statuschk=`systemctl status kdump | grep Active`
					;;
					*)	
					echo ${RN} "NOT support Yet "
					;;
				esac 
			;;  
			*) 
				echo "N/A" 
			;;
		esac

		if grep -q crashkernel "${grubcfg}" ; then  
			BOOTSET="Enable"
		else 
			BOOTSET="Disable"
		fi	   

		echo "KDUMP set in grub menu           : "${BOOTSET}
		echo "Grub parameter                   : "`grep 'crashkernel' ${grubcfg}`

		if grep -q crashkernel /proc/cmdline ; then  
			KDUMPSET="Enable"
		else 
			KDUMPSET="Disable"
		fi	  
		echo ""
		echo "KDUMP set in current boot kernel : "${KDUMPSET}
		echo "Current boot parameter           : "`cat /proc/cmdline` 
	
		echo ""
		echo "KDUMP operation status           : "${statuschk}
	
	else 
		echo "Please install lsb_release package"
	fi 

}

zombiechk()
{  
	section "Zombie process check"
	#cat /proc/*/status | grep Status | grep D 
	#cat /proc/*/status | grep Status | grep Z
	#cat /proc/*/status | grep Status | grep T  

	NOZ=`ps -ef | grep defunct | grep -v grep | wc -l `
	echo "Number of Zombie : " ${NOZ} 
	if [ ${NOZ} -gt 0 ]; then  
		section "Zombie process list"
		ps -ef | grep defunct | grep -v grep	
	fi 
} 

dimdecodechk()
{ 
	section "Dmidecode check"
	dmidecode
}

usagechk()
{  
	runcmd cpuusage
	runcmd memoryusage
	runcmd memorystatus
	runcmd swapstatus
	runcmd iostatus
	runcmd pschk  
	runcmd zombiechk
	runcmd lastchk 
	runcmd errorchk  
	runcmd dimdecodechk
} 

runcmd()
{ 
	#echo ${1} "(${!1})" 
	#echo "${1} ---------------------- [${!1}]"
	if [ "on" == ${!1} ]; then 
		${1}  
	fi
}


usage()
{ 
	echo "Usage   : check_sys.sh [--save {filename}  |  --print] " 
	echo "Options : \-s, --save filename will save log to filenam define from config"
	echo "          \-p, --print will print log on screen"
	echo "          \-h, --help show this help screen"
}

if [ "$#" -lt 1 ]; then  
	usage
else
	case $1 in  
		"--save" | "-s") 
			clear   
			checkenv 
			checkoutputdir
			if [ -z $2 ]; then   
				#filedate=`date +"%Y%m%d-%H%M%S"`
				#file=${HOSTNAME}'_'${filedate}'.log'  
				file=${OUTPUT_DIR}${OUTPUT_FILE}
			elif [ -f $2 ]; then
				usage
				echo "Already exists "$2		
			else  
				file=$2	 
			fi 
			
			title > ${file} 2>&1
			basicchk >> ${file} 2>&1
			usagechk >> ${file} 2>&1  
			line
			echo "FINISH"
		;; 
		"--print" | "-p")  
			clear
			checkenv
			title
			basicchk 
			usagechk 
		;; 
		"--help" | "-h" ) 
			usage 
			exit
		;;
	esac  
fi 
