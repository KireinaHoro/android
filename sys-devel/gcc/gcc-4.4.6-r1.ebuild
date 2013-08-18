# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.4.6-r1.ebuild,v 1.10 2012/11/24 21:22:30 vapier Exp $

PATCH_VER="1.0"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="0.4.5"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
PIE_GLIBC_STABLE="x86 amd64 ppc ppc64 arm ia64"
PIE_UCLIBC_STABLE="x86 arm amd64 ppc ppc64"
SSP_STABLE="amd64 x86 ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
SSP_UCLIBC_STABLE=""
#end Hardened stuff

inherit toolchain flag-o-matic prefix

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-3 LGPL-3 || ( GPL-3 libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.2"
KEYWORDS="~ppc-aix ~x64-freebsd ~x86-freebsd ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

RDEPEND=""
DEPEND="${RDEPEND}
	kernel_Darwin? ( ${CATEGORY}/binutils-apple )
	kernel_AIX? ( ${CATEGORY}/native-cctools )
	kernel_linux? (
		ppc? ( >=${CATEGORY}/binutils-2.17 )
		ppc64? ( >=${CATEGORY}/binutils-2.17 )
		>=${CATEGORY}/binutils-2.15.94
	)"
if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} !prefix? ( elibc_glibc? ( >=sys-libs/glibc-2.8 ) )"
fi

pkg_setup() {
	toolchain_pkg_setup

	if use graphite ; then
		ewarn "Graphite support is still experimental and unstable."
		ewarn "Any bugs resulting from the use of Graphite will not be fixed."
	fi
}

src_unpack() {
	toolchain_src_unpack
	use vanilla && return 0

	# work around http://gcc.gnu.org/bugzilla/show_bug.cgi?id=33637
	epatch "${FILESDIR}"/4.3.0/targettools-checks.patch

	# http://bugs.gentoo.org/show_bug.cgi?id=201490
	epatch "${FILESDIR}"/4.2.2/gentoo-fixincludes.patch

	# http://gcc.gnu.org/bugzilla/show_bug.cgi?id=27516
	epatch "${FILESDIR}"/4.3.0/treelang-nomakeinfo.patch

	# call the linker without explicit target like on sparc
	epatch "${FILESDIR}"/solaris-i386-ld-emulation.patch

	# add support for 64-bits native target on Solaris
	epatch "${FILESDIR}"/4.4.0/gcc-4.4.1-solaris-x86_64.patch

	# make sure 64-bits native targets don't screw up the linker paths
	epatch "${FILESDIR}"/solaris-searchpath.patch
	epatch "${FILESDIR}"/no-libs-for-startfile.patch
	# replace nasty multilib dirs like ../lib64 that occur on --disable-multilib
	if use prefix; then
		epatch "${FILESDIR}"/4.3.3/prefix-search-dirs.patch
		eprefixify "${S}"/gcc/gcc.c
	fi

	# make it have correct install_names on Darwin
	epatch "${FILESDIR}"/4.3.3/darwin-libgcc_s-installname.patch

	# --- The following patches still cause failure for other
	# platforms. Since gcc-4.4 is still masked on interix, and
	# i have no time ATM to fix things, i for now just commented
	# them out.

	# interix patches - all from 4.2.4 updated and combined
	#epatch "${FILESDIR}"/${P}-interix.patch
	# and this one to avoid the need of a re-bootstrap.
	#epatch "${FILESDIR}"/${P}-interix-avoid-bs.patch

	if [[ ${CHOST} == *-mint* ]] ; then
		epatch "${FILESDIR}"/4.4.1/${PN}-4.4.1-mint1.patch
		epatch "${FILESDIR}"/4.4.1/${PN}-4.4.1-mint2.patch
		epatch "${FILESDIR}"/4.4.1/${PN}-4.4.1-mint3.patch
		epatch "${FILESDIR}"/4.3.2/${PN}-4.3.2-mint3.patch
	fi

	# Always behave as if -pthread were passed on AIX (#266548)
	epatch "${FILESDIR}"/4.3.3/aix-force-pthread.patch

	epatch "${FILESDIR}"/gcj-4.3.1-iconvlink.patch

	#epatch "${FILESDIR}"/${PN}-4.2-pa-hpux-libgcc_s-soname.patch
	epatch "${FILESDIR}"/${PN}-4.2-ia64-hpux-always-pthread.patch
	epatch "${FILESDIR}"/4.4.4/aix-bnoerok.patch
	epatch "${FILESDIR}"/4.2.2/aix-lineno.patch

	# try /usr/lib31 in 32bit profile on x86_64-linux (needs --enable-multilib),
	# but this does make sense in prefix only.
	use prefix && epatch "${FILESDIR}"/${PN}-4.4.1-linux-x86-on-amd64.patch

	sed -i 's/use_fixproto=yes/:/' gcc/config.gcc #PR33200

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch

	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${FILESDIR}"/4.4.0/gcc-4.4.0-softfloat.patch

	epatch "${FILESDIR}"/4.2.2/aix-minimal-toc.patch
	epatch "${FILESDIR}"/4.2.2/aix61-longdouble64.patch
}

