#!/bin/bash

if [ $1 = '-i' ]; then
    interactive=true
    shift
fi

if [ $# -ne 1 ]; then
    echo "Usage: $0 <hosts file>" >&2
    echo 'Run `'"$0"' --help'\'' for more information.' >&2
    exit 1
fi

if [ "$1" = '--help' ]; then
    echo 'Usage: '"$0"' <hosts file>'
    echo 'Update the password on the remote hosts listed in the hosts file.'
    echo 'The script will prompt for the current password and the new password.'
    echo 'The script will attempt to login on each host using the current password'
    echo 'plus the corresponding per-host prefix and suffix, if any.'
    echo 'If the login fails, the script will retry using the current password only.'
    echo
    echo -e '  -i\tInteractive mode: if the login attempts fail for a given host,'
    echo -e '\tthe script will run passwd as the current user on that host manually,'
    echo -e '\tletting ssh and passwd prompt for credentials.'
    echo
    echo 'The hosts file should contain one host per line,'
    echo 'with an optional per-host password prefix and suffix separated by colons.'
    echo 'Syntax: host[:prefix[:suffix]]'
    exit 0
fi

cat "$1" > /dev/null || exit

read -rsp 'Current password: ' password
read -rsp 'New password: ' new_password
read -rsp 'Confirm new password: ' confirm_password

if [ "$new_password" != "$confirm_password" ]; then
    echo 'Passwords do not match' >&2
    exit 1
fi

update_cmd() {
    # Emulate the inputs for the passwd(1) prompts:
    #Changing password for <user running the command (i.e. the one running the script)>.
    #Current password: <current password (passed as first argument)>
    #New password: <new password (passed as second argument)>
    #Retype new password: <new password again>
    #passwd: password updated successfully
    echo "{ echo '${1//'/'\''/}'; echo '${2//'/'\''/}'; echo '${2//'/'\''/}'; } | passwd >/dev/null"
}

update_password() {
    # Create the dummy SSH_ASKPASS script
    local script=$(mktemp)
    chmod u-r "$script"
    chmod u+x "$script"
    echo '#!/bin/bash' > "$script"
    echo "echo '${1//'/\'/}'" >> "$script"

    SSH_ASKPASS="$script" SSH_ASKPASS_REQUIRE=force ssh "$(whoami)@$host" $(update_cmd "$1" "$new_password_plus") 2>/dev/null
    local ret=$?

    # Remove the dummy SSH_ASKPASS script;
    # it contains the current password in plain text,
    # so better remove it immediately after use
    rm -f "$script"
    return $ret
}

cat "$1" | while read -r host; do
    # Read optional per-host password prefix and suffix
    # Syntax: host[:prefix[:suffix]]
    prefix=$(cut -d':' -f2 "$host")
    suffix=$(cut -d':' -f3 "$host")
    host=$(cut -d':' -f1 "$host")
    new_password_plus="$new_password"
    password_plus="$password"
    if [ -n "$prefix" ]; then password="${prefix}${password_plus}" new_password_plus="${prefix}${new_password_plus}"; fi
    if [ -n "$suffix" ]; then password="${password_plus}${suffix}" new_password_plus="${new_password_plus}${suffix}"; fi
    # Update the password on the remote machine
    # The SSH_ASKPASS dummy script will be used for password authentication if needed
    update_password "$password_plus" || update_password "$password"
    ret=$?
    if [ $ret -e 255 ]; then
        if [ -n "$interactive" ]; then ssh "$(whoami)@$host" passwd;
        else echo "Failed to log in on $host as $(whoami)" >&2;
        fi
    elif [ $ret -ne 0 ]; then echo "Failed to update password for $(whoami) on $host" >&2;
    else echo "Password successfully updated for $(whoami) on $host";
    fi
done
