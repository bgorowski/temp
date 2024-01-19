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
INVALID_ARGUMENT_NUMBER=1
JOB_LIST_FILE_DOESNT_EXIST=2
INVALID_TASK_NAME=3
INVALID_JOB_NAMES=4


main()
{
    local argc=$#
    local argv=$@

    local job_list_file=$1
    local task_name=$2

    validate_input $argc $argv
    validate_input_result=$?

    if [ $validate_input_result != $OK ]; then
        return $validate_input_result;

    else
        check_jobs_status $job_list_file
        check_jobs_status_result=$?
        
        if [ $check_jobs_status_result != $OK ]; then
            return $check_jobs_status_result;
        else
            backup_job_definitions $job_list_file $task_name
            create_deletion_jil $job_list_file $task_name
        fi
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

check_jobs_status()
{
    local job_list_file=$1
    
    # https://techdocs.broadcom.com/us/en/ca-enterprise-software/intelligent-automation/autosys-workload-automation/12-0/reference/ae-system-states/status.html
    # arrays to hold job names with particular status
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

    echo -e "Checking jobs' status..."

    while read -r line || [ -n "$line" ];
    do 
        if [ "$line" != "" ]; then
            local jobname=$line
            echo -n "$jobname: " 
            local autostatus_output=$(./autostatus.sh)
            # local autostatus_output=$(autostatus -j ${jobname})
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
                    starting+=$jobnameINVALID_JOB_NAMES
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

    local nonexistent_jobs_number="${#doesnt_exist[@]}"
    local unsupported_jobs_number="${#unsupported[@]}"
    local running_jobs_number="${#running[@]}"
    local starting_jobs_number="${#starting[@]}"
    local restarting_jobs_number="${#restarting[@]}"

    if [[   $nonexistent_jobs_number != 0 || 
            $unsupported_jobs_number != 0 ||
            $running_jobs_number != 0 ||
            $starting_jobs_number != 0 ||
            $restarting_jobs_number != 0 ]]; then

        echo -e "Checking jobs' status ${RED}[ERROR]${NC} One or more jobs have status disabling them from deletion" 
        return $INVALID_JOB_NAMES   
    else
        echo -e "Checking jobs' status ${GREEN}[OK]${NC}"
        return $OK;
    fi
}

backup_job_definitions()
{
    local job_list_file=$1
    local task_name=$2
    
    echo "Creating backup JIL file with job definitions..."

    while read -r line || [ -n "$line" ];
    do 
        if [ "$line" != "" ]; then
            local jobname=$line
            echo -n "Creating backup of: ${jobname} "
            # command autorep -j "$jobname" -q >> "${task_name}_backup.jil"
            command ./autorep.sh >> "${task_name}_backup.jil"
            echo -e "${GREEN}[OK]${NC}"
        fi
    done < "$job_list_file"

    echo -e "Creating backup JIL file with job definitions ${GREEN}[OK]${NC}"
    echo "${task_name}_backup.jil file created"

    return $OK;
}

create_deletion_jil()
{
    local job_list_file=$1
    local task_name=$2

    while read -r line || [ -n "$line" ];
    do 
        if [ "$line" != "" ]; then
            local jobname=$line
            printf '%s %s\n' "delete_job:" "$jobname" >> "${task_name}_deletion.jil"   
        fi
    done < "$job_list_file"

    echo -e "Creating deletion JIL file ${GREEN}[OK]${NC}"
    echo "${task_name}_deletion.jil file created"

    return $OK;
}

main "$@"




