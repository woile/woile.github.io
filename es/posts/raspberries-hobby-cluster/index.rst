.. title: Raspberry Pi hobby cluster
.. slug: raspberries-hobby-cluster
.. date: 2019-02-22 04:46:17 UTC-03:00
.. tags: kubernetes, docker, cluster, raspberry
.. category: containers
.. link:
.. description: set up a kubernetes cluster with raspberry pi
.. type: text

In this tutorial we are gonna try to setup a cluster in our home
server built with raspberries.

In another post I'll describe how to configure a Kubernetes cluster in our raspberries.

Kubernetes is a container orchestration tool, it can do all of this:

-  Automatic bin packing
-  Self-healing
-  Horizontal scaling
-  Service discovery and Load balancing
-  Automated rollouts and rollbacks
-  Secrets and configuration management
-  Storage orchestration
-  Long running jobs
-  Batch execution

.. TEASER_END

Hardware
--------

-  4x `Raspberry Pi 3 B+`_
-  4x `RJ45 Cat6 ethernet cable`_
-  4x `32GB Micro SDHC`_
-  4x `Micro USB cable`_
-  1x `Switch TP-LINK TL-SF1005D 5-Port 10/100Mbps Unmanaged Desktop`_
-  1x `Anker Port Wall Chargers`_
-  1x `USB to barrel`_ (optional)

Requirements
------------

-  unix system (linux or mac)
-  flash v2.2.0 `installation`_
-  hypriot OS v1.9.0 `download`_

SSH keys
--------

We need a SSH key in order to connect to the cluster without having to type
the password every time we access.

In case you don't have any, run this command and follow the steps.

.. code:: bash

    ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

Add the key to your ssh agent, assuming our keys generated are :code:`id_rsa`
and :code:`id_rsa.pub`.

.. code:: bash

    ssh-add ~/.ssh/id_rsa

You can find a more in depth explanation in this `tutorial`_

Creating cloud-init-config
--------------------------

The ``flash`` command line utility, uses a cloud-init-conf in order to configure the
debian system that it's going to be installed. We are gonna use hypriot debian,
which is optimized for containers.

Let's generate the conf using a template I've created, remember to update
the environment variables with your values.

+-----------------------------------+-----------------------------------+
| Variable                          | Description                       |
+===================================+===================================+
| ``USERNAME``                      | Username to login into the os     |
+-----------------------------------+-----------------------------------+
| ``SSH_PUBLIC_KEY``                | A public key to log in without    |
|                                   | typing the password.              |
+-----------------------------------+-----------------------------------+
| ``WIFI_SSID_NAME``                | The name of your wifi             |
+-----------------------------------+-----------------------------------+
| ``WIFI_PASSWORD``                 | Use                               |
|                                   | ``wpa_passphrase SSID PASSWORD``  |
|                                   | for preshared key                 |
+-----------------------------------+-----------------------------------+

