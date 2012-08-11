# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/eselect-boost/eselect-boost-0.4.ebuild,v 1.6 2012/05/16 15:38:05 jer Exp $

EAPI="4"

inherit multilib

DESCRIPTION="boost module for eselect"
HOMEPAGE="http://www.gentoo.org/proj/en/eselect/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ~ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~ia64-hpux ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x86-solaris"
IUSE=""

DEPEND=""
RDEPEND=">=app-admin/eselect-1.0.5"
S="${WORKDIR}"

src_install() {
	local mdir="/usr/share/eselect/modules"
	dodir ${mdir}
	sed -e "s|%LIBDIR%|$(get_libdir)|g" "${FILESDIR}/boost.eselect-${PVR}" > "${ED}${mdir}/boost.eselect" || die "failed to install"

	keepdir /etc/eselect/boost
	keepdir /usr/share/boost-eselect/profiles
}
