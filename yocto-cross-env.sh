if [[ -z "${OETMP}" ]]; then
	echo "Need an OETMP defined!"
	exit 1
fi

MACHINE=overo

# eventually there will be this option
# MACHINE=duovero

export SYSROOTSDIR=${OETMP}/sysroots
export CROSSBINDIR=${SYSROOTSDIR}/`uname -m`-linux/usr/bin
export CROSSTOOLDIR=${CROSSBINDIR}/armv7a-vfp-neon-poky-linux-gnueabi
export CROSSSTOOL_PREFIX=arm-poky-linux-gnueabi-

export KERNELDIR=${SYSROOTSDIR}/${MACHINE}/usr/src/kernel

export SGX_SDK_ROOT=${HOME}/Graphics_SDK_4_08_00_01

# change to gfs_rel_es3.x for OMAP35xx builds
export SGX_BIN_DIR=${SGX_SDK_ROOT}/gfx_rel_es5.x

export QMAKEQTE="/opt/qte/bin/qmake -spec qws/linux-overo-g++"


PATH=${PATH}:${CROSSBINDIR}:${CROSSTOOLDIR}

