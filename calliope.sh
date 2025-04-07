#!/bin/bash

SHORT_DESC="Journaling using LaTeX and git"
UPSTREAM_URL="https://github.com/sanjayankur31/calliope"
VERSION=1.2.7
MY_EDITOR="vimx --servername $(pwgen 8 1)"
MY_VIEWER="xdg-open"
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
timestamp=$(date +%Y%m%d%H%M%S)
diary_dir="diary"
pdf_dir="pdfs"
todays_entry="$year-$month-$day.tex"
latest_diary_entry=$(find $diary_dir -name "????-??-??.tex" | sort | tail -1)
latest_entry_year=${latest_diary_entry:6:4}
latest_diary_entry_file=${latest_diary_entry:11}
latest_pdf_entry=$(find $pdf_dir -name "????-??-??.pdf" | sort | tail -1)
latest_pdf_year=${latest_pdf_entry:5:4}
latest_pdf_entry_file=${latest_pdf_entry:9}
year_to_compile="meh"
entry_to_compile="meh"
entry_to_edit="meh"
entry_to_view="meh"
style_file="research_diary.sty"
package_name=$(basename $style_file ".sty")
other_files_path="other_files/"
images_files_path="images/"
search_command="rg"
search_options="-i -t tex -C2"
search_term=""
author=""
ProjectName=""
bibsrc=""
encryptionId=""
GPG_COMMAND="gpg2"
default_commit_message="Add new entry"
useParallel=true

# configuration file to override the above defined variables.
if [ -f .callioperc ]
then
    source .callioperc
else
    echo "No .callioperc file found. Creating file with empty fields."
    echo "Please fill in the necessary information."
    echo "It will be used in subsequent runs."
    echo "ProjectName=\"\"" > .callioperc
    echo "author=\"\"" >> .callioperc
    echo "bibsrc=\"\"" >> .callioperc
    echo "encryptionId=\"\"" >> .callioperc
    exit 0
fi

add_entry ()
{
    echo "Today is $year/$month/$day"
    echo "Your diary is located in: $diary_dir/."

    if [ ! -d "$diary_dir" ]; then
        mkdir -p "$diary_dir"
    fi

    if [ ! -d "$diary_dir/$year" ]; then
        mkdir -p "$diary_dir/$year"
        mkdir -p "$pdf_dir/$year"
        mkdir -p "$diary_dir/$year/$images_files_path"
        mkdir -p "$diary_dir/$year/$other_files_path"
    fi

    if [ -d "$diary_dir/$year" ]; then
        echo "Adding new entry to directory $diary_dir/$year."

        cd "$diary_dir/$year" || exit -1
        filename="$year-$month-$day.tex"

        if [ -f "$filename" ] || [ -f "$filename.gpg" ]; then
            echo "File for today already exists: $diary_dir/$year/$filename."
            echo "Happy writing!"
        else
            if [ ! -f "$style_file" ]; then
                ln -s ../../templates/$style_file .
            fi

            cp ../../templates/entry.tex "$filename" && git add --intent-to-add "$filename"

            sed -i "s/@year/$year/g" "$filename"
            sed -i "s/@MONTH/$(date +%B)/g" "$filename"
            sed -i "s/@dday/$day/g" "$filename"
            sed -i "s/@day/$(date +%e)/g" "$filename"
            sed -i "s|@author|$author|g" "$filename"
            sed -i "s|@project|$ProjectName|g" "$filename"
            sed -i "s|@bibsrc|${bibsrc}|g" "$filename"

            echo "Finished adding $filename to $year."
            cd ../../ || exit -1
        fi
    fi

    if [ -n "$TMUX" ]
    then
        echo "Setting tmux buffer for your convenience."
        tmux set-buffer "$diary_dir/$year/$filename"
    else
        echo "Not using a tmux session. Not setting buffer."
    fi
}

clean ()
{
    echo "Cleaning up.."
    rm -fv -- *.aux *.bbl *.blg *.log *.nav *.out *.snm *.toc *.dvi *.vrb *.bcf *.run.xml *.cut *.lo* *.brf*
    latexmk -c
}

