#!/bin/bash

PREFIX="/usr/local/bin"

while [[ -n "$1" ]]; do
    case "$1" in
        -i|--install-prefix)
            shift
            PREFIX="$1"
            shift
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            echo "Unknown argument $1"
            exit 1
            ;;
    esac
    shift
done


if [[ ! -f "./remote_shutdown.sh" ]]; then
    echo "Script not found. Run the install script from the project root dir."
    exit 1
fi
if [[ ! -d "/usr/local/bin/" ]]; then
    echo "Installation directory does not exist."
    exit 1
fi

ln "./remote_shutdown.sh" "$PREFIX/remote_shutdown"

if [[ $? -ne 0 ]]; then
    echo "Install failed."
    exit 1
fi

echo "Script succesfully installed to $PREFIX/remote_shutdown."