.. code:: bash

    export USERNAME=willy
    export WIFI_SSID_NAME="Bla bla"
    export WIFI_PASSWORD="longandsecurepassword"
    export WIFI_COUNTRY=NL
    export TIMEZONE=$(curl -s https://ipapi.co/timezone)
    export SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

    curl -s https://gist.githubusercontent.com/Woile/51eca58047b6bd51c60eeae80d60ec14/raw/db05664b5e90a28472f139bc8757562c2ed13026/cloud-init-config-template.yaml | \
    sed -e "s/\${USERNAME}/$USERNAME/" \
    -e "s/\${WIFI_SSID_NAME}/$WIFI_SSID_NAME/" \
    -e "s/\${WIFI_PASSWORD}/$WIFI_PASSWORD/" \
    -e "s/\${WIFI_COUNTRY}/$WIFI_COUNTRY/" \
    -e "s|\${TIMEZONE}|$TIMEZONE|" \
    -e "s|\${SSH_PUBLIC_KEY}|$SSH_PUBLIC_KEY|" > cloud-init-config.yaml


Flashing SD cards
-----------------

Insert the SD card and find it with ``df``.

Flash the ``cloud-init-conf.yaml`` in all of your SD cards.
It's important to change the hostname per raspberry. Pay attention to param
``--hostname``.

For my 4 raspberries I am going to use these hostnames:

.. code:: bash

   willy-1
   willy-2
   willy-3
   willy-4

``flash -f --hostname willy-1 --device <device_found_using_df> -u cloud-init-config.yaml hypriotos-rpi-v1.9.0.img pv``

Example:

``flash -f --hostname willy-1 --device /dev/mmcblk0 -u cloud-init-config.yaml hypriotos-rpi-v1.9.0.img pv``

Plug the SD card on each raspberry and connect them to the wall.


Setting up the nodes
--------------------

To find the IPs of your raspberries run:

.. code:: bash

    # For Debian based OS
    sudo apt-get install arp-scan
    # For Mac
    brew install arp-scan

.. code:: bash

   ip a  # here found the interface, like wlp2s0
   sudo arp-scan --interface=<your_interface> --localnet

Connect to each one of them using ``ssh <username>@<hostname>``, because
we previosuly added the ssh key, we should not need to type a passsword.

Execute on each node the next steps.

Reset password
~~~~~~~~~~~~~~

.. warning::

    This is an important step!

Update your user’s password with ``passwd``. Remember that by default is ``hypriot``.

Configure Firewall
~~~~~~~~~~~~~~~~~~

For simplicity and in case you want to have a multi master cluster, we
are gonna allow ports for master kubernetes and for kubernetes workers.

Run this as root typing ``sudo su``

.. code:: bash

   ufw --force reset  # ok
   ufw allow ssh
   ufw allow 6443 # Kubernetes API (master)
   ufw allow 80  # HTTP
   ufw allow 443  # HTTPS
   ufw allow 8443  # kubectl proxy
   ufw allow 10250  # Kubelet API (master and worker)
   ufw allow 10251  # kube-scheduler (master)
   ufw allow 10252  # kube-controller-manager (master)
   ufw allow 2379:2380/tcp  # etcd server client API (master)
   ufw allow 30000:32767/tcp  # NodePort Services** (worker)
   ufw default deny incoming
   yes | ufw enable

`Ports used by kubernetes`_

Configuring master node
-----------------------

Choose one of the raspberries as the master, I use ``willy-1`` as
master.

Set static IP
~~~~~~~~~~~~~

Edit ``/etc/network/interfaces.d/eth0`` and set it to

.. code:: ini

   allow-hotplug eth0
   iface eth0 inet static
   address 10.0.0.1
   netmask 255.255.255.0
   broadcast 10.0.0.255
   gateway 10.0.0.1

Reboot to claim the IP ``10.0.0.1`` in your internal cluster’s network
(the switch network)

Allocate addresses to the worker nodes using DHCP
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The cloud-init template already includes ``isc-dhcp-server``

Edit ``/etc/default/isc-dhcp-server``, comment out ``# INTERFACESv6=""``
and set ``INTERFACESv4="eth0"``

Or run this

.. code:: bash

    sudo sed -e '/INTERFACESv6=/ s/^#*/#/' -e 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' -i /etc/default/isc-dhcp-server

Backup and edit ``/etc/dhcp/dhcpd.conf``. Set it like this:

.. code:: ini

    option domain-name "willy.home"; # Set a domain name, can be anything
    option domain-name-servers 8.8.8.8, 8.8.4.4; # Use Google DNS by default, you can substitute ISP-supplied values here
    subnet 10.0.0.0 netmask 255.255.255.0 { # We'll use 10.0.0.X for our subnet
        range 10.0.0.1 10.0.0.50;
        option subnet-mask 255.255.255.0;
        option broadcast-address 10.0.0.255;
        option routers 10.0.0.1;
    }
    default-lease-time 600;
    max-lease-time 7200;
    authoritative;

Restart service ``sudo systemctl restart dhcpcd.service``

Now our master will start assigning addresses to the other nodes.

In case it’s not assigning IPs, try unplugging from the switch and
restarting all the other nodes but the master. You can check the IPs by
doing ``ip a`` or ``hostname -I``, remember that this is the range
``range 10.0.0.1 10.0.0.50``

Our cluster is set up now.

Credits
-------

This tutorial is based on `Kubernetes: Up and Running`_, `Hypriot \|
Setup Kubernetes on a Raspberry Pi Cluster easily the official way!`_ and
`Production Hobby Cluster`_.

.. _Raspberry Pi 3 B+: https://www.amazon.de/gp/product/B07BDR5PDW/ref=oh_aui_detailpage_o04_s01?ie=UTF8&psc=1
.. _RJ45 Cat6 ethernet cable: https://www.amazon.de/gp/product/B01AWK81VM/ref=oh_aui_detailpage_o04_s03?ie=UTF8&psc=1
.. _32GB Micro SDHC: https://www.amazon.de/gp/product/B06XFSZGCC/ref=oh_aui_detailpage_o04_s02?ie=UTF8&psc=1
.. _Micro USB cable: https://www.amazon.de/gp/product/B016BEVNK4/ref=oh_aui_detailpage_o02_s00?ie=UTF8&psc=1
.. _Switch TP-LINK TL-SF1005D 5-Port 10/100Mbps Unmanaged Desktop: https://www.amazon.de/gp/product/B000FNFSPY/ref=oh_aui_detailpage_o04_s03?ie=UTF8&psc=1
.. _Anker Port Wall Chargers: https://www.amazon.de/gp/product/B00VUGOSWY/ref=oh_aui_detailpage_o04_s04?ie=UTF8&psc=1
.. _USB to barrel: https://www.amazon.de/DELOCK-Kabel-USB-Power-Hohlstecker/dp/B001XM49Y2/ref=sr_1_7?s=computers&ie=UTF8&qid=1540141485&sr=1-7&keywords=usb+to+barrel
.. _`Kubernetes: Up and Running`: http://shop.oreilly.com/product/0636920043874.do
.. _Hypriot \| Setup Kubernetes on a Raspberry Pi Cluster easily the official way!: https://blog.hypriot.com/post/setup-kubernetes-raspberry-pi-cluster/
.. _installation: https://github.com/hypriot/flash/tree/2.2.0#installation
.. _download: https://github.com/hypriot/image-builder-rpi/releases/download/v1.9.0/hypriotos-rpi-v1.9.0.img.zip
.. _tutorial: https://confluence.atlassian.com/bitbucketserver/creating-ssh-keys-776639788.html
.. _Ports used by kubernetes: https://kubernetes.io/docs/setup/independent/install-kubeadm/#check-required-ports
.. _Production Hobby Cluster: https://imti.co/hobby-cluster/#swap