  SGX QT BUILD README
--------------------------------------------------------------------------------

Some notes for getting Qt OpenGL working on Gumstix Overo (draft)

The goal is to get a working 3.2 kernel Overo system with Qt embedded and OpenGL
support so we can run our custom Qt OpenGL apps on the Gumstix.

These instructions could probably be modified to support Qt-X11, but I don't use
X with the Gumstix and have not tried that.

The kernel and rootfs were built using Yocto. Qt and the TI graphics SDK are 
built outside of Yocto/OE, but using the same cross-build tools.

The assumption for all of this is that you have already successfully built a 
Gumstix image with a 3.2 kernel using Yocto. 

If your image contains Qt embedded then you should create a new image recipe 
that omits that. Qt will be built and installed separately.

The PowerVR drivers are closed-source. You can get them as part of the TI Linux 
Graphics SDK. There are different drivers based on the version of the SGX core. 
I'll be targeting the DM3730 core in this document, but I will point out the 
small configuration difference for the OMAP3530 core. I did verify the OMAP35xx
builds work with recent cores. You'll have to use a different version of the
TI Graphics SDK if your Gumstix/SGX core is too old.

I am using the soft-fp builds of the SGX driver currently. The 4.08.00.01 drivers
are available in a hard-fp version, but I haven't tried them yet.


--------------------------------------------------------------------------------
0.  OVERVIEW
--------------------------------------------------------------------------------

1) Patch the kernel DSS driver and rebuild the 3.2 kernel

2) Build the kernel modules

3) Build Qt with the powervr plugin

4) Copy components to the Gumstix SD card

5) Finish install on the Gumstix

6) Run some demos



For the example, I am using a Yocto build where my TMPDIR is at /oe5.

The meta-layer I am using is called meta-pansenti. There is no requirement to 
use this layer, but paths referenced will have this name in them.

You can get it here : https://github.com/Pansenti/meta-pansenti

I'm using the pansenti-sgx-image recipe for the rootfs.

The kernel comes from Steve Sakoman's repository.

git://www.sakoman.com/git/linux-omap-2.6.git


--------------------------------------------------------------------------------
1. PATCH THE KERNEL DSS DRIVER AND REBUILD THE 3.2 KERNEL
--------------------------------------------------------------------------------

1) Patch the DSS driver in the kernel

The kernel recipe is here 

        meta-pansenti/recipes-kernel/linux/linux-sakoman_3.2.bb


Copy this patch file in sgx-qt-build/kernel-3.2/0001-Revert...-v3.2.patch to your
kernel recipe directory. (The patch comes from Robert Nelson. See the References
section at the end of this document.)

For instance, in my repo the kernel recipe directory would be this

        <top-level>/meta-pansenti/recipes-kernel/linux/linux-sakoman-3.2/


Then modify the kernel recipe, linux-sakoman_3.2.bb to add the DSS patch.
Here is what mine looks like. The libertas patch is unrelated.

        require linux.inc

        DESCRIPTION = "Linux kernel for OMAP processors"
        KERNEL_IMAGETYPE = "uImage"

        COMPATIBLE_MACHINE = "overo"

        BOOT_SPLASH = ""

        PV = "3.2"

        S = "${WORKDIR}/git"

        SRCREV = "${AUTOREV}"
        SRC_URI = "git://www.sakoman.com/git/linux-omap-2.6.git;branch=omap-3.2;protocol=git \
	           file://defconfig \
                   file://libertas-async-fwload.patch \
                   file://0001-Revert-OMAP-DSS2-remove-update_mode-from-omapdss-v3.2.patch \
                  "


2) Rebuild the kernel with 

        bitbake -c cleansstate virtual/kernel
        bitbake virtual/kernel
	

3) Rebuild your image. It should not include Qt, but should include the following
if you plan on using a touchscreen.

        tslib_calibrate
        tslib_tests
        tslib_conf
        fbset
        fbset-modes


