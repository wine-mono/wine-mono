#!/bin/sh

set -e

rm -f "${CABFILENAME}" "${TABLEDIR}/*.idt"

mkdir -p "${TABLEDIR}"
cp "${TABLESRCDIR}"/*.idt "${TABLEDIR}"

IMAGECABWINPATH=`${WINE} winepath -w "${CABFILENAME}"`

CONTENTDIR="${TABLEDIR}/cab_contents"
rm -rf "${CONTENTDIR}"
mkdir -p "${CONTENTDIR}"

cd "${IMAGEDIR}"

FILEKEY_EXPR='s/\//\\/g'
FILEKEY_REV_EXPR='s/\\/\//g'
DIRKEY_EXPR='s/\//|/g'

find . '!' -name '*.pdb' | cut -d '/' -f2- | while read -r f; do
    if test . = "$f"; then
        continue
    fi
    FILEKEY=`echo $f|sed -e "$FILEKEY_EXPR"`
    DIRKEY=`echo $f|sed -e "$DIRKEY_EXPR"`
    PARENT=`dirname "$f"`
    BASENAME=`basename "$f"`

    if test $PARENT = .; then
        PARENTKEY=$ROOTDIR
    else
        PARENTKEY=`echo $PARENT|sed -e "$DIRKEY_EXPR"`
    fi

    if test -d "$f"; then
        GUID=`uuidgen -s -n 26a7bdb4-1612-4e2b-a26e-e548a12e4d48 -N "$f" | tr [a-z] [A-Z]`
        KEYPATH=`find "$f" -maxdepth 1 -type f '!' -name '*.pdb'|sort|head -n 1|sed -e "$FILEKEY_EXPR"`

        case "$f" in
        Microsoft.NET/Framework64*) CONDITION='(VersionNT64)';;
        *) CONDITION=;;
        esac

		mkdir -p "${CONTENTDIR}"/"$f"

        printf '%s\t{%s}\t%s\t0\t%s\t%s\n' "$DIRKEY" "$GUID" "$DIRKEY" "$CONDITION" "$KEYPATH" >> ${TABLEDIR}/component.idt
        printf "%s\t%s\n" "$DIRKEY" "$DIRKEY" >> ${TABLEDIR}/createfolder.idt
        printf "%s\t%s\t%s\n" "$DIRKEY" "$PARENTKEY" "$BASENAME" >> ${TABLEDIR}/directory.idt
        printf "wine_mono\t%s\n" "$DIRKEY" >> ${TABLEDIR}/featurecomponents.idt
    elif test -L "$f"; then
        printf "%s\t%s\t%s\t%s\t2\n" "$FILEKEY" "$PARENTKEY" "$BASENAME" "$PARENTKEY" >> ${TABLEDIR}/removefile.idt
        TARGET=`readlink "$f"`
        TARGETBASE=`basename "$TARGET"`
        TARGETRELDIR=`dirname "$TARGET"`
        TARGETPARENT=`python3 -c 'import os.path; import sys; print(os.path.normpath(os.path.join(*sys.argv[1:])).replace("/", "|"))' "$PARENT" "$TARGETRELDIR"`
        printf "%s\t%s\t%s\t%s\t%s\n" "$FILEKEY" "$BASENAME" "$PARENTKEY" "$TARGETBASE" "$TARGETPARENT" >> ${TABLEDIR}/symlinks.idt
    elif test -f "$f"; then
		ln -s "${IMAGEDIR}"/"$f" "${CONTENTDIR}"/"$f"
    fi
done

mono "$GENFILEHASHES" >> ${TABLEDIR}/msifilehash.idt

cd "${CONTENTDIR}"

${WINE} cabarc -m mszip -r -p N "$IMAGECABWINPATH" * || exit 1

cd "${IMAGEDIR}"

rm -rf "${CONTENTDIR}"

# We can't dictate the order of files in the cab, so read it back to find the sequence numbers.
SEQ=0
rm -f "${TABLEDIR}/sequence"

${WINE} cabarc L "$IMAGECABWINPATH" | sed 's/\r//' | sed -e "$FILEKEY_REV_EXPR" | while read -r f; do
    FILEKEY=`echo $f|sed -e "$FILEKEY_EXPR"`
    FILESIZE=`ls -l "$f" | awk '{print $5}'`
    PARENT=`dirname "$f"`
    BASENAME=`basename "$f"`
    SEQ=`expr $SEQ + 1`

    if test $PARENT = .; then
        PARENTKEY=$ROOTDIR
    else
        PARENTKEY=`echo $PARENT|sed -e "$DIRKEY_EXPR"`
    fi

    printf '%s\t%s\t%s\t%s\t\t\t\t%s\n' "$FILEKEY" "$PARENTKEY" "$BASENAME" "$FILESIZE" "$SEQ" >> ${TABLEDIR}/file.idt
    printf "%s" "$SEQ" > ${TABLEDIR}/sequence
done

printf '1\t%s\t\t%s\t\t\n' `cat "${TABLEDIR}/sequence"` "$CABINET" >> ${TABLEDIR}/media.idt

if test x${WHICHMSI} = xsupport; then
	PRODUCTCODE=`uuidgen -s -n 27ec5e1a-7f2f-445c-9e78-76ae42a51b6d -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	PACKAGECODE=`uuidgen -s -n 5b2a0add-9ec1-4c3c-b749-2c7d96db4656 -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	printf '{DE624609-C6B5-486A-9274-EF0B854F6BC5}\t\t%s\t\t0\t\tOLDSUPPORTVERSION\n' $MSI_VERSION >> "$TABLEDIR"/upgrade.idt
else
	SUPPORT_PRODUCTCODE=`uuidgen -s -n 27ec5e1a-7f2f-445c-9e78-76ae42a51b6d -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	PRODUCTCODE=`uuidgen -s -n e3d60378-6160-4d62-9105-1a321b78891e -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	PACKAGECODE=`uuidgen -s -n 27abb979-e12d-4a3a-95d8-f42c2027a693 -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	printf 'REMOVESUPPORT\t1122\tWindowsFolder\tmsiexec /x {%s}\t\n' $SUPPORT_PRODUCTCODE >> "$TABLEDIR"/customaction.idt
fi

printf 'ProductCode\t{%s}\n' $PRODUCTCODE >> "$TABLEDIR"/property.idt
printf 'ProductVersion\t%s\n' $MSI_VERSION >> "$TABLEDIR"/property.idt
printf '9\t{%s}\n' $PACKAGECODE >> "$TABLEDIR"/summaryinformation.idt
printf '{DF105CC2-8FA2-4367-B1D3-95C63C0941FC}\t4.8.0\t%s\t\t0\t\tOLDRUNTIMEVERSION\n' $MSI_VERSION >> "$TABLEDIR"/upgrade.idt
