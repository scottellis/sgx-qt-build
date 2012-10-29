if [[ -z "${OETMP}" ]]; then
	echo "Need an OETMP defined!"
	exit 1
fi

export SYSROOTSDIR=${OETMP}/sysroots
export CROSSTOOLDIR=${SYSROOTSDIR}/`uname -m`-linux/usr/bin
export KERNELDIR=${SYSROOTSDIR}/overo/kernel

PATH=${PATH}:${CROSSTOOLDIR}:${CROSSTOOLDIR}/armv7a-vfp-neon-poky-linux-gnueabi

export QMAKEQTE=/opt/qte/bin/qmake -spec qws/linux-overo-storm-g++