compile_today ()
{
    cd "$diary_dir/$year/" || exit -1
    decrypt "$todays_entry"
    echo "Compiling $todays_entry."
    if ! latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex "$todays_entry" ; then
        echo "Compilation failed. Exiting."
        cd ../../ || exit -1
        exit -1
    fi
    clean

    if [ ! -d "../../$pdf_dir/$year" ]; then
        mkdir -p "../../$pdf_dir/$year"
    fi
    mv -- *.pdf "../../$pdf_dir/$year/"
    echo "Generated pdf moved to pdfs directory."
    cd ../../ || exit -1
}

list_latest ()
{
    echo "Latest entries: "
    echo "source ($latest_entry_year): $latest_diary_entry"
    echo "PDF ($latest_pdf_year): $latest_pdf_entry"
}
compile_latest ()
{

    pushd "$diary_dir/$latest_entry_year/"
        decrypt "$latest_diary_entry_file"
        echo "Compiling $latest_diary_entry_file."

        if ! latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex "$latest_diary_entry_file" ; then
            echo "Compilation failed. Exiting."
            cd ../../ || exit -1
            exit -1
        fi
        clean

        if [ ! -d "../../$pdf_dir/$latest_entry_year" ]; then
            mkdir -p "../../$pdf_dir/$latest_entry_year"
        fi
        mv -- *.pdf "../../$pdf_dir/$latest_entry_year/"
        echo "Generated pdf moved to pdfs directory."
    popd

}

compile_all ()
{
    if [ ! -d "$diary_dir/$year_to_compile/" ]; then
        echo "$diary_dir/$year_to_compile/ does not exist. Exiting."
        exit -1
    fi

    if [ ! -d "../../$pdf_dir/$year_to_compile" ]; then
        mkdir -p ../../$pdf_dir/$year_to_compile
    fi

    cd "$diary_dir/$year_to_compile/" || exit -1
    if $useParallel; then
        echo "Compiling all in $year_to_compile in parallel."
        find . -name '*.tex' | parallel -I% --max-args 1 --joblog parallel.log --bar latexmk -pdf -silent -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex %
        mv -- *.pdf "../../$pdf_dir/$year_to_compile/"
        awk 'NR>1 {
        if ((! $7 == 0))
            {
                print $7, $19
            }
        }' parallel.log > ../../failed-runs.log
        clean
        cd ../../
        if [ -s failed-runs.log ]; then
            echo "Check for failed runs in failed-runs.log!"
            echo "Following runs failes:"
            cat failed-runs.log
        else
            rm failed-runs.log
        fi
        exit -1
    else
        echo "Compiling all in $year_to_compile."
        for i in "$year_to_compile"-*.tex ; do
            if ! latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex "$i"; then
                echo "Compilation failed at $i. Exiting."
                cd ../../ || exit -1
                exit -1
            fi
            mv -- *.pdf "../../$pdf_dir/$year_to_compile/"
            echo "Generated pdf for $i moved to pdfs directory."
            clean
        done

        echo "Generated pdf moved to pdfs directory."
        cd ../../ || exit -1
    fi
}

compile_specific ()
{
    year=${entry_to_compile:0:4}
    if [ ! -d "$diary_dir/$year/" ]; then
      echo "$diary_dir/$year/ does not exist. Exiting."
      exit -1
    fi

    cd "$diary_dir/$year/" || exit -1
    decrypt "$entry_to_compile"
    echo "Compiling $entry_to_compile"
    if ! latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex "$entry_to_compile"; then
        echo "Compilation failed. Exiting."
        cd ../../ || exit -1
        exit -1
    fi
    clean
    if [ ! -d "../../$pdf_dir/$year" ]; then
        mkdir -p ../../$pdf_dir/$year
    fi
    mv -- *.pdf "../../$pdf_dir/$year/"
    echo "Generated pdf moved to pdfs directory."
    cd ../../ || exit -1
}