4) You should probably install your new image on an SD card and make sure 
everything is still working before proceeding.


--------------------------------------------------------------------------------
2. BUILD THE KERNEL MODULES
--------------------------------------------------------------------------------

TI documentation for their Graphics SDK can be found here

http://processors.wiki.ti.com/index.php/Graphics_SDK_Quick_installation_and_user_guide

From the above wiki link in the table in the 'About Graphics SDK', it shows
that there are  differences in the SGX Core revisions used by the OMAP35xx and 
DM37xx SOCs.

As a result, the binaries from the SDK are specific to the SGX core you are
targetting.


1) Download the TI Graphics SDK from here

http://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/gfxsdk/

I am using version 4.08.00.01 of the SDK for this example.


2a) If you are on a 64-bit platform, I believe you need the 32-bit compatibility
libraries to execute the bin file. You should do this first. 

Ubuntu users can use this command

        sudo apt-get install ia32-libs

If you are on a 32-bit platform, this isn't necessary.


2b) Extract the SDK by running the binary: Graphics_SDK_setuplinux_4_08_00_01.bin 

The default extract location is 

        ~/Graphics_SDK_4_08_00_01 

which I'll use.

When prompted, you should select es3.x, es5.x and the SDK.


3) Add some Yocto built cross-tools to your PATH.

I have a script that I use for this kind of thing I call yocto-cross-env.sh.
It can be found in the root of the sgx-qt-build/ directory.

Run it like this substituting the OETMP for your Yocto build.

        scott@quad:~$ export OETMP=/oe5
        scott@quad:~$ source ~/sgx-qt-build/yocto-cross-env.sh

The default in yocto-cross-env.sh is for Overo Storm boards (DM37xx).
Change the SGX_BIN_DIR variable in yocto-cross-env.sh to ...es3.x.. to target
OMAP35xx boards. 

4) Copy the example Rules.make to the SDK directory.

The example is sgx-qt-build/4.-8.00.01/Rules.make.

        scott@quad:~$ cp ~/sgx-qt-build/4.08.00.01/Rules.make ~/Graphics_SDK_4_08_00_01/

You should not have to modify it.


5) Apply a small kernel definition patch to the SDK source. (A renaming of a
definition from ..FREEZEABLE.. to ..FREEZABLE..)

Copy the patch to the Graphics SDK directory

        scott@quad:~$ cd Graphics_SDK_4_08_00_01
        scott@quad:~/Graphics_SDK_4_08_00_01$ cp ~/sgx-qt-build/4.08.00.01/omaplfb_freezable.patch .

Apply the patch

        scott@quad:~/Graphics_SDK_4_08_00_01$ patch -p1 < omaplfb_freezable.patch


6) Running 'make help' will show you the build options available.

        scott@quad:~/Graphics_SDK_4_08_00_01$ make help

        Usage (for build): make BUILD={debug | release} OMAPES={3.x | 5.x | 6.x | 8.x} FBDEV={yes | no} SUPPORT_XORG= {1 | 0 }  all
              Platform                                  OMAPES 
              --------                                  ------ 
              OMAP35x(SGX core 1.2.1)                    3.x   
              OMAP37x/AM37x(SGX core 1.2.5)              5.x   
              816x(389x)/814x(387x)(SGX core 1.2.5)      6.x   
              335x(SGX core 1.2.5 )                      8.x   
        --> Specifying OMAPES is mandatory. BUILD=release and FBDEV=yes SUPPORT_XORG=0(not enabled) by default
        Usage (for install): make BUILD=(debug | release} OMAPES={3.x | 5.x | 6.x | 8.x} EGLIMAGE={1 | 0} install
        --> See online Graphics Getting Started Guide for further details.


7) To build the kernel drivers for the DM3730, run the following

        scott@quad:~/Graphics_SDK_4_08_00_01$ make BUILD=release OMAPES=5.x FBDEV=yes


