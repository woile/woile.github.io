.. title: Moving from docker alpine to slim
.. slug: moving-from-docker-alpine-to-slim
.. date: 2019-01-13 12:34:43 UTC-03:00
.. tags: linux python containers alpine slim debian
.. category: docker
.. link:
.. description:
.. type: text

I've been running a docker python3.x image for a long time.
I've used the base version, the slim and the alpine.

Initially I moved from the base python3.6 to the python3.6-slim and everything
went great. The main win was that no change was required in the Dockerfile,
it was smaller and more secure (less dependencies, more security, right?)

After a while, I decided to move from slim to alpine, because of the size benefit.
While doing the migration I found these drawbacks:

**Renaming dependencies**. I had to convert from :code:`apt` to :code:`apk` for every dependency.

**Working with edge**. There's always a problem with the edge repository.
Sometimes it's down. Sometimes the packages are broken.
You have to dig a lot in order to have a proper configuration.
Like using :code:`--no-cache` flag in apk. Or setting up the edge repo, then having to upgrade :code:`apk-tools`

This kind of problems break our pipeline when there's no new commit. And I don't want this.
That's why I've decided to move back to :code:`slim`.

Don't get me wrong, alpine is great, small and secure, and if you don't have many edge dependencies,
I guess it'll work flawlessly, and I would totally use it.
But our image unfortunately has dependencies like postgis, and proj4, which fail a lot in alpine.

But my story is not over with alpine, I'll try it again in the future.
I know with time it will get better and better, and I'll understand it more and more.
