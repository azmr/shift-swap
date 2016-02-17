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

declare -a temp_map_files

if [[ $keymap_file == *.gz ]]; then
	gunzip -k $keymap_file			# unzip, but keep prev map file (-k)
	keymap_file=${keymap_file%???}	# remove last 3 characters
	temp_map_files=("${temp_map_files[@]}" "$keymap_file")
fi

keymap_filename=${keymap_file%????}

if [ "$swap_braces" -eq 1 ]; then
	keymap_filename=${keymap_filename}_b
	sed -r -e 's/([0-9]+) = (bracket.{4,5})( +)([a-z]+)/\1 = \4\3\2/' "$keymap_file" > "$keymap_filename.map"
	temp_map_files=("${temp_map_files[@]}" "$keymap_filename.map")
fi

if [ "$swap_numbers" -eq 1 ]; then
	keymap_filename=${keymap_filename}_n
	sed -r -e 's/([0-9]+) = (one|two|three|four|five|six|seven|eight|nine|zero)( +)([a-z]+)/\1 = \4\3\2/' "$keymap_file" > "$keymap_filename.map"
	temp_map_files=("${temp_map_files[@]}" "$keymap_filename.map")
fi

gzip -k "$keymap_filename.map"

echo "temps: ${temp_map_files[@]}"

for temp in "${temp_map_files[@]}"; do
	rm "$temp"
done

