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