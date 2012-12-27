#!/bin/bash
# Azkaban Control script by DPathak dpathak74@gmail.com
#chkconfig: 3 80 20
#description: Azkaban Start/Stop/Status script
#Version 3.0.2
#Release date: 2011-10-18 2:15 PM, modified 2012-08-02 13:40
# Install:
        #vi azkaban into /etc/init.d
        #chmod a+rx azkaban
        #chkconfig --add azkaban
        #chkconfig --levels 345 azkaban on

# 
# To use this script
# run it as root - it will switch to the specified user or <unixUser> user can run it without sudo
# It loses all console output - use the log.
#

RUNAZ_VERSION=3.4.0.1
#Setting up hostname
HOSTNAME=`uname -n`

# Trap 
CNTRL_C_TRAP_SET=0;

### Local variables, users, directories, etc...
AZ_USER='<unixUser>'
USER=`whoami`
AZ_HOME="/usr/local/${USER}/azkaban-0.10.2"
AZ_TMP="${AZ_HOME}/tmp"
JAVA_HOME="/usr/java/jdk1.6.0_29"
export JAVA_HOME

if [[ `whoami` == "<unixUser>" ]] && [[ ! -e ${AZ_TMP} ]]; then
  mkdir ${AZ_TMP}
else
echo
fi


function show_vers() {
  echo
  echo runAzkaban.sh v$RUNAZ_VERSION maintainer: \<ss-tools\@streamsage.com\>
  echo
}

function show_errs() {
	echo "${txtred} Usage: $0 {start|stop|status} ${txtrst}"
        echo
        echo "${txtble}Please run script from ${txtred}${AZ_HOME}${txtrst}."
        echo
        echo "######################################################"
        echo " Example: cd ${AZ_HOME}"
        echo " then run ./bin/runAzkaban.sh"
        echo "######################################################"
	echo
}

# Text color variables
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow
txtble=$(tput setaf 4)    # Blue
txtwht=$(tput setaf 7)    # White
txtrst=$(tput sgr0)       # Text reset

#source for properties file.

function src_val () {
for p in 8081 8082 8083

	do

		if [[ ! -e ${AZ_HOME}/conf/az_${p}.cfg ]] & [[ ! -s ${AZ_HOME}/conf/az_${p}.cfg ]] ; then

			echo
			echo "${txtble}AZKABAN${txtrst} config file:${txtred}az_${p}.cfg${txtrst} not found or found empty...cannot proceed"
			echo
		exit 1;

		else


		source ${AZ_HOME}/conf/az_${p}.cfg

			if [ "${REX_ZOOKEEPER_HOSTS:-"ZK_HOST_REPLACE"}" = "ZK_HOST_REPLACE" -o "${REX_CONFIG_ENVIRONMENT:-"ENV_ID_REPLACE"}" = "ENV_ID_REPLACE" ];

		then
   				echo "Dependencies check failed in az_${p}.cfg, please update values: - REX_ZOOKEEPER_HOSTS/REX_CONFIG_ENVIRONMENT in ${AZ_HOME}/conf/az_${p}.cfg"

					if [ "${REX_ZOOKEEPER_HOSTS:-""}" = "" -o "${REX_CONFIG_ENVIRONMENT:-""}" = "" ] ; then

						echo
						echo "Variables loading failed from az_${p}.cfg please update REX_ZOOKEEPER_HOSTS and/or REX_CONFIG_ENVIRONMENT in az_${p}.cfg"

					exit 1;

					else

						echo 

						echo "Loaded values from az_${p}.cfg file"

						echo

				
   
					fi
				fi

			fi

done

}

function az_proc () {

	AZ_PID=$(/usr/sbin/lsof -i tcp:8081|awk '{print $2}'|tail -1) > /dev/null 2>&1
	AZ_PPID=$(ps -p $AZ_PID -o %P | sed -n 's/^ *\([0-9][0-9]*\) *$/\1/p') > /dev/null 2>&1

}


