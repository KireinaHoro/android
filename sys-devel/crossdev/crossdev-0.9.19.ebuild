# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/crossdev/crossdev-0.9.19.ebuild,v 1.1 2008/11/28 09:21:10 vapier Exp $

DESCRIPTION="Gentoo Cross-toolchain generator"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND=">=sys-apps/portage-2.1
	app-shells/bash
	|| ( dev-util/unifdef sys-freebsd/freebsd-ubin >=sys-apps/darwin-miscutils-4 )"

src_install() {
	dosbin "${FILESDIR}"/crossdev || die
	dosed "s:GENTOO_PV:${PV}:" /usr/sbin/crossdev
}