Ignore the warnings you get about devmem2.

When it completes, you should see some kernel modules in the gfx_rel_es5.x subdirectory.

        scott@quad:~/Graphics_SDK_4_08_00_01$ ls -l gfx_rel_es5.x/*.ko
        -rw-rw-r-- 1 scott scott  130076 Oct 24 13:54 gfx_rel_es5.x/bufferclass_ti.ko
        -rw-rw-r-- 1 scott scott  320884 Oct 24 13:54 gfx_rel_es5.x/omaplfb.ko
        -rw-rw-r-- 1 scott scott 2129793 Oct 24 13:54 gfx_rel_es5.x/pvrsrvkm.ko


If you were building for the OMAP3530, you would have run this make command

        scott@quad:~/Graphics_SDK_4_08_00_01$ make BUILD=release OMAPES=3.x FBDEV=yes


The OMAP3530 kernel modules will be in the gfx_rel_es3.x subdirectory.


That's all for the PowerVR drivers. 


--------------------------------------------------------------------------------
3. BUILD QT WITH THE POWERVR PLUGIN
--------------------------------------------------------------------------------

These instructions are for Qt version 4.8.3. This was the latest Qt4 version when
I wrote this.

The cross-built Qt will be installed into /opt on both the build workstation and
the Gumstix root filesystem. You will need permissions in /opt.


1) Download the Qt source code from here

        http://releases.qt-project.org/qt4/source/qt-everywhere-opensource-src-4.8.3.tar.gz


2) Extract the Qt source code to a convenient directory for building. I'm going 
to use my home directory.

        scott@quad:~$ tar xzf /oe-sources/qt-everywhere-opensource-src-4.8.3.tar.gz


3) (Optional) Make a shorter soft link for convenience
    
        scott@quad:~$ ln -s qt-everywhere-opensource-src-4.8.3/ qt
        
        scott@quad:~$ ls -ld qt*
        lrwxrwxrwx  1 scott scott   35 Oct 24 14:30 qt -> qt-everywhere-opensource-src-4.8.3/
        drwxr-xr-x 16 scott scott 4096 Sep 12  2011 qt-everywhere-opensource-src-4.8.3


4) Apply this pvrqwswsegl.patch to the Qt source. 

Copy the patch to the Qt source directory.

        scott@quad:~$ cp sgx-qt-build/qt-4.8.3/pvrqwswsegl.patch qt

Apply the patch

        scott@quad:~$ cd qt
        scott@quad:~/qt$ patch -p1 < pvrqwswsegl.patch


5) Create a make specification (mkspec) for the overo cross build.

There is an example mkspec in the sgx-qt-build directory.

        scott@quad:~/qt$ cd mkspecs/qws
        scott@quad:~/qt/mkspecs/qws$ cp -r ~/sgx-qt-build/4.08.00.01/linux-overo-g++ .



6) Create a new include directory in the TI Graphics SDK directory that Qt will
look for.
      
        scott@quad:~/qt/mkspecs/qws/linux-overo-g++$ cd ~/Graphics_SDK_4_08_00_01/include
        scott@quad:~/Graphics_SDK_4_08_00_01/include$ mkdir GLES
        scott@quad:~/Graphics_SDK_4_08_00_01/include$ cp OGLES2/EGL/eglplatform.h GLES/


6) Configure Qt, targeting /opt for the eventual install.

First change permissions for /opt.

        scott@quad:~/qt$ sudo chown -R scott:scott /opt

Copy the qt-configure.sh script to the qt directory.

        scott@quad:~/qt$ cp ~/sgx-qt-build/qt-4.8.3/qt-configure.sh .

Make sure you have the environment setup if you are running this in a new shell
then run this again substituing your OETMP.

        scott@quad:~$ export OETMP=/oe5
        scott@quad:~$ source ~/sgx-qt-build/yocto-cross-env.sh

Run the script, answering the licensing questions as appropriate. I choose LGPL.
        
        scott@quad:~/qt$ ./qt-configure.sh


7) Build Qt

        scott@quad:~/qt$ make 

Optionally, and for a big speed improvement, add -j N parameter to make. N should
be the number of cpu cores you want to use. 

For example

        scott@quad:~/qt$ make -j6


8) Install Qt on the local workstation to the /opt directory. This just collects
the libs, headers and demos/examples that need to go to the target into one 
location. They'll be copied to the Gumstix SD card in another step.

Run the install step like this
        
        scott@quad:~/qt$ make install


You should have a new directory /opt/qte



--------------------------------------------------------------------------------
4. COPY COMPONENTS TO THE GUMSTIX SD CARD
--------------------------------------------------------------------------------

Setup your SD card as you usually would with a boot partition and rootfs.

On the system I writing this on, the SD card shows up as /dev/sdb. 
Remount the rootfs partition and copy over the TI Graphics components and the 
Qt software that was built above.

Mount the Gumstix rootfs partition

        scott@quad:~$ sudo mount /dev/sdb2 /media/card

Create an /opt directory on the Gumstix rootfs

        scott@quad:~$ sudo mkdir /media/card/opt

Copy the TI Graphics stuff

        scott@quad:~$ sudo cp -r ~/Graphics_SDK_4_08_00_01/gfx_rel_es5.x /media/card/opt

For OMAP35xx builds, copy gfx_rel_es3.x

        scott@quad:~$ sudo cp -r ~/Graphics_SDK_4_08_00_01/gfx_rel_es3.x /media/card/opt


Copy Qt

        scott@quad:~$ sudo cp -r /opt/qte/ /media/card/opt

Unmount the SD card

        scott@quad:~$ sync
        scott@quad:~$ sudo umount /dev/sdb2


Put the SD card in the Gumstix and boot it.

--------------------------------------------------------------------------------
5. Finish install on the Gumstix
--------------------------------------------------------------------------------

1) Install the GFX components. This copies various GFX scripts, libraries, 
kernel modules and demo programs to standard locations.

From here out, substitute gfx_rel_es3.x for gfx_rel_es5.x if you built for an
OMAP35xx system.

        root@overo:~# cd /opt/gfx_rel_es5.x/
        root@overo:/opt/gfx_rel_es5.x# ./install.sh

You can ignore the message to reboot.

Run depmod to let the system know about the new drivers

        root@overo:/opt/gfx_rel_es5.x# depmod


2) The PowerVR software needs an initialization file that tells it about Qt.
Create an /etc/powervr.ini file that looks like this

        [default]
        WindowSystem=libpvrQWSWSEGL.so

Note: If you are interested in running non-Qt demos that came with the TI SDK
then you will want another library in place of libpvrQWSWSEGL.so.
TODO: Add the reference doc for this.


3) Add the Qt libraries to the library path. 

Add this line to /etc/ld.so.conf

        /opt/qte/lib

Then force a refresh of the run-time linker database

        root@overo:~# rm /etc/ld.so.cache
        root@overo:~# ldconfig -v


4) Load the kernel drivers. 

There is a script to do this in /etc/init.d called rc.pvr.

        root@overo:~# /etc/init.d/rc.pvr start

        root@overo:~# lsmod
        Module                  Size  Used by
        omaplfb                11582  0 
        pvrsrvkm              160943  1 omaplfb
        libertas_sdio          16208  0 
        libertas               99103  1 libertas_sdio
        cfg80211              165642  1 libertas
        rfkill                 17069  1 cfg80211
        lib80211                5017  1 libertas
        firmware_class          6797  2 libertas_sdio,libertas
        ads7846                10347  0 

Your modules may differ based on your kernel config. The important ones for this
are omaplfb and pvrsrvkm.

You can add rc.pvr to your startup scripts. 

--------------------------------------------------------------------------------
6. RUN SOME DEMOS
--------------------------------------------------------------------------------

At this point, I've only used a DVI connected display with this Qt/OpenGL system.

The kernel boot params that I've tried are

        vram=12M
        omapdss.def_disp=dvi

with the following resolutions

        omapfb.mode=dvi:1680x1050MR-16@60
        omapfb.mode=dvi:1280x1024MR-16@60
        omapfb.mode=dvi:1024x768MR-16@60
and
        omapfb.mode=dvi:640x480MR-32@60
        
You can adjust these settings in your u-boot environment.


There are some Qt demos under /opt/qte/examples/opengl

A fun one to try is hellogl_es2.

        root@overo:~# cd /opt/qte/examples/opengl/hellogl_es2
        root@overo:/opt/qte/examples/opengl/hellogl_es2# ./hellogl_es2 -qws -display powervr


For the 32-bit color 640x480 mode you have to specify a proper rgba setting first
or you get error like (3) in the troubleshooting section.


        
--------------------------------------------------------------------------------
Troubleshooting
--------------------------------------------------------------------------------

1) You get the following error when running the hellogl_es2 demo

        root@overo:/opt/qte/examples/opengl/hellogl_es2# ./hellogl_es2 -qws -display powervr
        QEglContext::createSurface(): Unable to create EGL surface, error = 0x300b

You likely forgot or improperly configured /etc/powervr.ini


2) You get the following loading the kernel modules (/etc/init.d/rc.pvr start)

        PVR_K: (FAIL) SGXInit: Incompatible HW core rev (10003) and SW core rev (10201).

Your SGX core is too old. It is reporting version 1.0.3 and version 1.2.1 is 
the minimum supported by this SDK.


3) You get the following error running demos on the touchscreen

        root@overo:/opt/qte/examples/opengl/hellogl_es2# ./hellogl_es2 -qws -display powervr
        /dev/fb0: could not find a suitable PVR2D pixel format
        Could not initialize EGL display - are the drivers loaded?
        /dev/fb0: could not find a suitable PVR2D pixel format
        powervr: driver cannot connect
        Aborted

The framebuffer needs to be reconfigured. You can use fbset to fix this.

The default fbset that gets installed is part of BusyBox and doesn't support
framebuffer mode changes like this.

If you included the standalone fbset package in your Yocto image recipe, version
2.1.x, then the following will work.

First unload the sgx kernel drivers

        root@overo:# /etc/init.d/rc.pvr stop

Then change the framebuffer.

Check the current settings

        root@overo:~# fbset

        mode "640x480-61"
            # D: 24.000 MHz, H: 30.000 kHz, V: 60.730 Hz
            geometry 640 480 640 480 32
            timings 41666 80 48 3 7 32 4
            rgba 8/16,8/8,8/0,0/0
        endmode

Change them

        root@overo:~# fbset -rgba 8/16,8/8,8/0,8/24

Check that they took.

        root@overo:~# fbset

        mode "640x480-61"
            # D: 24.000 MHz, H: 30.000 kHz, V: 60.730 Hz
            geometry 640 480 640 480 32
            timings 41666 80 48 3 7 32 4
            rgba 8/16,8/8,8/0,8/24
        endmode

Reload the sgx drivers

        root@overo:~# /etc/init.d/rc.pvr start


After that you can run the hellogl_es2 example and it should run at >100 fps
on a DM37xx at least.



--------------------------------------------------------------------------------      
References
--------------------------------------------------------------------------------

Robert Nelson's DSS patch for 3.2

https://github.com/RobertCNelson/stable-kernel/tree/master/patches/sgx/0001-Revert-OMAP-DSS2-remove-update_mode-from-omapdss-v3.2.patch


TI documentation for their Graphics SDK can be found here

http://processors.wiki.ti.com/index.php/Graphics_SDK_Quick_installation_and_user_guide


