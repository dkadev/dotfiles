#------------------------------------------------------
# Functions
#------------------------------------------------------

# Make pentest dirs
function mkpt() {
    if [ $# -eq 0 ]; then
        echo "Usage: mkpt <dir_name>"
    else
        parent_dir_name=$1
        mkdir -p "$parent_dir_name"/{credentials,data,exploits,logs,scans} && ls -lah "$parent_dir_name"
    fi
}

# Process grepable nmap output and print ip and open ports for each IP
function processGnmap() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <gnmap file>"
        return 1
    fi
    local inputFile="$1"
    # Get all unique IP addresses
    local ips=$(grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' "$inputFile" | sort -u)
    # Process each IP address
    echo "$ips" | while read -r ip; do
        local ports=$(grep "$ip" "$inputFile" | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | sort -u | xargs | tr ' ' ',')
        local result="IP Address: [$ip], Open Ports: [$ports]"
        echo "$result"
        echo "You may want to execute this nmap command now: nmap -sCV -p$ports -Pn -vvv -oA nmap_target $ip"
    done
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

    cat "$ip_file1" "$ip_file2" | sort -t . -k 3,3n -k 4,4n >"$output_file"

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

        echo $ip >>"$subnet/ips.txt"
    done <$ip_list_file
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
            gpg -d "$encrypted_file" >"$decrypted_file"

            # Extract the decrypted file
            tar -xvzf "$decrypted_file"

            echo "Processed file: $encrypted_file"
        else
            echo "File not found: $encrypted_file"
        fi
    done
}

# Encrypt file
function encryptFile(){
	if [[ -n $1 && $# -eq 1 ]]; then
		openssl enc -aes-256-cbc -pbkdf2 -k strongPass <$1 >$1.enc
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: $0 \033[3;37m<file>\033[0m"
	fi
}

# Decrypt file
function decryptFile(){
	if [[ -n $1 && -n $2 && $# -le 2 ]]; then
		openssl enc -d -aes-256-cbc -pbkdf2 -k strongPass <$1 >$2
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: $0 \033[3;37m<Encrypt-File> <Output-File>\033[0m"
	fi
}

# Search Wordlists
function wordlists(){
	if [[ -n $1 && $# -eq 1 ]]; then
		find -L /usr/share/wordlists -type f -iname "*$1*"
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: $0 \033[3;37m<string>\033[0m"
	fi
}

# Search NSE script
function nseSearch(){
	#locate *.nse | grep -i -o "$1".*;
	if [[ -n $1 && $# -eq 1 ]]; then
		nmap_basepath=$(nmap -v -d 2>/dev/null | grep -Po 'Read from \K\/.*(?=:)')
		script_list=$(grep -Po '[\w-]+(?=.nse)' "$nmap_basepath"/scripts/script.db | grep -i "$1")

		# Search NSE script names for search parameter
		if [[ -n $script_list ]]; then
			echo -e "\n\033[3;36mNSE scripts available in nmap:\033[0m"
			grep -Po '[\w-]+(?=.nse)' "$nmap_basepath"/scripts/script.db | grep -i "$1"
		else
			echo -e "\n\033[1;31mNo matches found for \033[0;97m'$1'\033[1;31m.\033[0m"
		fi
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: $0 \033[3;37m<string>\033[0m"
	fi
}

# Add target
function addtarget(){
	if [[ -n $1 ]]; then
		echo $1 > $HOME/.config/scripts/.targets 2>/dev/null
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: addtarget <IP-Address>\033[0m"
	fi
}

# Delete target
function deltarget(){
	echo "" > $HOME/.config/scripts/.targets 2>/dev/null
}

# Conocer la URL en una URL acortada
function urlAcortada(){
	if [[ -n $1 && $# -eq 1 ]]; then
		curl -sLI $1 | grep -i Location
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: urlAcortada <URL>\033[0m"
	fi
}

# Conocer la version de WordPress de un sitio
function wpVersion(){
	if [[ -n $1 && $# -eq 1 ]]; then
		curl -s -X GET $1 | grep '<meta name="generator"'
		if [ $? -ne 0 ]; then
			curl -s -X GET $1/wp-links-opml.php | grep '<meta name="generator"'
		fi
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: wpVersion <URL-WordPress>\033[0m"
	fi
}

# Conocer los plugins instalados de un sitio web con WordPress
function wpPlugins(){
	if [[ -n $1 && $# -eq 1 ]]; then
		curl -s -X GET $1 | sed 's/href=/\n/g' | sed 's/src=/\n/g' | grep 'wp-content/plugins/*' | cut -d"'" -f2
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: wpPlugins <URL>\033[0m"
	fi
}

# Conocer los temas instalados de un sitio web con WordPress
function wpThemes(){
	if [[ -n $1 && $# -eq 1 ]]; then
		curl -s -X GET $1 | sed 's/href=/\n/g' | sed 's/src=/\n/g' | grep 'themes' | cut -d"'" -f2
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: wpThemes <URL>\033[0m"
	fi
}

function zoneTransfer(){
	if [[ -n $1 && $# -eq 1 ]]; then
		domain=$1
		n=0
		for server in $(host -t ns $domain | cut -d ' ' -f 4) ; do
			address=`host -l $1 $server | grep -i 'address' | tr "\n" "|"`
				if [ -n "$address" ] ; then
					address2=`echo $address | cut -d '#' -f 1`
					echo $address2
					tmp=`echo $address2 | cut -d ' ' -f 2`
					zonetransfer=`dig +short -t AXFR $domain @$tmp`
					echo -e "\t $zonetransfer"
					n=1
				fi
		done
		if [ $n -eq 0 ] ; then
			echo "\n\t\033[1;31m[-] Zone transfer not possible!\033[0m"
		fi
	else
		echo -e "\n\t\033[0;36m[\033[0;33m!\033[0;36m] \033[0;37mUse: zoneTransfer <DOMAIN>\033[0m"
	fi
}