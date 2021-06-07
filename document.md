---
title: How to build `libffmpeg.so`\linebreak
       for use in Chrome(ium) and derivatives.
author: Gustav (Gego of Xaren)
date: 2020-06-07
geometry: margin=2cm
papersize: a4
mainfont: DejaVu Serif
fontsize: 12pt
---

# Abstract
When streaming games to a web browser, the decode lag[^decode-lag] can be very
high on older systems when using generic x86_64/AMD64. This can be mitigated
by compiling `libffmpeg.so` from source using a specific set of optimisations.

[^decode-lag]: The delay that occurs from when the browser gets the data to
               decode and when the browser renders the image to the screen.

This note provides information on how to compiling `ffmpeg` and it's libraries
from source and how to produce `libffmpeg.so` on a GNU/Linux system, as the
standard `make script` does not produce it.

The note will conclude with a table that the improvements can make a difference
in responsiveness.

# Introduction and Motivation
The author of was playing games on Stadia[^stadia] and using a plug-in for
Chrome(ium) measured that the decode time was higher than optimal when playing
intensive games (in the order of 10+ ms) running on his older
hardware[^hardware] without hardware acceleration, and the quite high CPU usage.
The author wanted to see if using a specific microarchitecture (m-arch)
would lower the decode lag.

[^stadia]: Google's cloud gaming service.

[^hardware]: CPU: AMD FX-8350 @ 4.000GHz, GPU: AMD Radeon RX 570 (8GB).

There there is no real documentation on how to produce `libffmpeg.so` by hand,
only a patch submitted to ffmpeg that was rejected
[(Le Cuirot, 2017)](#ref:LeCuirot). Le Cuirot's patch became basis for this
document.

# How to build `libffmpeg.so`

The fist step is to download the source code for ffmpeg. This can be done in
a number of ways, in this example the archive provided on ffmpeg's homepage will
be used.

```bash
# change directory to some place.
wget https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar -xf ffmpeg-snapshot.tar.bz2
cd ffmpeg
```

In this example the target CPU is the FX-8350, which uses the
Piledriver microarchitecture [(Wikipedia, Piledriver)](#ref:WikPiledriver),
which is AMD's 15th microarchitecture family. This would make it one of the
`bdver` class microarchitectures
[GCC Manual (2021)](#ref:GccManual).

Configure the build system for ffmpeg to use the correct architecture. This
could be a bit of trail-and-error to figure out, when building: target the
highest microarchitecture that in the cpu family that may work, (Here other
flags are provided to include most things with our build.) and then build the
programs and libraries:

```bash
./configure --enable-nonfree --enable-gpl --enable-version3\
            --enable-hardcoded-tables\
            --enable-pic --enable-lto\
            --arch=amd64 --cpu=bdver4\
            --disable-doc
make -j8
```

In the code listing above the microarchitecture is provided to the `--cpu=`
flag.

Then testing to see if it works:

```bash
./ffplay "path to testfile.mp4"
# and
./ffplay "path to testfile.webm"
```

In this case the test resulted in a segmentation fault, so using `--cpu=bdver3`
was tested instead, and worked. The configuration used can be seen below.
Additional added a some `-mtune` and `-O2` options to make sure that the
binaries are tuned to the architecture and optimised.

```bash
./configure --enable-nonfree --enable-gpl --enable-version3\
            --enable-hardcoded-tables\
            --enable-pic --enable-lto\
            --extra-cflags='-mtune=bdver3 -O2'\
            --extra-cxxflags='-mtune=bdver3 -O2'\
            --extra-objcflags='-mtune=bdver3 -O2'\
            --arch=amd64 --cpu=bdver3\
            --disable-doc
```
Note that it may seem that the command has frozen, but just give it a few
seconds.

Building of the final library is very easy:

```bash
gcc -shared -fPIC\
    libavcodec/libavcodec.a\
    libavdevice/libavdevice.a\
    libavfilter/libavfilter.a\
    libavformat/libavformat.a\
    libavutil/libavutil.a\
    libpostproc/libpostproc.a\
    libswresample/libswresample.a\
    libswscale/libswscale.a\
    -o libffmpeg.so
```

# Testing and Results
TODO

# Refrences
[](){#ref:LeCuirot} _Le Cuirot, J,_ 2017, [FFmpeg-devel] build: Allow libffmpeg 
to be built for Chromium-based browsers, URL: 
[https://patchwork.ffmpeg.org/project /ffmpeg/patch/20170728100716.8143-1-chewi@gentoo.org/](https://patchwork.ffmpeg.org/project/ffmpeg/patch/20170728100716.8143-1-chewi@gentoo.org/)
, date read: 2021-06-07.

[](){#ref:WikPiledriver} _Wikipedia,_ Piledriver (microarchitecture), URL: 
[https://en.wikipedia.org/wiki/Piledriver_(microarchitecture)](https://en.wikipedia.org/wiki/Piledriver_(microarchitecture))
, date read: 2021-06-07.

[](){#ref:GccManual} _GCC Manual,_ 2021, version 11.1, pp. 142-152, URL:
[https://gcc.gnu.org/onlinedocs/gcc-11.1.0/gcc.pdf](https://gcc.gnu.org/onlinedocs/gcc-11.1.0/gcc.pdf)
, date read: 2021-06-07.

