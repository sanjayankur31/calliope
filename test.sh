#!/bin/bash

# Copyright 2021 Ankur Sinha
# Author: Ankur Sinha <sanjay DOT ankur AT gmail DOT com> 
# File : test.sh
#
# Test script to test basic calliope functionality

# The latest (and only entry)
year=$(date +%G)
diary_dir="diary"
current_folder="$(pwd)"

echo "Creating new file for today"
# Delete diary if it exists
rm -rf "$diary_dir/$year/"
./calliope.sh -t || exit -1

latest_diary_entry=$(ls $diary_dir/$year/$year*tex | tail -1)

# Add a section title
sed -i "s/section{}/section{Test}/" "$latest_diary_entry" || exit -1

# Add lipsum package, and lipsum text
sed -i '/^\\usepackage/a \\\usepackage{lipsum}' "templates/research_diary.sty" || exit -1
sed -i '/^\\section/a \\\lipsum{}' "$latest_diary_entry" || exit -1

# Add a test citation
sed -i "s|addbibresource{.*}|addbibresource{$current_folder/testbib.bib}|" "templates/research_diary.sty" || exit -1
sed -i '/^\\printbibliography/i \\\cite{Test2017}' "$latest_diary_entry" || exit -1


# Compile entry
echo "Compiling entry"
./calliope.sh -l || exit -1

echo "Compiling anthology"
./calliope.sh -a $(date +%Y) || exit -1
