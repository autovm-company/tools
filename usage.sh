#!/bin/sh

# FIND NAME
function findName {

    name=$(echo "$1" | grep name | cut -d '"' -f 2)

    echo "$name"
}

# FIND MEMORY USAGE
function findMemoryUsage {

    memoryUsage=$(echo "$1" | grep guestMemoryUsage | grep -Eo [0-9]+)

    # CONVERT TO KB
    memoryUsage=$(($memoryUsage*1024))

    echo "$memoryUsage"
}

# FIND CPU USAGE
function findCpuUsage {

    cpuUsage=$(echo "$1" | grep overallCpuUsage | grep -Eo [0-9]+)

    echo "$cpuUsage"
}

# FIND DISK USAGE
function findDiskUsage {

    diskUsage=$(echo "$1" | grep committed | grep -Eo [0-9]+ | head -n 1)

    echo "$diskUsage"
}

# FIND BANDWIDTH USAGE
function findBandwidthUsage {

    # NAME WITHOUT SPACE
    name=$(echo "$1" | sed 's/ /_/g')

    # FIND WORLD
    world=$(esxcli network vm list | grep "\s$name\s" | grep -Eo [0-9]+ | head -n 1)

    # FIND BANDWIDTH
    bandwidth=$(esxcli network vm port list -w "$world" | head -n 1 | grep -Eo [0-9]+ | xargs esxcli network port stats get -p | grep Bytes | grep -Eo [0-9]+)

    echo "$bandwidth"
}

# SEND USAGE
function sendUsage {

    # FIND IDENTITY
    identity=$(echo "$1" | grep -Eo [0-9]+ | head -n 1)

    # MACHINE SUMMARY
    summary=$(vim-cmd vmsvc/get.summary "$identity")

    # FIND NAME
    name=$(findName "$summary" "$identity")

    # FIND MEMORY USAGE
    memory=$(findMemoryUsage "$summary" "$identity")

    # FIND CPU USAGE
    cpu=$(findCpuUsage "$summary" "$identity")

    # FIND DISK USAGE
    disk=$(findDiskUsage "$summary" "$identity")

    # FIND BANDWIDTH
    bandwidth=$(findBandwidthUsage "$name")

    # FIND RECIEVED
    recieved=$(echo "$bandwidth" | sed -n 1p)

    # FIND SENT
    sent=$(echo "$bandwidth" | sed -n 2p)

    # REQUEST PARAMS
    params="name=$name&memory=$memory&cpu=$cpu&disk=$disk&recieved=$recieved&sent=$sent"

    # REQUEST ADDRESS
    address="$2/candy/backend/hook/machine/usage"

    # REQUEST TOKEN
    token="token: $3"

    # SEND REQUEST
    wget -O usage.log "$address" --post-data "$params" --header "$token"
}

# INFINITE LOOP
while true; do

    # SLEEP SECONDS
    sleep 600

    # FIND ALL MACHINES
    machines=$(vim-cmd vmsvc/getallvms)

    # ONE BY ONE
    echo "$machines" | while read machine; do

        # SEND USAGE
        sendUsage "$machine" "$1" "$2"

        # SLEEP SECONDS
        sleep 10
    done
done
