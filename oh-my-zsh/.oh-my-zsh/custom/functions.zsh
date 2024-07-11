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

# Process grepable nmap output and print ip and open ports
function processGnmap() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <gnmap file>"
        return 1
    fi

    local inputFile="$1"
    local outputFile="output.txt"

    local fileContent=$(cat "$inputFile")

    local ip=$(echo "$fileContent" | grep -oP '\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}' | sort -u | head -n 1)
    local ports=$(echo "$fileContent" | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')

    local result="IP Address: [$ip], Open Ports: [$ports]"
    echo "$result"
    echo "You may want to execute this nmap command now: nmap -sCV -p$ports -Pn -vvv -oA nmap_target $ip"
    echo "$result" >>"$outputFile"
}

# Extract Nmap ports
function extractPorts () {
    ports="$(echo "$1" | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(echo "$1" | grep -oP '\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}' | sort -u | head -n 1)"
    echo -e "\t[] IP Address: $ip_address" >> extractPorts.tmp
    echo -e "\t[] Open ports: $ports\n" >> extractPorts.tmp
    cat extractPorts.tmp
    rm extractPorts.tmp
}

# Extract Nmap ports from file
function extractPortsFromFile() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <input_file>"
        exit 1
    fi
    
    input_file="$1"
    output_file="output.txt"
    
    while read -r line; do
        extractPorts "$line" >> "$output_file"
    done < <(cat "$input_file")
}

# ExtractHosts from cme smb and dnsrecon
#########################################
function merge_ips() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <ip_file1> <ip_file2> <output_file>"
        exit 1
    fi
    
    ip_file1=$1
    ip_file2=$2
    output_file=$3
    
    cat "$ip_file1" "$ip_file2" | sort -t . -k 3,3n -k 4,4n > "$output_file"
    
}

function separate_subnets() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <ip_list_file>"
        exit 1
    fi
    
    ip_list_file=$1
    
    while read ip; do
        subnet=$(echo $ip | awk -F '.' '{print $1"."$2"."$3}')
        
        if [ ! -d "$subnet" ]; then
            mkdir "$subnet"
        fi
        
        echo $ip >> "$subnet/ips.txt"
    done < $ip_list_file
}

function extractHosts() {
    cat smb.txt | awk {'print $2'} | tee hosts_smbcme
    cat dns.txt | awk {'print $4'} | tee hosts_dnsrecon
    
    merge_ips "hosts_smbcme" "hosts_dnsrecon" "hosts.txt"
    cat hosts.txt | uniq | tee hosts_sorted.txt
    mv hosts_sorted.txt hosts.txt
    
    rm -rf "hosts_smbcme"
    rm -rf "hosts_dnsrecon"
    
    separate_subnets "hosts.txt"

    rm -rf "Found.."
    rm -rf "Lookup.."
}
#########################################

# Strip and encrypt PDF
function strip_pdf() {
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

# Zip and encrypt folders
function zip_folders() {
    path="$1"
    for f in "$path"/*/; do
        name=$(basename "$f")
        zip -P "$name" "$name.zip" "$name" -r
    done
}
# Tar and encrypt folders with gpg
function ctargpg() {
    if [ $# -eq 0 ]; then
        echo "No folders provided."
        return 1
    fi
    
    echo -n "Enter password for encryption: "
    read -s password
    echo
    
    for folder in "$@"; do
        if [ -d "$folder" ]; then
            encrypted_file="$folder.tar.gz.gpg"
            tar_file="$folder.tar.gz"
            
            # Compress the folder using tar
            tar -cvzf "$tar_file" "$folder"
            
            # Encrypt the tar file using gpg, providing the password through echo and a pipe
            echo "$password" | gpg --batch --yes --passphrase-fd 0 -c -o "$encrypted_file" "$tar_file"
            
            # Remove the temporary tar file
            rm "$tar_file"
            
            echo "Compressed and encrypted folder: $folder"
            echo "Encrypted file: $encrypted_file"
        else
            echo "Folder not found: $folder"
        fi
    done
}

# Decrypt and untar folders with gpg
function xtargpg() {
    for encrypted_file in "$@"; do
        if [ -f "$encrypted_file" ]; then
            decrypted_file=$(basename "$encrypted_file" .gpg)
            
            # Decrypt the file
            gpg -d "$encrypted_file" > "$decrypted_file"
            
            # Extract the decrypted file
            tar -xvzf "$decrypted_file"
            
            echo "Processed file: $encrypted_file"
        else
            echo "File not found: $encrypted_file"
        fi
    done
}
