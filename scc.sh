#!/bin/bash
#Squid Cache Carve (SCC)

#Add ability to search?
#(r)ecurse
#(a) treat all as text
#(i)gnore case
#(l) file names only
#grep -rail <search_string> *

if [[ $# -eq 0 ]]; then
  echo "Enter the squid cache directory (usually /var/spool/squid/) followed by [ENTER]"
  read directory
else
  directory=$@
fi

mkdir -p out
file_prog=0
file_count=0
file_total=$(find $directory -type f | wc -l)

for file in $directory/*/*/*; do
    #hex the file, remove artificial newlines, count the \r\n\r\n
    if [ $(xxd -p $file | tr -d '\n' | grep 0d0a0d0a -c) == 1 ]; then
        #if the count is one, get the offset
        offset=$(($(xxd -p $file | tr -d '\n' | awk '{print match($0, "0d0a0d0a")}')/2))
        #split the header and body
        xxd -l $offset $file | xxd -r > out/header
        xxd -s $(($offset+4)) $file | xxd -r -s -$(($offset+4)) > out/body
        #if head header has a valid looking file name and extension, continue
        file_name_ext=$(strings out/header | grep -m 1 '://' | rev | cut -d '/' -f 1 | rev)
        if [[ $(echo $file_name_ext | grep '.' -c) == 1 ]] && [[ ${#file_name_ext} -le 254 ]] && [[ ${file_name_ext} != *"?"* ]]; then
            #make a folder for the domain
            domain=$(strings out/header | grep -m 1 '://' | cut -d '/' -f 3)
            mkdir -p out/$domain
            #move the file
            file_name=$(strings out/header | grep -m 1 '://' | rev | cut -d '/' -f 1 | rev | cut -d '.' -f1)
            #echo $file_name
            if [ -z "$file_name" ]; then
                file_name="empty"
            fi
            cp out/body out/$domain/$file_name
            ((file_count++))
            #handle extensions
            header_ext=$(strings out/header | grep -m 1 '://' | rev | cut -d'/' -f 1 | rev | cut -d '.' -f2)
            #echo $header_ext

            #if [ -z "$header_ext" ]; then
            #    header_ext="unknown"
            #fi
            body_ext=$(file --extension out/body | cut -d' ' -f 2)
            header_ext=${header_ext,,}
            body_ext=${body_ext,,}


            #check for bad

            #add sub-extension

            #write file extension
            mv "out/$domain/$file_name" "out/$domain/$file_name.$header_ext"
            #remove the temp files
            rm -f out/body
            rm -f out/header
        fi
    fi
    #update the status
    ((file_done++))
    echo -ne "  Working: $((${file_done}*100/${file_total})) %  \r"
done
#done message
echo -e "  Complete: 100 %\n  Files: $file_count"










    
    #if [ $(echo $body_type | grep ??? -c) == 1 ]; then
    #    body_type=$(file out/body | cut -d ' ' -f 2)
    #fi

    #!!!! if ascii, just give it the file extension, skip below step
    #!!!! alerts on executables, mismatches?, etc.

    

    #if [ $header_type == $body_type ]; then
        