function get_port () {

portList="8081 8082 8083"

for port in ${portList}
	do
        	/usr/sbin/lsof -i tcp:${port} 2>&1 > /dev/null
                	if [ $? == 0 ] ; then
                        	echo "Port: $port is not available, getting next from approved list"
                	else
                        	echo "Port: $port is available to deploy"
                	fi
	done

}

function env_chk {

echo
echo "${txtble}Checking for environment variable.${txtrst}"

sleep 5
if [ $(id -u) = "0" ] && [ ${USER} != "<unixUser>" ]; then
        echo
        echo "AZKABAN startup is not allowed to run by ${txtred}root/superuser${txtrst}, please run as ${txtgrn}<unixUser>${txtrst} user"
        echo
    exit 1
fi

if [ ! -e "$JAVA_HOME" ]; then
        echo ${txtred}
        echo "################################################################################"
        echo
        echo "ERROR: JAVA_HOME is not set."
        echo "Download and install required Java version (you could run yum -y install ss-java) and properly set the JAVA_HOME environment variable before running."
        echo ${txtrst}
        exit
else
	echo
fi

        echo "${txtble}Environment variable test...${txtgrn}PASSED  ${txtble}("USER: ${USER}, JAVA_HOME: $JAVA_HOME, AZKABAN_HOME: $AZ_HOME") ${txtrst}"

}

status() {
        
	if [ $(id -u) = "0" ] && [ ${USER} != "<unixUser>" ]; then
        	echo
        	echo "AZKABAN startup is not allowed to run by ${txtred}root/superuser${txtrst}, please run as ${txtgrn}<unixUser>${txtrst} user"
        	echo
    		exit 1
	fi

	echo
	chk=`/usr/sbin/lsof -i tcp:8081-8083`
	if [ "$chk" == "" ] ; then
	echo 
	echo "*** ${txtble}AZKABAN${txtrst} is ${txtred}NOT${txtrst} running ***"
	echo
	exit 1
	else
	#az_proc
	echo "${txtble}AZKABAN ${txtred}status check in progress...Please ***WAIT***${txtrst}"
	sleep 5
	echo
	chk1=`/usr/sbin/lsof -i tcp:8081` 2>&1 > /dev/null
	echo
                if [[ $chk1 == "" ]]; then
                echo
                else
                echo
                pid_1=`/usr/sbin/lsof -i tcp:8081|awk '{print $2}'|tail -1`
		source ${AZ_HOME}/conf/az_8081.cfg
                echo "==================================================================================================================================================" ; echo -e "${txtred}\t\t\t\t\t\t\t\tAzkaban instance - 01${txtrst}" ; echo "==================================================================================================================================================";echo -e "${txtgrn}|USER|\t|PID|\t|JOB_DIR|\t\t\t\t\t|LOG_DIR|\t\t\t\t\t|ZK_HOST|\t\t|ENV_ID|${txtrst}" ; echo -e "${txtble}|<unixUser>|\t|${pid_1}|\t|${JOB_DIR}|\t|${LOG_DIR}|\t|${REX_ZOOKEEPER_HOSTS}|\t|${REX_CONFIG_ENVIRONMENT}|${txtrst}"

                fi

                chk2=`/usr/sbin/lsof -i tcp:8082` 2>&1 > /dev/null
		if [[ $chk2 == "" ]]; then
                echo
                else
                echo
                pid_2=`/usr/sbin/lsof -i tcp:8082|awk '{print $2}'|tail -1`
		source ${AZ_HOME}/conf/az_8082.cfg
		echo "==================================================================================================================================================" ; echo -e "${txtred}\t\t\t\t\t\t\t\tAzkaban instance - 02${txtrst}" ; echo "==================================================================================================================================================";echo -e "${txtgrn}|USER|\t|PID|\t|JOB_DIR|\t\t\t\t\t|LOG_DIR|\t\t\t\t\t|ZK_HOST|\t\t|ENV_ID|${txtrst}" ; echo -e "${txtble}|<unixUser>|\t|${pid_2}|\t|${JOB_DIR}|\t|${LOG_DIR}|\t|${REX_ZOOKEEPER_HOSTS}|\t|${REX_CONFIG_ENVIRONMENT}|${txtrst}"

                fi

        	chk3=`/usr/sbin/lsof -i tcp:8083` 2>&1 > /dev/null
                if [[ $chk3 == "" ]]; then
                echo
                else
                echo
                pid_3=`/usr/sbin/lsof -i tcp:8083|awk '{print $2}'|tail -1`
		source ${AZ_HOME}/conf/az_8083.cfg
		echo "==================================================================================================================================================" ; echo -e "${txtred}\t\t\t\t\t\t\t\tAzkaban instance - 03${txtrst}" ; echo "==================================================================================================================================================";echo -e "${txtgrn}|USER|\t|PID|\t|JOB_DIR|\t\t\t\t\t|LOG_DIR|\t\t\t\t\t|ZK_HOST|\t\t|ENV_ID|${txtrst}" ; echo -e "${txtble}|<unixUser>|\t|${pid_3}|\t|${JOB_DIR}|\t|${LOG_DIR}|\t|${REX_ZOOKEEPER_HOSTS}|\t|${REX_CONFIG_ENVIRONMENT}|${txtrst}"

		echo

                fi

        fi
}

