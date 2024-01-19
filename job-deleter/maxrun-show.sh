#!/bin/bash
###########
#   author: Bartlomiej Gorowski
###############################

# bash text output color codes used in functions below
NC='\033[0m' # No Color
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'

# return codes
OK=0
ACTIVE_MAXRUN=0
NO_MAXRUN=1

INVALID_ARGUMENT_NUMBER=1
JOB_LIST_FILE_DOESNT_EXIST=2
INVALID_TASK_NAME=3
INVALID_JOB_NAMES=4


main()
{
    local argc=$#
    local argv=$@

    local date=$1

    # validate_input $argc $argv
    # validate_input_result=$?

    validate_input_result=$OK

    if [ $validate_input_result != $OK ]; then
        return $validate_input_result;

    else
        get_maxruns
    fi  
}

validate_input()
{
    local script_filename=$0
    local argc=$1
    local jobs_list_filename=$2
    local task_name=$3
    
    if [ $argc != 2 ]; then
        echo -e "${RED}[ERROR]${NC} Invalid argument number\n" >&2
        echo -e "${GREEN}USAGE:${NC}\n$script_filename file_with_job_names name_of_task\n" >&2
        echo -e "${GREEN}EXAMPLE:${NC}\n$script_filename peadl_to_be_deleted.txt SCTASK250325\n" >&2
        #echo -e "${DARK_GRAY}OUTPUT:${NC}\n"
        return $INVALID_ARGUMENT_NUMBER
    fi

    if ! [ -f "$jobs_list_filename" ]; then
        echo -e "${RED}[ERROR]${NC} File $jobs_list_filename doesn't exist" >&2
        return $JOB_LIST_FILE_DOESNT_EXIST
    fi

    if ! [[ "$task_name" =~ ^[0-9A-Za-z_\ -]+$ ]]; then
        echo -e "${RED}[ERROR]${NC} Invalid SCTASK name provided" >&2
        return $INVALID_TASK_NAME
    fi

    echo -e "Validating user input ${GREEN}[OK]${NC}"

    return $OK;
}

# grep -h "ALARM: MAXRUNALARM" $AUTOUSER/out/event_demon.$AUTOSERV | awk '{ print $9 }'

check_if_active_maxrun()
{
    local maxrun_start_time=$2
    local last_start_time=$3
    
    if [[ $maxrun_start_time = $last_start_time ]]; then
        return $ACTIVE_MAXRUN
    elif [[ $maxrun_time < $last_start_time ]]; then
        return $NO_MAXRUN
    fi
}

get_maxruns()
{   
    echo -e "\nChecking todays maxruns:\n"
    
    local todays_maxruns=$(grep -h "ALARM: MAXRUNALARM" ${AUTOUSER}/out/event_demon.${AUTOSERV} | awk '{ printf "%s\t%s\n",$2,$9 }')

    while IFS= read -r line
    do 
        local jobname=$(echo ${line} | awk '{ print $2 }')
        local maxrun_start_time=$(echo ${line} | awk '{ print $1 }')
        maxrun_start_time=${maxrun_start_time%?}
        local last_start_time=$(autorep -j ${jobname} | awk 'NR==4 { print $3 }')
        local job_status=$(autostatus -j ${jobname})

        if [[ "$job_status" == "RUNNING" ]]; then

            check_if_active_maxrun $maxrun_start_time $last_start_time
            local result=$?

            if [[ "$result" == $ACTIVE_MAXRUN ]]; then
                echo -e "${jobname}\t${GREEN}[ACTIVE MAXRUN]${NC}"
            else
                echo -e "${DARK_GRAY}${jobname}\t[RUNNING - NO MAXRUN]${NC}"
            fi

        else
            echo -e "${DARK_GRAY}${jobname}\t[${autostatus_output}]${NC}"
        fi

    done <<< "$todays_maxruns"

    return $OK;
}


main "$@"




