#!/bin/bash
###########
#   author: Bartlomiej Gorowski
###############################

main()
{
    # global error return codes
    ok=0
    invalid_argument_number=1
    job_list_file_doesnt_exist=2
    invalid_task_name=3
    invalid_job_names=4

    local argc=$#
    local argv=$@

    local job_list_file=$1
    local task_name=$2

    validate_input $argc $argv
    validate_input_result=$?

    if [ $validate_input_result != $ok ]; then
        return $validate_input_result;
    else
        check_jobs_status $job_list_file
        check_jobs_status_result=$?
        
        if [ $check_jobs_status_result != $ok ]; then
            return $check_jobs_status_result;
        else
            backup_job_definitions $job_list_file $task_name
            create_deletion_jil $job_list_file $task_name
        fi
    fi  
}

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
        return $invalid_argument_number
    fi

    if ! [ -f "$jobs_list_filename" ]; then
        echo -e "${RED}[ERROR]${NC} File $jobs_list_filename doesn't exist" >&2
        return $job_list_file_doesnt_exist
    fi

    if ! [[ "$task_name" =~ ^[0-9A-Za-z_\ -]+$ ]]; then
        echo -e "${RED}[ERROR]${NC} Invalid SCTASK name provided" >&2
        return $invalid_task_name
    fi

    echo -e "Validating user input ${GREEN}[OK]${NC}"

    return $ok;
}

truncate_whitespaces()
{
    local str=$(echo $1 | tr -d ' ')
    echo $str
}

check_jobs_status()
{
    local job_list_file=$1
    
    # arrays to hold job names with that status
    local activated=()
    local failure=()
    local inactive=()
    local pend_mach=()
    local on_hold=()
    local on_ice=()
    local on_noexec=()
    local que_wait=()
    local restart=()
    local reswait=()
    local running=()
    local starting=()
    local success=()
    local suspended=()
    local terminated=()
    local wait_reply=()
    local doesnt_exist=()
    local unsupported=()

    echo -e "Checking jobs' status ${DARK_GRAY}[IN PROGRESS]${NC}\n"

    while read -r line || [ -n "$line" ];
    do 
        if [ "$line" != "" ]; then
            local jobname=`truncate_whitespaces "$line"`
            echo -n "$jobname: " 
            local autostatus_output=$(./autostatus.sh)
            if [[ "$autostatus_output" == *"Invalid job/box name:"* ]]; then
                job_status="DOESNT_EXIST" 
            else
                job_status=$autostatus_output
            fi

            case $job_status in 
                ACTIVATED)
                    activated+=$jobname
                    ;;
                FAILURE)
                    failure+=$jobname
                    ;;
                INACTIVE)
                    inactive+=$jobname
                    ;;
                PEND_MACH)
                    pend_mach+=$jobname
                    ;;
                ON_HOLD)
                    on_hold+=$jobname
                    ;;
                ON_ICE)
                    on_ice+=$jobname
                    ;;
                ON_NOEXEC)  
                    on_noexec+=$jobname
                    ;;
                QUE_WAIT)
                    que_wait+=$jobname
                    ;;
                RESTART)
                    restart+=$jobname
                    ;;
                RESWAIT)
                    reswait+=$jobname
                    ;;
                RUNNING)
                    running+=$jobname
                    ;;
                STARTING)
                    starting+=$jobname
                    ;;
                SUCCESS)
                    success+=$jobname
                    ;;
                SUSPENDED)
                    suspended+=$jobname
                    ;;
                TERMINATED)
                    terminated+=$jobname
                    ;;
                WAIT_REPLY)
                    wait_reply+=$jobname
                    ;;
                DOESNT_EXIST)
                    doesnt_exist+=$jobname
                    ;;
                *)
                    unsupported+=$jobname

                    echo -e "${RED}[ERROR]${NC} - unsupported job status returned." \
                            "Check Autosys version in use." \
                            "This script is compatible with Autosys v.12"
                    ;;
            esac

            echo "$job_status"
        fi
    done < "$job_list_file"

    echo ""

    local nonexistent_jobs_number="${#doesnt_exist[@]}"
    local unsupported_jobs_number="${#unsupported[@]}"
    local running_jobs_number="${#running[@]}"
    local starting_jobs_number="${#starting[@]}"
    local restarting_jobs_number="${#restarting[@]}"

    if [[ $nonexistent_jobs_number != 0 || $unsupported_jobs_number != 0 || $running_jobs_number != 0 || $starting_jobs_number != 0 || $restarting_jobs_number != 0 ]]; then
        echo -e "Checking jobs' status ${RED}[ERROR]${NC} One or more jobs have status disabling them from deletion" 
        return $invalid_job_names   
    else
        echo -e "Checking jobs' status ${GREEN}[OK]${NC}"
        return $ok;
    fi
}

backup_job_definitions()
{
    local job_list_file=$1
    local task_name=$2
     
    while read -r line || [ -n "$line" ];
    do 
        if [ "$line" != "" ]; then
            printf '%s %s\n' "delete_job:" "$line" >> "$task_name"
        fi

    done < "$job_list_file"
}

create_deletion_jil()
{
    local job_list_file=$1
    local task_name=$2

    while read -r line || [ -n "$line" ];
    do 
        if [ "$line" != "" ]; then
            printf '%s %s\n' "delete_job:" "$line" >> "${task_name}_added"
        fi

    done < "$job_list_file"
}

main "$@"




