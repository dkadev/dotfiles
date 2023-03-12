#------------------------------------------------------
# Functions
#------------------------------------------------------

# Make box dirs
function mkbx(){
    if [ $# -eq 0 ]; then
        echo "Usage: mkbx <dir_name>"
    else
        parent_dir_name=$1
        mkdir -p "$parent_dir_name"/{content,exploits,recon}
    fi
}

# Make pentest dirs
function mkpt(){
    if [ $# -eq 0 ]; then
        echo "Usage: mkpt <dir_name>"
    else
        parent_dir_name=$1
        mkdir -p "$parent_dir_name"/{evidence/credentials,evidence/data,evidence/screenshots,logs,scans,scope,tools}
    fi
}

# Extract nmap information
function extractPorts(){
    ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
    echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
    echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
    echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
    echo $ports | tr -d '\n' | xclip -sel clip
    echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
    cat extractPorts.tmp; rm extractPorts.tmp
}

strip_pdf() {
    echo "Original Metadata for $1"
    exiftool $1

    echo "Removing Metadata...."
    echo ""
    qpdf --linearize $1 stripped1-$1
    exiftool -all:all= stripped1-$1
    qpdf --linearize stripped1-$1 stripped2-$1
    rm stripped1-$1
    rm stripped1-$1_original

    echo "New Metadata for stripped2-$1"
    exiftool stripped2-$1
    echo ""

    echo "Securing stripped2-$1...."
    password=$(pwgen -s 12 1)
    echo "Password will be: $password"
    echo ""
    qpdf --linearize --encrypt $password $password 128 --print=full --modify=none --extract=n --use-aes=y -- stripped2-$1 stripped-$1
    rm stripped2-$1

    echo "Final status of stripped-$1"
    pdfinfo -upw $password stripped-$1
}