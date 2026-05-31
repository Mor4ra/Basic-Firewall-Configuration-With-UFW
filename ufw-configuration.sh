#!/bin/bash
sudo apt install ufw
ufw enable
ufw status verbose # show the current configuration for ufw, which is the default 'out-the-box' policy.
ufw allow ssh