src_compile() {
	case ${CTARGET}:" ${USE} " in
		*-mint*)
			EXTRA_ECONF="${EXTRA_ECONF} --enable-multilib"
		;;
		*-solaris*)
			# todo: some magic for native vs. GNU linking?
			EXTRA_ECONF="${EXTRA_ECONF} --with-gnu-ld --with-gnu-as"
		;;
		*-aix*)
			# AIX doesn't use GNU binutils, because it doesn't produce usable
			# code
			EXTRA_ECONF="${EXTRA_ECONF} --without-gnu-ld --without-gnu-as"
			append-ldflags -Wl,-bbigtoc,-bmaxdata:0x10000000 # bug#194635
		;;
		*-interix*)
			# disable usage of poll() on interix, since poll() only
			# works on the /proc filesystem (.......)
			export glibcxx_cv_POLL=no

			# if using the old system as, gcc's configure script fails
			# to detect that as cannot handle .lcomm with alignment.
			# on interix, it is rather easy to detect the as, since there
			# is only _one_ build of it with a fixed date in the version
			# header...
			if as --version | grep 20021111 > /dev/null 2>&1; then
				einfo "preventing gcc from detecting .lcomm alignment option in interix system as."
				export gcc_cv_as_lcomm_with_alignment=no
			fi
		;;
		i[34567]86-*-linux*:*" prefix "*)
			# to allow the linux-x86-on-amd64.patch become useful, we need
			# to enable multilib, even if there is just one multilib option.
			EXTRA_ECONF="${EXTRA_ECONF} --enable-multilib"
			if [[ ${CBUILD:-${CHOST}} == "${CHOST}" ]]; then
				# we might be on x86_64-linux, but don't do cross-compile, so
				# tell the host-compiler to really create 32bits (for stage1)
				# (real x86-linux-gcc also accept -m32).
				tc-export CC CXX
				CC="${CC} -m32"
				CXX="${CC} -m32"
			fi
		;;
	esac

	# Since GCC 4.1.2 some non-posix (?) /bin/sh compatible code is used, at
	# least on Solaris, and AIX /bin/sh is ways too slow,
	# so force it to use $BASH (that portage uses) - it can't be EPREFIX
	# in case that doesn't exist yet
	export CONFIG_SHELL="${BASH}"
	gcc_src_compile
}

src_install() {
	toolchain_src_install

	if [[ ${CTARGET} == *-interix* ]] && ! is_crosscompile; then
		# interix delivers libdl and dlfcn.h with gcc-3.3.
		# Since those parts are perfectly usable by this gcc (and
		# required for example by perl), we simply can reuse them.
		# As libdl is in /usr/lib, we only need to copy dlfcn.h.
		# When cross compiling for interix once, ensure that sysroot
		# contains dlfcn.h.
		cp /opt/gcc.3.3/include/dlfcn.h "${ED}${INCLUDEPATH}" \
		|| die "Cannot gain /opt/gcc.3.3/include/dlfcn.h"
	fi

	if [[ ${CTARGET} == *-interix3* ]]; then
		# interix 3.5 has no stdint.h and no inttypes.h. This breaks
		# so many packages, that i just install interix 5.2's stdint.h
		# which should be ok.
		cp "${FILESDIR}"/interix-3.5-stdint.h "${ED}${INCLUDEPATH}/stdint.h" \
		|| die "Cannot install stdint.h for interix3"
	fi

	# create a small profile.d script, unsetting some of the bad
	# environment variables that the sustem could set from the outside.
	# (GCC_SPECS, GCC_EXEC_PREFIX, CPATH, LIBRARY_PATH, LD_LIBRARY_PATH,
	#  C_INCLUDE_PATH, CPLUS_INCLUDE_PATH, LIBPATH, SHLIB_PATH, LIB, INCLUDE,
	#  LD_LIBRARY_PATH_32, LD_LIBRARY_PATH_64).
	# Maybe there is a better location for doing this ...? Feel free to move
	# it there if you want to.

	cat > "${T}"/00-gcc-paths.sh <<- _EOF
		#!/bin/env bash
		# GCC specific variables
		unset GCC_SPECS GCC_EXEC_PREFIX
		# include path variables
		unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH INCLUDE
		# library path variables
		unset LIBRARY_PATH LD_LIBRARY_PATH LIBPATH SHLIB_PATH LIB LD_LIBRARY_PATH_32 LD_LIBRARY_PATH_64
	_EOF

	insinto /etc/profile.d
	doins "${T}"/00-gcc-paths.sh

}

