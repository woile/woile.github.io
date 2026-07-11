+++
title = "Decrypt filesystem"
draft = true
+++

## Second option

Let's start opening a terminal and typing:

`lsblk`

Look for your encrypted partition, it might look something similar to:

```shell
nvme0n1        259:0    0 953.9G  0 disk
├─nvme0n1p1    259:1    0   512M  0 part
├─nvme0n1p2    259:2    0   488M  0 part
└─nvme0n1p3    259:3    0 952.9G  0 part
```

Then to decrypt:

```shell
cryptsetup luksOpen <path_to_encrypted> <name_for_unencrypted_partition>
# This will prompt a password
```

For example:

```shell
cryptsetup luksOpen /dev/mapper/nvme0n1p3 woile
```

Once decrypted type again:

`lsblk`

And you'll see your partition unencrypted, something like this:

```shell
nvme0n1        259:0    0 953.9G  0 disk
├─nvme0n1p1    259:1    0   512M  0 part
├─nvme0n1p2    259:2    0   488M  0 part
└─nvme0n1p3    259:3    0 952.9G  0 part
  └─woile 253:0    0 952.9G  0 crypt
```

Now it's time to mount the new partition

1. create a directory
2. mount unencrypted partition

```shell
mkdir /media/tmp_mount_location  # (1)
mount /dev/mapper/woile /media/tmp_mount_location  # (2)
```

That's it, if you go to /media/tmp_mount_location, your files should be there.

This is mostly a mental note for me.

Cheers!