# both of these need to be run in the folder itself
# so remember to pushd/popd as required
encrypt ()
{
    if [ -z ${encryptionId} ]
    then
        echo "Encryption is not enabled"
    else
        if command -v $GPG_COMMAND &> /dev/null
        then
            if [ -f "$1" ]
            then
                if [ "${1: -4}" == ".gpg"  ]
                then
                    echo "File $1 is already encrypted. Not re-encrypting."
                    exit 1
                else
                    echo "Encrypting $1 with $encryptionId"
                    if [ "$1" -ot "${1}.gpg" ]
                    then
                        echo "WARNING: Encrypted file newer than text file found."
                        echo "WARNING: Not encrypting, since this may overwrite a newer encrypted file."
                        exit 1
                    else
                        $GPG_COMMAND --batch --yes --encrypt --sign -r "$encryptionId" "$1" && rm "$1" -f || exit -1
                    fi
                fi
            else
                echo "File $1 not found"
                exit 1
            fi
        else
            echo "$GPG_COMMAND is not installed. Cannot encrypt."
            exit 1
        fi
    fi
}

encrypt_all ()
{
    # Any files that do not end in ".gpg" are considered unencrypted, just encrypt those.
    if [ -z ${encryptionId} ]
    then
        echo "Encryption is not enabled"
    else
        echo "Encrypting all unencrypted files with $encryptionId"
        find "$pdf_dir/" "$diary_dir/" -type f -and -not -type l -and -not -name "*.gpg" | while read f
        do
            directory="$(dirname $f)"
            file="$(basename $f)"
            pushd $directory
                encrypt "$file" || exit -1
            popd
        done
    fi
}

decrypt ()
{
    if [ -z ${encryptionId} ]
    then
        echo "Encryption is not enabled"
    else
        if command -v $GPG_COMMAND &> /dev/null
        then
            if [ -f "$1" ]
            then
                if [ "${1: -4}" == ".gpg"  ]
                then
                    echo "Decrypting $1 with $encryptionId"
                    nongpgfname="$(basename $1 .gpg)"
                    if [ "$1" -nt "$nongpgfname" ]
                    then
                        $GPG_COMMAND --batch --yes --decrypt $1 > "$nongpgfname"
                    else
                        echo "WARNING: Decrypted file is newer than encrypted copy."
                        echo "WARNING: Not overwriting. Please check the files, and re-encrypt if required."
                    fi
                else
                    echo "File is not a GPG encrypted file. Doing nothing."
                fi
            else
                echo "File $1 not found"
                exit 1
            fi
        else
            echo "$GPG_COMMAND is not installed. Cannot decrypt."
            exit 1
        fi
    fi
}

# remember to pushd/popd into the required directory
decrypt_all_sources ()
{
    # Any files that end in ".gpg" are considered encrypted, decrypt those.
    if [ -z ${encryptionId} ]
    then
        echo "Encryption is not enabled"
    else
        echo "Decrypting all encrypted files"
        find . -type f -and -not -type l -and -name "*.gpg" | while read f
        do
            directory="$(dirname $f)"
            file="$(basename $f)"
            pushd $directory
                decrypt "$file" || exit -1
            popd
        done
    fi
}

decrypt_all ()
{
    # Any files that end in ".gpg" are considered encrypted, decrypt those.
    if [ -z ${encryptionId} ]
    then
        echo "Encryption is not enabled"
    else
        echo "Decrypting all encrypted files"
        find "$pdf_dir/" "$diary_dir/" -type f -and -not -type l -and -name "*.gpg" | while read f
        do
            directory="$(dirname $f)"
            file="$(basename $f)"
            pushd $directory
                decrypt "$file" || exit -1
            popd
        done
    fi
}

