# Basic Firewall Configuration With UFW
- A hands-on exercise configuring UFW on Ubuntu.

## First steps
- choose our environment, for this specific exercise, I will be purely working within a kali vm with a nested LXC ubuntu container.
- First, we need to install `lxc` since it's not preinstalled in kali:

        ```
        sudo apt install lxc -y
        ```

- That should successfully install `lxc`, to verify run, `lxc-checkconfig`, you should see a wall of text showing features needed by LXC to function. Most
of them should be enabled.
- We're now going to utilize `lxc` to create a linux container, I'll be working with `Ubuntu 24.04 LTS Noble Numbat`, feel free to install a distro
of your choice.

        ```
        # I'm choosing to name my LXC container "ubuntu-ufw" as a callback to this exercise, I have also specified the distro version and architecture.
        sudo lxc-create -n ubuntu-ufw -t download -- -d ubuntu -r noble -a amd64
        ```

- To check if the container has been created, run:

        ```
        sudo lxc-ls -f # shows all currently installed LXC containers
        ```

- Next thing is starting the container, accessing it's shell and doing the exercise, easy peasy.

        ```
        # starting the container
        sudo lxc-start -n ubuntu-ufw
        # accessing the container's shell
        sudo lxc-attach -n ubuntu-ufw
        ```

- **Setting up our container** - LXC containers are minimal when first installed, we're going to need a few fundamental tools like `ip` and `ping` to check
our network configuration and test incoming and outgoing connections. `ping` is available in the `iputils-ping` utility and `ip` in `iproute2`.

        ```
        # refresh sources.list
        apt update
        # installing needed utilities needed + UFW
        apt install ufw iproute2 iputils-ping
        ```

    - We're required to configure the firewall to allow `ssh` and deny `http` traffic. First we'll need to install the services in our container then
    proceed to configuring the firewall to follow these requirements.

            ```
            apt install openssh-server && apt install apache2
            ```

## Firewall Setup & Configuration
- UFW is utilized by `ufw` command line utility.(see `man ufw`)
- Before doing anything, we should enable UFW & check it's current status/configuration:

        ```
        ufw enable
        ufw status verbose
        ```

- In the status output, we can see that UFW is on, logging  is on, the default policy and firewall profiles for installed applications are inactivated:

        ```
        root@ubuntu-ufw:/# ufw status verbose
        Status: active
        Logging: on (low)
        Default: deny (incoming), allow (outgoing), deny (routed)
        New profiles: skip
        ```

- let's go on to configuring our firewall to allow SSH but block HTTP traffic. This should be easy as UFW's policy is deny by default, so we only need to
allow ssh:

        ```
        ufw allow ssh
        ```

- checking again the UFW status, we see that SSH is allowed:

        ```
        root@ubuntu-ufw:/# ufw status verbose
        Status: active
        Logging: on (low)
        Default: deny (incoming), allow (outgoing), deny (routed)
        New profiles: skip

        To                         Action      From
        --                         ------      ----
        22/tcp                     ALLOW IN    Anywhere                  
        22/tcp (v6)                ALLOW IN    Anywhere (v6)
        ```

- Before we try to SSH into our container from the host, we first have to edit the `/etc/ssh/sshd_config` file to allow Root Login by setting
`Permit-RootLogin` to `yes` and uncommenting this line. After this we restart the ssh service, `systemctl restart ssh` so it can now use our new version
of the configuration file.
- Then again, we do sort of the same thing but on the host, we edit the `/etc/ssh/ssh_config` - this is the configuration file for outgoing ssh connections.
We look for the line `PasswordAuthentication` and set it to `yes` then uncomment the line.  With this in place, we should be able to ssh into our container
from the host. something to note is that, this would probably won't work in the real world because you won't have access to the host's `/etc/ssh/sshd_config`
file unless you escalate your privileges to `root`.


        ```
        # from the host: (the container's ip is `10.0.3.203`)
        ┌──(kali㉿kali)-[~/Basic-Firewall-Configuration-With-UFW]
        └─$ ssh root@10.0.3.203      
        The authenticity of host '10.0.3.203 (10.0.3.203)' can't be established.
        ED25519 key fingerprint is: SHA256:B2K8ETiFUS+nYPap2IEXYjaPxkxFhj3gnxTINI5qV1g
        This key is not known by any other names.
        Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
        Warning: Permanently added '10.0.3.203' (ED25519) to the list of known hosts.
        root@10.0.3.203's password: 
        Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.19.14+kali-amd64 x86_64)

        * Documentation:  https://help.ubuntu.com
        * Management:     https://landscape.canonical.com
        * Support:        https://ubuntu.com/pro

        The programs included with the Ubuntu system are free software;
        the exact distribution terms for each program are described in the
        individual files in /usr/share/doc/*/copyright.

        Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
        applicable law.

        root@ubuntu-ufw:~#
        ```

- SSH works! HTTP fails because it's blocked by default:

        ```
        ┌──(kali㉿kali)-[~/Basic-Firewall-Configuration-With-UFW]
        └─$ curl http://10.0.3.203

        ```

- The cursor just hangs then a timeout showing `curl` failed, meaning http traffic is blocked.

## Conclusion
- This exercise demonstrated the basic workflow of firewall management with UFW: define a default policy then explicitly allow what is needed.

