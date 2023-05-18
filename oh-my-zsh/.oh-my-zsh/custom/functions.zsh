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

function zip_folders() {
    path="$1"
    for f in "$path"/*/; do
        name=$(basename "$f")
        zip -P "$name" "$name.zip" "$name" -r
    done
}

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
