if [[ -z "${OETMP}" ]]; then
	echo "Need an OETMP defined!"
	exit 1
fi

export SYSROOTSDIR=${OETMP}/sysroots
export STAGEDIR=${SYSROOTSDIR}/`uname -m`-linux/usr/bin

export KERNELDIR=${SYSROOTSDIR}/overo/kernel

PATH=${PATH}:${STAGEDIR}:${STAGEDIR}/armv7a-vfp-neon-poky-linux-gnueabi

