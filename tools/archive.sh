#!/bin/sh

# usage: sh archive.sh tree-ish outdir
# Archives a Git revision with all of its submodules.

recursivearchivefiles ()
{
    # recursivearchivefiles directory prefix tree-ish output-file

    cd "$1"

    echo Archiving: "$1"

    # recurse into submodules
    git ls-tree -r "$3"|grep '^[^ ]* commit'|while read line; do
        if test "x$line" = x; then
            continue
        fi

        obj=`echo "$line"|sed -e 's/^[^ ]* [^ ]* \([^	]*\)	.*$/\1/'`
        filename=`echo "$line"|sed -e 's/^[^ ]* [^ ]* [^	]*	\(.*\)$/\1/'`

        if ! test -e "$1"/"$filename"/.git; then
            echo Missing submodule: "$1"/"$filename"
            continue
        fi

        recursivearchivefiles "$1"/"$filename" "$2""$filename"/ "$obj" "$4"

        cd "$1"
    done

    TEMPFILE=`mktemp`
    git archive --format=tar --prefix="$2" "$3" > $TEMPFILE
    tar Af "$4" "$TEMPFILE"
    rm "$TEMPFILE"
}

OUTPUT_FILE="$2/$3.tar"

rm -f "$OUTPUT_FILE"

recursivearchivefiles "$PWD" "$1"/ HEAD "$OUTPUT_FILE"

# add llvm-mingw
tar rf "$OUTPUT_FILE" --transform 's:^./:'"$1"'/:g' ./$4

