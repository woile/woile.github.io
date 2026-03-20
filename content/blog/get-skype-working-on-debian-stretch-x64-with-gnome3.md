+++
title = "Get Skype working on Debian Stretch x64 with GNOME3"
description = "Skype working in Debian Stretch"
date = 2016-09-19
tags = ["skype", "debian", "linux"]
aliases = ["/posts/get-skype-working-on-debian-stretch-x64-with-gnome3"]
+++

> WARNING
>
> This info is no longer relevant. Skype no longer exists.
> And many good apps support calls or videocalls

Some alternatives I recommend:

- [matrix](https://matrix.org/ecosystem/clients/)
- [signal](https://signal.org/)
- [discord](https://discordapp.com/)

If you really need to install this software, for legacy reasions, then proceed at your own risk.

I got tired of installing skype so many times looking all over the
internet, so I\'ll leave here some easy steps to make it work in Debian
Stretch with GNOME 3.21 (and may be some earlier versions). It\'s just
that there is not enough information around. Debian recommends to
install the .deb package, but it usually does not work.

As you probably know, skype is a 32bit software, so we\'ll need to
enable that in our repository manager. Next we\'ll install some
dependencies and finally we\'ll get the file in the specified folder.

``` bash
sudo dpkg --add-architecture i386
sudo apt-get install libxv1:i386 libqtdbus4:i386 libqtwebkit4:i386 libxss1:i386
mkdir ~/.apps/
wget -qO- https://download.skype.com/linux/skype-4.3.0.37.tar.bz2 | tar jx -C ~/.apps/
```

Instead of launching the `./skype` script, you can add a `skype.desktop`
file to your gnome environment.

The location for this file is either `~/.local/share/applications`, for
the current user, or `/usr/share/applications` for everyone.

The content for your `skype.desktop`, should be something like this:

``` bash
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
```

PS: Remember to change the user for the one you are using.

Good luck!