#### Startup command function


PRGDIR=`dirname "$0"`

base_dir=$(dirname $0)/..

for file in $base_dir/lib/*.jar;
	do
  		CLASSPATH=$CLASSPATH:$file
	done

for file in $base_dir/dist/azkaban/jars/*.jar;

do
        CLASSPATH=$CLASSPATH:$file
done

for file in $base_dir/dist/azkaban-common/jars/*.jar;

do

        CLASSPATH=$CLASSPATH:$file

done

if [ -z $AZKABAN_OPTS ]; then

  	AZKABAN_OPTS="-Xmx2G -server -Dcom.sun.management.jmxremote"

fi


function startCmd() {

ZKH=`cat ${AZ_HOME}/conf/az_${PORT}.cfg|grep REX_ZOOKEEPER_HOST|sed 's,.*=,,'`
RCE=`cat ${AZ_HOME}/conf/az_${PORT}.cfg|grep REX_CONFIG_ENVIRONMENT|sed 's,.*=,,'`

export REX_ZOOKEEPER_HOSTS=$ZKH
export REX_CONFIG_ENVIRONMENT=$RCE

	java -Dlog4j.configuration=file://$AZ_HOME/azkaban/log4j.xml $AZKABAN_OPTS -cp $CLASSPATH azkaban.app.AzkabanApp --static-dir $base_dir/azkaban/web/static $@ --port ${PORT} --job-dir ${JOB_DIR} --log-dir ${LOG_DIR} --temp-dir ${TMP_DIR} > /dev/null 2>&1 &
        echo
        sleep 5
        echo

}


function createpidfile() {
  
	mypid=$1
 	pidfile=$2
 	#Close stderr, don't overwrite existing file, shove my pid in the lock file.
 	$(exec 2>&-; set -o noclobber; echo "$mypid" > "$pidfile") 
  
		[[ ! -f "$pidfile" ]] && exit #Lock file creation failed
			procpid=$(<"$pidfile")
  			[[ $mypid -ne $procpid ]] && {
    	#I'm not the pid in the lock file
    	# Is the process pid in the lockfile still running?
    			isrunning "$pidfile" || {
        # No.  Kill the pidfile and relaunch ourselves properly.
      
	rm "$pidfile"
      
	$0 $@ &
    
		}
    
		exit
  
	}
}

start() {
	

### Check ENV before starting.

env_chk;

src_val;

INSTANCE=0;

BASEDIR=$(pwd)

	echo
	echo -n "Please select ${txtble}INSTANCE${txtrst} to start, e.g.${txtgrn} 01, 02 or 03 :${txtrst}"
	echo
	read INSTANCE
if [[ ${INSTANCE} -ne "01" ]]  && [[ ${INSTANCE} -ne "02" ]] && [[ ${INSTANCE} -ne "03" ]] ; then
	echo "${txtred}$INSTANCE${txtble} is not allowed, please choose between ${txtgrn}01..03 :${txtrst}"
	exit 1
 else

	echo
	echo -n "Starting Azkaban."
	sleep 5
	echo
		
	if [[ ${INSTANCE} == "01" ]];  then
		
		if [ -f ${AZ_HOME}/tmp/8081.pid ]; then
			echo
			echo "${txtble}INSTANCE ${txtgrn}01 ${txtrst}is already running, please ${txtred}STOP${txtrst} before starting it, or pick next one."
			echo
			exit 1;
		else

			source ${AZ_HOME}/conf/az_8081.cfg
			startCmd
			mypidfile=${AZ_HOME}/tmp/8081.pid
			createpidfile $! "$mypidfile"
			echo
			echo "Azkaban INSTANCE:${txtgrn} 01 ${txtrst} *** STARTED *** on port:${txtble} 8081${txtrst}"
		        echo
			echo "${txtred} PLEASE run ${txtgrn} $0 status ${txtble} for instance details...${txtrst}"
			echo

		fi
			
	elif [[ ${INSTANCE} == "02" ]]; then

		if [ -f ${AZ_HOME}/tmp/8082.pid ]; then
			echo
			echo "${txtble}INSTANCE ${txtgrn}02 ${txtrst}is already running, please ${txtred}STOP${txtrst} before starting it, or pick next one."
			echo
                        exit 1;
                else

                        source ${AZ_HOME}/conf/az_8082.cfg
			startCmd
			mypidfile=${AZ_HOME}/tmp/8082.pid
                        createpidfile $! "$mypidfile"
                        echo
			echo "Azkaban INSTANCE:${txtgrn} 02 ${txtrst} *** STARTED *** on port:${txtble} 8082${txtrst}"
		        echo
			echo "${txtred} PLEASE run ${txtgrn} $0 status ${txtble} for instance details...${txtrst}"
			echo
		fi


	else 
		
		if [ -f ${AZ_HOME}/tmp/8083.pid ]; then
			echo
                        echo "${txtble}INSTANCE ${txtgrn}03 ${txtrst}is already running, please ${txtred}STOP${txtrst} before starting it, there are only 3 instances per server allowed."
                        echo
                        exit 1;
                else

			source ${AZ_HOME}/conf/az_8083.cfg
                        startCmd
			mypidfile=${AZ_HOME}/tmp/8083.pid
                        createpidfile $! "$mypidfile"
			echo
                        echo "Azkaban INSTANCE:${txtgrn} 03 ${txtrst} *** STARTED *** on port:${txtble} 8083${txtrst}"
		        echo
			echo "${txtred} PLEASE run ${txtgrn} $0 status ${txtble} for instance details...${txtrst}"
			echo
		fi

	fi

fi

}

function stop() {
                

	if [ $(id -u) = "0" ] && [ ${USER} != "<unixUser>" ]; then
        	echo
        	echo "AZKABAN startup is not allowed to run by ${txtred}root/superuser${txtrst}, please run as ${txtgrn}<unixUser>${txtrst} user"
       	 	echo
    		exit 1
	fi
		status 
		echo
		echo "${txtred} Select instance to ***shutdown***${txtrst}"
                echo
		echo -n "${txtble}Enter number to stop e.g. ${txtred}01${txtrst}:"
                read inst
		if [ "$inst" -eq "01" ]; then
			if [ ! -f ${AZ_HOME}/tmp/8081.pid ]; then
				echo 
				echo "${txtble}INSTANCE ${txtgrn}01 is ${txtred}NOT ${txtrst}running. Please use another instance to stop"
			else
				echo
				echo "${txtred}Stopping instance 01, Please ***WAIT***${txtrst}"
			sleep 5
        			rm -f ${AZ_HOME}/tmp/8081.pid
				rm -rf ${AZ_HOME}/logs/logs_8081/temp
				kill -HUP ${pid_1}
				echo
				echo
				echo "${txtble}INSTANCE ${txtgrn}01 ${txtred}Shutdown ${txtrst}completed..."
				echo
			fi
		elif [ "$inst" -eq "02" ]; then
			if [ ! -f ${AZ_HOME}/tmp/8082.pid ]; then
                        	echo 
                        	echo "${txtble}INSTANCE ${txtgrn}02 is ${txtred}NOT ${txtrst}running. Please use another instance to stop"
			else
				echo
                        	echo "${txtred}Stopping instance 02, Please ***WAIT***${txtrst}"
                	sleep 5
				rm -f ${AZ_HOME}/tmp/8082.pid
				rm -rf ${AZ_HOME}/logs/logs_8082/temp
                		kill -HUP ${pid_2}
                        	echo    
                        	echo
                        	echo "${txtble}INSTANCE ${txtgrn}02 ${txtred}Shutdown ${txtrst}completed..."
				echo
			fi

		elif  "$inst" -eq "03" ]; then
			if [ ! -f ${AZ_HOME}/tmp/8083.pid ]; then
                        	echo 
                        	echo "${txtble}INSTANCE ${txtgrn}03 is ${txtred}NOT ${txtrst}running. Please use another instance to stop"
			else
                        	echo
                        	echo "${txtred}Stopping instance 03, Please ***WAIT***${txtrst}"
                	sleep 5
				rm -f ${AZ_HOME}/tmp/8003.pid
				rm -rf ${AZ_HOME}/logs/logs_8083/temp
                		kill -HUP ${pid_3}
                        	echo    
                        	echo
                        	echo "${txtble}INSTANCE ${txtgrn}03 ${txtred}Shutdown ${txtrst}completed..."
                        	echo

			fi

		fi
}

function stopall () {

	status
	pid_1=`cat ${AZ_HOME}/tmp/8081.pid 2>&1`
	pid_2=`cat ${AZ_HOME}/tmp/8082.pid 2>&1`
	pid_3=`cat ${AZ_HOME}/tmp/8083.pid 2>&1`
	echo
	echo "################################################################################"
	echo "Status check completed...${txtred}Hard killing${txtble} any remaining threads ${txtgrn}***Please wait***."${txtrst}
	echo "################################################################################"
	echo
	sleep 7
	kill -9 ${pid_1} > /dev/null 2>&1
	kill -9 ${pid_2} > /dev/null 2>&1
	kill -9 ${pid_3} > /dev/null 2>&1
	rm -f ${AZ_HOME}/tmp/8081.pid ${AZ_HOME}/tmp/8082.pid ${AZ_HOME}/tmp/8083.pid > /dev/null 2>&1
        rm -rf ${AZ_HOME}/logs/logs_8081/temp ${AZ_HOME}/logs/logs_8082/temp ${AZ_HOME}/logs/logs_8083/temp > /dev/null 2>&1
	echo
	echo "${txtble}All instances shutdown completed...${txtrst}"
	echo
}

show_vers;
case "$1" in
  view)
    test=1;
    trap cntrl_c INT;
    while [ $test -eq 1 ]; do
      cntrl_c;
    done;
        ;;
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status
        ;;
  stopall)
        stopall
        ;;  

*)
	echo
	echo "${txtred} usage: $0 {start|stop|status|stopall} ${txtrst}"
	echo
esac

exit 0
