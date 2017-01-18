#!/bin/bash

index=0

# Write alias of site into array from site.txt
while read line; do 
	aliasArray[$index]="$line"
	index=$(($index+1))
done < site.txt

# Get http response with status
for ((a=0; a < ${#aliasArray[*]}; a++)); do
    status=`curl --write-out %{http_code} --silent --output /dev/null ${aliasArray[$a]}`

    # Check status code
    if [ "$status" == "200" ]; then
    	echo "${aliasArray[$a]} - $status"
    	echo "OK!"
	else
		echo "${aliasArray[$a]} - $status"
	fi
done