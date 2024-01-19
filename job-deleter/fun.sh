#!/bin/bash
###########
#   author: Bartlomiej Gorowski
###############################


truncate_whitespaces()
{
    local str=$(echo $1 | tr -d ' ')
    echo $str
}

result=`truncate_whitespaces "jeden               dwa  trzy   ."`
echo $result

test()
{
    local active_maxruns=0;
    
    ((active_maxruns++))
    ((active_maxruns++))

    echo $active_maxruns
}

test