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
    local maxrun_time_dirty="07:23:41]"

    maxrun_time_dirty=${maxrun_time_dirty%?}

    echo $maxrun_time_dirty
}

test