create_anthology ()
{
    Name="$year_to_compile-${ProjectName// /-}-Diary"
    FileName=$Name".tex"
    tmpName=$Name".tmp"

    echo "$ProjectName diary"
    echo "Author: $author"
    echo "Year: $year_to_compile"

    if [ ! -d "$diary_dir/$year_to_compile" ]; then
        echo "ERROR: No directory for $year_to_compile exists"
        exit;
    fi

    if [ -z ${encryptionId} ]
    then
        echo ""
    else
        pushd "$diary_dir/$year_to_compile" && decrypt_all_sources && popd
    fi


    cd "$diary_dir" || exit -1

    touch $FileName
    echo "%" > $FileName
    echo "% $ProjectName Diary for $author, $year_to_compile" >> $FileName
    echo "%" >> $FileName
    echo "\documentclass[a4paper,twoside,11pt]{report}" >> $FileName
    echo "\newcommand{\workingDate}{\textsc{$year_to_compile}}" >> $FileName
    echo "\newcommand{\userName}{$author}" >> $FileName
    echo "\newcommand{\projectName}{$ProjectName}" >> $FileName
    echo "\usepackage{$package_name}" >> $FileName
    echo " " >> $FileName
    echo "\title{$ProjectName diary - $year_to_compile}" >> $FileName
    echo "\author{$author}" >> $FileName
    echo " " >> $FileName

    echo "\rhead{\textsc{$year_to_compile}}" >> $FileName
    echo "\chead{\textsc{$ProjectName}}" >> $FileName
    echo "\lhead{\textsc{\userName}}" >> $FileName
    echo "\rfoot{\textsc{\thepage}}" >> $FileName
    echo "\cfoot{\textit{Last modified: \today}}" >> $FileName
    echo "\addbibresource{$bibsrc}" >> $FileName
    echo "\graphicspath{{./$year_to_compile/$images_files_path}}" >> $FileName
    echo "\lstset{{inputpath=./$year_to_compile/$other_files_path}}" >> $FileName

    echo " " >> $FileName
    echo " " >> $FileName
    echo "\begin{document}" >> $FileName
    echo "\begin{center} \begin{LARGE}" >> $FileName
    echo "\textbf{$ProjectName Diary} \\\\[3mm]" >> $FileName
    echo "\textbf{$year_to_compile} \\\\[2cm]" >> $FileName
    echo "\end{LARGE} \begin{large}" >> $FileName
    echo "$author \end{large} \\\\" >> $FileName
    echo "\textsc{Compiled \today}" >> $FileName
    echo "\end{center}" >> $FileName
    echo "\thispagestyle{empty}" >> $FileName
    echo "\newpage" >> $FileName
    echo "\tableofcontents" >> $FileName
    echo "\thispagestyle{empty}" >> $FileName
    # echo "\clearpage" >> $FileName

    for i in "$year_to_compile"/"$year_to_compile"-*.tex ; do
        echo -e "\n%%% --- $i --- %%%\n" >> $tmpName
        echo "\rhead{`grep workingDate $i | cut -d { -f 4 | cut -d } -f 1`}" >> $tmpName
        sed -n '/\\begin{document}/,/\\end{document}/p' $i >> $tmpName
        echo -e "\n" >> $tmpName
        echo "\newpage" >> $tmpName
    done

    # uncomment the chapter line
    sed -i 's/%\\chapter/\\chapter/' $tmpName
    sed -i 's/\\begin{document}//g' $tmpName
    sed -i 's/\\printindex//g' $tmpName
    sed -i 's/\\bibliography.*$//g' $tmpName
    sed -i 's/\\printbibliography.*$//g' $tmpName
    sed -i 's/\\end{document}//g' $tmpName
    sed -i 's|\\includegraphics\(.*\)'"$images_files_path"'\(.*\)|\\includegraphics\1\2|g' $tmpName
    sed -i 's|\\includesvg\(.*\)'"$images_files_path"'\(.*\)|\\includesvg\1\2|g' $tmpName
    sed -i 's|\\lstinputlisting\(.*\)'"$other_files_path"'\(.*\)|\\lstinputlisting\1\2|g' $tmpName
    sed -i 's|\\inputminted\(.*\)\('"$other_files_path"'\)\(.*\)|\\inputminted\1'"./$year_to_compile/"'\2\3|g' $tmpName
    # with options: options can contain a {, so need to handle them first
    sed -i 's/\\includepdf\(\[.*\]\){\(.*\)/\\includepdf\1{'"$year_to_compile"'\/\2/g' $tmpName
    # without options
    sed -i 's/\\includepdf{\(.*\)/\\includepdf{'"$year_to_compile"'\/\1/g' $tmpName
    sed -i 's/\\newcommand/\\renewcommand/g' $tmpName

    cat $tmpName >> $FileName
    echo "\printbibliography" >> $FileName
    echo "\printindex" >> $FileName
    echo "\end{document}" >> $FileName

    if [ ! -f "$style_file" ]; then
        ln -sf ../templates/$style_file .
    fi

    if ! latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape -synctex=1" -use-make -bibtex "$FileName"; then
        echo "Compilation failed. Exiting."
        cd ../ || exit -1
        exit -1
    fi
    mv -- *.pdf "../$pdf_dir/"

    clean
    rm $tmpName

    echo "$year_to_compile master document created in $pdf_dir."
    cd ../ || exit -1

    if [ -z ${encryptionId} ]
    then
        echo ""
    else
        pushd "$diary_dir/$year_to_compile" && git clean -dfx . && popd
    fi
}

