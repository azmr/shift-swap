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

option_passed=0
swap_braces=0
swap_numbers=0

while getopts ":bhm:n" opt; do
	case $opt in
		b ) swap_braces=1;; 
		h ) help_text;;
		m ) mod_swap=1; mod_keys=$OPTARG;;
		n ) swap_numbers=1;;
		\? ) echo "Invalid option: -$OPTARG" >&2; exit;;
	esac
	option_passed=1
done

if [ "$option_passed" != 1 ]; then
	echo "No option passed. Exiting..."
	exit
fi

# remove options from arg list
shift "$((OPTIND-1))"

keymap_file="$1"

if [ -z "$keymap_file" ]; then
	echo "No file provided. Exiting..." >&2
	exit
fi

declare -a temp_map_files

if [[ $keymap_file == *.gz ]]; then
	gunzip -k $keymap_file			# unzip, but keep prev map file (-k)
	keymap_file=${keymap_file%???}	# remove last 3 characters
	temp_map_files=("${temp_map_files[@]}" "$keymap_file")
fi

old_keymap_file="$keymap_file"
keymap_filename=${keymap_file%????}
comment_message="# Changes:\n"

# deal with caps/ctrl/esc swaps
if [[ $mod_swap == 1 ]]; then
	# ensure 3 letters long
	if [[ ${#mod_keys} != 3 ]]; then
		echo "Error: must provide a 3 letter argument to option -m"
		exit
	fi

	# ensure letters match 'elc'
	if [[ $mod_keys =~ [elc]{3} ]]; then
		mod_arg_1=${mod_keys:0:1}
		mod_arg_2=${mod_keys:1:1}
		mod_arg_3=${mod_keys:2:1}
		
		mod_args=""
		for arg in $mod_arg_1 $mod_arg_2 $mod_arg_3; do
			case $arg in
				e ) mod_args=("${mod_args[@]}" "Escape");;
				l ) mod_args=("${mod_args[@]}" "Caps_Lock");;
				c ) mod_args=("${mod_args[@]}" "Control");;
			esac
		done

		keymap_filename="${keymap_filename}_$mod_keys"

		sed -r -e "s/(^keycode +[0-9]+ += +)(Escape)/\1aaaaaaaaaa/;
			s/(^keycode +[0-9]+ += +)(Caps_Lock)/\1bbbbbbbbbb/;
			s/(^keycode +[0-4][0-9]+ += +)(Control)/\1cccccccccc/;
			s/aaaaaaaaaa/${mod_args[1]}/;
			s/bbbbbbbbbb/${mod_args[2]}/;
			s/cccccccccc/${mod_args[3]}/" "$keymap_file" > "$keymap_filename.map"

		elc_message=""
		# TODO: make conditionals work
		if [[ ${mod_args[1]} != "Escape" ]]; then
			elc_message="$elc_message# Escape -> ${mod_args[1]}\n"
		fi
		if [[ ${mod_args[2]} != "Caps_Lock" ]]; then
			elc_message="$elc_message# Caps_Lock -> ${mod_args[2]}\n"
		fi
		if [[ ${mod_args[3]} != "Control" ]]; then
			elc_message="$elc_message# Control -> ${mod_args[3]}\n"
		fi

		comment_message="$comment_message$elc_message"
		keymap_file="$keymap_filename.map"
		temp_map_files=(${temp_map_files[@]} $keymap_file)
	else
		echo "Incorrect arguments for modifier swap: should be in the format 'elc'/'ecl'/'lec' etc..."
	fi
fi

# deal with brace swap
if [ "$swap_braces" -eq 1 ]; then
	keymap_filename=${keymap_filename}_b
	sed -r -e 's/([0-9]+) = (bracket.{4,5})( +)([a-z]+)/\1 = \4\3\2/' "$keymap_file" > "$keymap_filename.map"
	keymap_file="$keymap_filename.map"
	temp_map_files=("${temp_map_files[@]}" "$keymap_file")
	comment_message="$comment_message# Swaps [] with \{}\n"
fi

# deal with number/symbol swap
if [ "$swap_numbers" -eq 1 ]; then
	keymap_filename=${keymap_filename}_n
	sed -r -e 's/([0-9]+) = (one|two|three|four|five|six|seven|eight|nine|zero)( +)([a-z]+)/\1 = \4\3\2/' "$keymap_file" > "$keymap_filename.map"
	keymap_file="$keymap_filename.map"
	temp_map_files=("${temp_map_files[@]}" "$keymap_file")
	comment_message="$comment_message# Swaps numbers with their corresponding symbols\n"
fi

# add comment to beginning of file
sed_string="1 s/^.*$/\# $keymap_file\n$comment_message# Map adapted from $old_keymap_file using the script at https:\/\/github.com\/azmr\/shift-swap\n#\n# Original info:\n#/"
sed -r -e "$sed_string" "$keymap_file" > "$keymap_file.tmp"
mv $keymap_filename.map.tmp $keymap_filename.map

# rezip file
gzip -k "$keymap_filename.map"

for temp in "${temp_map_files[@]}"; do
	rm "$temp"
done

