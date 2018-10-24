Overview

Configures an already-installed IRIX system.

Requirements

* Host with ansible installed
* IRIX target host with
    * telnet available
    
Usage:
Make a new file ~/.vault_pass.txt with your vault password in it.

Delete group_vars/default/vault.yml , and make your own file that looks like this:

---
su_password: your_passwd

Then encrypt it:
ansible-vault encrypt host_vars/default --vault-password-file ~/.vault_pass.txt


Then invoke ansible:
ansible-playbook  -i inventory.ini -u <your user> master_setup.yml -k  --become-method=su --vault-password-file ~/.vault_pass.txt