edit_latest ()
{
    pushd $diary_dir/$latest_entry_year/
        decrypt "$latest_diary_entry_file"
        outputfile="$(basename $latest_diary_entry_file .gpg)"
        $MY_EDITOR "$outputfile"
    popd
}

edit_specific ()
{
    year=${entry_to_edit:0:4}
    if [ ! -d "$diary_dir/$year/" ]; then
      echo "$diary_dir/$year/ does not exist. Exiting."
      exit -1
    fi
    pushd "$diary_dir/$year/"
        decrypt "$entry_to_edit.tex.gpg"
        $MY_EDITOR "$entry_to_edit.tex"
    popd
}

view_specific ()
{
    year=${entry_to_view:0:4}
    if [ ! -d "$pdf_dir/$year/" ]; then
      echo "$pdf_dir/$year/ does not exist. Exiting."
      exit -1
    fi
    pushd "$pdf_dir/$year"
        decrypt "$entry_to_view.pdf.gpg"
        $MY_VIEWER "$entry_to_view.pdf"
    popd
}

view_latest ()
{
    pushd $pdf_dir/$year/
        latest_pdf_entry=$(ls $year*pdf* | tail -1)
        decrypt "$latest_pdf_entry"
        outputfile="$(basename $latest_pdf_entry .gpg)"
        $MY_VIEWER "$outputfile"
    popd
}

view_anthology ()
{
    Name="$year_to_compile-${ProjectName// /-}-Diary"
    pushd $pdf_dir/
        FileName="$Name.pdf.gpg"
        decrypt "$FileName"
        outputfile="$(basename $FileName .gpg)"
        $MY_VIEWER "$outputfile"
    popd
}

