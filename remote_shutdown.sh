#!/bin/bash

PROGNAME=${0##*/}
VERSION="0.1"
LIBS=()  # Paths to external libraries.

HOST_NAME=0
HOST_ADDR=1
HOST_PWR=2

HOSTS=()
ALL=1
VERBOSE=0


function set_up(){
    parse_hosts
    return 0
}

function clean_up(){
    # Graceful exit clean up.
    return 0
}

function graceful_exit(){
    clean_up
    exit 1
}

function error_exit(){
    local error_msg="$1"
    printf "%s: %s\n" "$PROGNAME" "${error_msg:-"Unknown Error"}" >&2
    graceful_exit
}

function signal_exit(){
    local signal="$1"
    case "$signal" in
        INT)
            error_exit "Program interrupted by user."
            ;;
        TERM)
            error_exit "Program terminated."
            ;;
        *)
            error_exit "Program killed by unknown signal."
            ;;
    esac
}

function load_libs(){
    local i
    for i in $LIBS; do
        [[ -r "$i" ]] || error_exit "Library '$i' not found."
        source "$i" || error_exit "Failed to source library '$i'."
    done
    return 0
}

function usage(){
    printf "%s\n" "Usage: $PROGNAME [-h | --help]"
    printf "       %s\n" "$PROGNAME [options] args"
    return 0
}

function print_help(){
    cat <<- EOF
$PROGNAME ver. $VERSION
"program description"

$(usage)

Otions:
-h, --help          Display this help message.

EOF
    return 0
}

function parse_hosts(){
    HOSTS=($(cat "./hosts.txt"))
    if [[ ${#HOSTS[@]} -lt 0 ]]; then
        error_exit "ERROR: invalid hosts list."
        graceful_exit
    fi
    return 0
}

function shutdown_host(){
    local host_number="$1"
    host_number=$(( ($host_number-1)*3 ))
    if [[ $host_number -ge ${#HOSTS[@]} ]]; then
        echo "ERROR: invalid host number $(( host_number/3 ))"
        return 1
    fi
    if [[ $host_number -lt 0 ]]; then
        echo "ERROR: invalid host number 0"
        return 1
    fi
    local host_name=${HOSTS[$(( $host_number+$HOST_NAME ))]}
    local host_addr=${HOSTS[$(( $host_number+$HOST_ADDR ))]}
    echo "Shutting down $host_name@$host_addr..."
    if [[ $VERBOSE -eq 1 ]]; then
        ssh "$host_name@$host_addr"
    else
        ssh "$host_name@$host_addr" 2> /dev/null
    fi
    if [[ $? -ne 0 ]]; then
        echo "error"
        return 1
    fi
    echo "ok"
    return 0
}

function ask_confirmation(){
    local msg="$1"
    local msg_default="Are you sure? [Y/n]"
    if [[ -z "$msg" ]]; then
        msg="$msg_default"
    fi
    local answer=""
    while [[ 1 -eq 1 ]]; do
        echo "$msg" >&2
        read answer
        case "$answer" in
            y|Y|"")
                echo 1
                return 0
                ;;
            n|N)
                echo 0
                return 0
                ;;
            *)
                echo "Invalid option. Please answer \"y\" or \"n\"." >&2
                ;;
        esac
    done
}

trap "signal_exit TERM" TERM HUP
trap "signal_exit INT" INT

load_libs

set_up

while [[ -n "$1" ]]; do
    case "$1" in
        -h|--help)
            print_help
            graceful_exit
            ;;
        -v|--verbose)
            shift
            VERBOSE=1
            shift
            ;;
        -n|--host-number)
            shift
            HOST_NUMBER="$1"
            ALL=0
            shift
            ;;
        -*|--*)
            usage >&2
            error_exit "Unknown option $1"
            ;;
        *)
            usage >&2
            error_exit "Unknown argument $1"
            ;;
    esac
    shift
done

if [[ $ALL -eq 1 ]]; then
    n=$(( ${#HOSTS[@]}/3 ))
    confirm=$(ask_confirmation "Shutting down $n hosts. Confirm? [Y/n]")
    [[ $confirm -eq 0 ]] && graceful_exit
    for i in $(seq 1 $n); do
        shutdown_host $i
    done
else
    shutdown_host $HOST_NUMBER
fi

graceful_exit

