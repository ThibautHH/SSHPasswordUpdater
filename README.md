# SSHPasswordUpdater

## Description

This script is used to update the password of a user on remote hosts using SSH.

## Usage

```bash
user@localhost:~/SSHPasswordUpdater$ ./update.sh --help
Usage: '"$0"' [OPTION]... <HOSTS FILE>
Update the password on the remote hosts listed in the hosts file.
The script will prompt for the current password and the new password.
The script will attempt to login on each host using the current password plus
the corresponding per-host prefix and suffix, if any.
If the login fails, the script will retry using the current password only.

  -i    Interactive mode: if the login attempts fail for a given host,
        the script will run passwd(1) as the current user on that host manually,
        letting ssh(1) and passwd(1) prompt for credentials.

The hosts file should contain one host per line,
with an optional per-host password prefix and suffix separated by colons.
Syntax: hostname[:prefix[:suffix]]
```

## Example

```bash
user@localhost:~/SSHPasswordUpdater$ cat hosts.txt
localhost
server1:srv1-
server2:srv2-:-srv2
server3::-srv3
server4:srv4-:
server5:srv5-
server6
user@localhost:~/SSHPasswordUpdater$ ./update.sh hosts.txt
Current password: *ex4MpL3P@ssw0rd*
New password: *n3wP@ssw0rd*
Confirm new password: *n3wP@ssw0rd*
Password successfully updated for user on localhost
Password successfully updated for user on server1
Password successfully updated for user on server2
Password successfully updated for user on server3
Password successfully updated for user on server4
Password successfully updated for user on server5
Failed to log in on server6 as user
```

Resulting passwords should be:

- user@localhost: *ex4MpL3P@ssw0rd* -> *n3wP@ssw0rd*
- user@server1: *srv1-ex4MpL3P@ssw0rd* -> *srv1-n3wP@ssw0rd*
- user@server2: *srv2-ex4MpL3P@ssw0rd-srv2* -> *srv2-n3wP@ssw0rd-srv2*
- user@server3: *ex4MpL3P@ssw0rd-srv3* -> *n3wP@ssw0rd-srv3*
- user@server4: *srv4-ex4MpL3P@ssw0rd* -> *srv4-n3wP@ssw0rd*
- user@server5: *ex4MpL3P@ssw0rd* -> *srv5-n3wP@ssw0rd*
- user@server6: *ex4MpL3P@ssw0rd* (unchanged since login failed)
