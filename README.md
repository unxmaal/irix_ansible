# Overview

Configures an already-installed IRIX system.

# Requirements

* Host with ansible installed
* IRIX target host with telnet available

# Usage:
Make a new file ~/.vault_pass.txt with your vault password in it. If your password is 'password', the file will only contain 'password'.

Delete group_vars/default/vault.yml , and make your own file that looks like this:

```
---
su_password: your_passwd
```

Then encrypt it:
```
ansible-vault encrypt group_vars/default/vault.yml --vault-password-file ~/.vault_pass.txt
```

## Phase 1
Examine and modify the inventory.yml file (in the top level directory) to match your local requirements.

Run the bootstrap playbook on a system that has just been installed. It expects the root password to be blank. 

This playbook will 
  * create an 'ansible' user
  * copy several bundles via ftp
  * install wget, python, and openssh
  * start sshd

```
ansible-playbook -i inventory.yml bootstrap.yml --vault-password-file ~/.vault_pass.txt
```


## Phase 2
Examine and modify the master_setup playbook to your liking, then run it. You can comment out unneeded roles.
* be sure and change the username at the bottom of master_setup to your selected user for the SGI

The master_setup playbook currently
  * installs nekodeps
  * installs base packages
  * sets up bash as an available shell
  * adds a user
  * enables remote x11
  * configures ntp
  * installs findutils
  * performs security hardening

```
ansible-playbook  -i inventory.yml -u ansible master_setup.yml -k  --become-method=su --vault-password-file ~/.vault_pass.txt
```
When prompted for "SSH password", enter 'ansible'.


When provisioning on OSX you need the sshpass package:
```
brew install http://git.io/sshpass.rb
```


# Reading
http://www.sillypages.org/sgi 
http://nixdoc.net/man-pages/irix/man1/pwconv.1.html

https://techpubs.jurassic.nl/manuals/0650/admin/IA_ConfigOps/sgi_html/index.html
https://techpubs.jurassic.nl/manuals/0650/admin/IA_ConfigOps/sgi_html/ch05.html#LE15895-PARENT
