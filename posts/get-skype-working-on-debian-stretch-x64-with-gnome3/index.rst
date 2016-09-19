.. title: Get Skype working on Debian Stretch x64 with GNOME3
.. slug: get-skype-working-on-debian-stretch-x64-with-gnome3
.. date: 2016-09-19 07:56:03 UTC-03:00
.. tags:
.. category: skype, debian
.. link:
.. description: Skype working in Debian Stretch
.. type: text

If you really need to install this software, and you cannot use an alternative like **hangouts**, or **tox**, then this guide is for you.

I got tired of installing skype so many times looking all over the internet, so I'll leave here some easy steps to make it work in Debian Stretch with GNOME 3.21 (and may be some earlier versions). It's just that there is not enough information around.
Debian recommends to install the .deb package, but it usually does not work.


As you probably know, skype is a 32bit software, so we'll need to enable that in our repository manager. Next we'll install some dependencies and finally we'll get the file in the specified folder.

.. code-block:: bash

    sudo dpkg --add-architecture i386
    sudo apt-get install libxv1:i386 libqtdbus4:i386 libqtwebkit4:i386
    mkdir ~/.apps/
    wget -qO- https://download.skype.com/linux/skype-4.3.0.37.tar.bz2 | tar jx -C ~/.apps/



Instead of launching the :code:`./skype` script, you can add a :code:`skype.desktop` file to your gnome environment.

The location for this file is either :code:`~/.local/share/applications`, for the current user, or :code:`/usr/share/applications` for everyone.

The content for your :code:`skype.desktop`, should be something like this:


.. code-block:: bash

   [Desktop Entry]
   Name=Skype
   Comment=Skype Internet Telephony
   Exec=/home/**santiago**/.apps/skype-4.3.0.37/skype
   Icon=/home/**santiago**/.apps/skype-4.3.0.37/icons/SkypeBlue_96x96.png
   Terminal=false
   Type=Application
   Encoding=UTF-8
   Categories=Network;Application;
   MimeType=x-scheme-handler/skype;
   X-KDE-Protocols=skype
   X-GNOME-Bugzilla-Product=skype


PS: Remember to change the user for the one you are using.

Good luck!