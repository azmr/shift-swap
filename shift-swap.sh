#!/bin/bash

swap_braces=0
swap_numbers=0

while getopts ":bn" opt; do
	case $opt in
		b ) swap_braces=1;; 
		n ) swap_numbers=1;;
		\? ) echo "Invalid option: -$OPTARG" >&2; exit;;
	esac
done

# remove options from arg list
shift "$((OPTIND-1))"

keymap_file="$1"

if [ -z "$keymap_file" ]; then
	echo "No file provided. Exiting..." >&2
	exit
fi

echo "b: $swap_braces, n: $swap_numbers"

