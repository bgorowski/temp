#!/bin/bash

job_status=("KURWISZON" "ACTIVATED" "FAILURE" "INACTIVE" "PEND_MACH" "ON_HOLD" "ON_ICE" "ON_NOEXEC" "QUE_WAIT" "RESTART" "RESWAIT" "RUNNING" "STARTING" "SUCCESS" "SUSPENDED" "TERMINATED" "WAIT_REPLY" "CAUAJM_E_50004 Invalid job/box name: jobname")

echo ${job_status[RANDOM%${#job_status[@]}]}