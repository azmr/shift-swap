#!/bin/bash

help_text(){
	echo "SHIFT-SWAP:	Generates a keymap that swaps numbers/square brackets with their shifted counterparts"
	echo "		allowing you to use symbols and/or curly braces more easily"
	echo ""
	echo "USAGE:		shift-swap.sh -[bhn] KEYMAP_FILE"
	echo " 		Don't forget to load the generated map.gz file!"
	echo ""
	echo "EXAMPLES:	shift-swap.sh -b -n uk.map.gz"
	echo "		shift-swap.sh -bn uk.map.gz"
	echo "		shift-swap.sh -n us.map"
	echo ""
	echo "OPTIONS:	You must include at least one flag."
	echo ""
	echo "	-b	Braces - swap [] with \{} so that \{} is unshifted, [] is shifted."
	echo ""
	echo "	-h	Help - this text."
	echo ""
	echo "	-n	Numbers - swap numbers with symbols, so that symbols (e.g. $) are unshifted, numbers (e.g. 4) are shifted"
	echo ""
	exit
}

if [ "$1" == "--help" -o "$1" == "help" ]; then
	help_text
fi

swap_braces=0
swap_numbers=0

while getopts ":bhn" opt; do
	case $opt in
		b ) swap_braces=1;; 
		h ) help_text;;
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

old_keymap_file="$keymap_file"
keymap_filename=${keymap_file%????}

if [ "$swap_braces" -eq 1 ]; then
	keymap_filename=${keymap_filename}_b
	sed -r -e 's/([0-9]+) = (bracket.{4,5})( +)([a-z]+)/\1 = \4\3\2/' "$keymap_file" > "$keymap_filename.map"
	keymap_file="$keymap_filename.map"
	temp_map_files=("${temp_map_files[@]}" "$keymap_file")
	comment_message="# Swaps [] with \{}\n"
fi

if [ "$swap_numbers" -eq 1 ]; then
	keymap_filename=${keymap_filename}_n
	sed -r -e 's/([0-9]+) = (one|two|three|four|five|six|seven|eight|nine|zero)( +)([a-z]+)/\1 = \4\3\2/' "$keymap_file" > "$keymap_filename.map"
	keymap_file="$keymap_filename.map"
	temp_map_files=("${temp_map_files[@]}" "$keymap_file")
	comment_message="$comment_message# Swaps numbers with their corresponding symbols\n"
fi

sed_string="1 s/^.*$/\# $keymap_file\n$comment_message# Map adapted from $old_keymap_file using the script at https:\/\/github.com\/azmr\/shift-swap\n#\n# Original info:\n#/"
sed -r -e "$sed_string" "$keymap_file" > "$keymap_file.tmp"
mv $keymap_filename.map.tmp $keymap_filename.map

gzip -k "$keymap_filename.map"

# echo "temps: ${temp_map_files[@]}"

for temp in "${temp_map_files[@]}"; do
	rm "$temp"
done