search_diary ()
{
    if ! command -v $search_tool &> /dev/null
    then
        echo "$search_tool not found."
        exit -1
    else
        echo "Running search command: $search_command $search_options -- \"$search_term\" $diary_dir/*/"
        $search_command $search_options -- "$search_term" $diary_dir/*/
    fi
}

remove_unencrypted ()
{
    # if encryption is enabled, delete all unencrypted pdf files before committing
    if [ -z ${encryptionId} ]
    then
        echo "Encryption is not enabled"
    else
        echo "Deleting all unencrypted files"
        find pdfs/ diary/ -not -name "*.gpg" -and -type f -and -not -type l -delete
    fi
}

commit_changes ()
{
    if ! command -v git &> /dev/null
    then
        echo "git is not installed."
        exit -1
    else
        encrypt_all && remove_unencrypted || exit -1
        echo "Committing changes to repository with commit message \"${commit_message:-$default_commit_message}\""
        git add .
        if ! git commit -m "${commit_message:-$default_commit_message}"
        then
            echo "Commit failed. Please check the output and commit manually."
            exit -1
        else
            exit 0
        fi
    fi
}

add_extra_file () {
    dirpath="$images_files_path"
    if [ "other" == "$1" ]
    then
        dirpath="$other_files_path"
    fi

    full_path="$2"
    filename=$(basename -- "$full_path")
    extension="${filename##*.}"
    cp -v "$2" "$diary_dir/$year/$dirpath/$timestamp.$extension"
    git add "$diary_dir/$year/$dirpath/$timestamp.$extension"
}

usage ()
{
    cat << EOF
    calliope: ${SHORT_DESC}

    Usage: calliope [options] [arguments]

    Version: $VERSION

    Master script file that provides functions to maintain a journal using LaTeX.
    Please report issues and request features at ${UPSTREAM_URL}.


    OPTIONS:

    -h  Show this message and quit

    -H  Print version and exit

    -t  Add new entry for today

    -l  Compile latest entry

    -C  Compile latest entry and commit to repository.
        An optional commit message may be given using the commit_message
        variable:
        commit_message="Test" ./calliope.sh -C
        If one is not given, the default is used: "$default_commit_message".

        Note that encryption, if enabled, is only done before committing.
        So, please remember to commit early and commit often.

    -m  Commit to repository (but do not compile).
        An optional commit message may be given using the commit_message
        variable:
        commit_message="Test" ./calliope.sh -m
        If one is not given, the default is used: "$default_commit_message".

        Note that encryption, if enabled, is only done before committing.
        So, please remember to commit early and commit often.

    -c  Compile today's entry

    -a  <year>
        Year to generate anthology of

    -A  <year>
        Year to view anthology of

    -p  <year>
        Compile all entries in this year

    -s  <entry> (yyyy-mm-dd)
        Compile specific entry

    -e  edit the latest entry using \$MY_EDITOR

    -E  <entry> (yyyy-mm-dd)
        edit specific entry using \$MY_EDITOR

    -v  view the latest entry using \$MY_VIEWER

    -V  <entry> (yyyy-mm-dd)
        view specific entry using \$MY_VIEWER

    -k  <search term>
        search diary for term using $search_tool
        Please see the documentation of the search tool you use
        to see what search terms/regular expressions are supported.

        Note: only works when encryption is *not* enabled.

    -G  <file to decrypt>
        decrypt a file

    -g  <file to encrypt>
        encrypt a file

    -x  clean folder: remove any unencrypted files if encryption is enabled

    -i  <image file path>
        imports the image into the diary image folder and renames it "<timestamp>.extension"

    -I  <non image file path>
        imports the non-image into the diary extra files folder and renames it "<timestamp>.extension"

EOF

}

if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

while getopts "evLltca:A:hHp:s:E:V:k:CG:g:xmi:I:" OPTION
do
    case $OPTION in
        t)
            add_entry
            exit 0
            ;;
        L)
            list_latest
            exit 0
            ;;
        e)
            edit_latest
            exit 0
            ;;
        v)
            view_latest
            exit 0
            ;;
        l)
            compile_latest
            exit 0
            ;;
        c)
            compile_today
            exit 0
            ;;
        a)
            year_to_compile=$OPTARG
            create_anthology
            exit 0
            ;;
        A)
            year_to_compile=$OPTARG
            view_anthology
            exit 0
            ;;
        h)
            usage
            exit 0
            ;;
        H)
            echo "${VERSION}"
            exit 0
            ;;
        p)
            year_to_compile=$OPTARG
            compile_all
            exit 0
            ;;
        s)
            entry_to_compile=$OPTARG
            compile_specific
            exit 0
            ;;
        E)
            entry_to_edit=$OPTARG
            edit_specific
            exit 0
            ;;
        V)
            entry_to_view=$OPTARG
            view_specific
            exit 0
            ;;
        k)
            search_term=$OPTARG
            search_diary
            exit 0
            ;;
        C)
            compile_latest
            commit_changes
            exit 0
            ;;
        m)
            commit_changes
            exit 0
            ;;
        G)
            decrypt "$OPTARG"
            exit 0
            ;;
        g)
            encrypt "$OPTARG"
            exit 0
            ;;
        x)
            remove_unencrypted
            exit 0
            ;;
        i)
            add_extra_file "image" "$OPTARG"
            exit 0
            ;;
        I)
            add_extra_file "other" "$OPTARG"
            exit 0
            ;;
        ?)
            usage
            exit 0
            ;;
    esac
done
