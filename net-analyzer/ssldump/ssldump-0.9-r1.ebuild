# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-analyzer/ssldump/ssldump-0.9-r1.ebuild,v 1.7 2011/12/09 16:15:55 jer Exp $

EAPI=4
inherit autotools eutils

MY_P=${PN}-0.9b3

DESCRIPTION="A Tool for network monitoring and data acquisition"
HOMEPAGE="http://www.rtfm.com/ssldump/"
SRC_URI="http://www.rtfm.com/ssldump/${MY_P}.tar.gz"

LICENSE="openssl"
SLOT="0"
KEYWORDS="amd64 ~arm ppc sparc x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="ssl"

RDEPEND="net-libs/libpcap
	ssl? ( >=dev-libs/openssl-1 )"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-libpcap-header.patch \
		"${FILESDIR}"/${P}-configure-dylib.patch \
		"${FILESDIR}"/${P}-openssl-0.9.8.compile-fix.patch \
		"${FILESDIR}"/${P}-DLT_LINUX_SLL.patch \
		"${FILESDIR}"/${P}-makefile-fix.patch

	sed -i configure.in -e 's|libpcap.a|libpcap.so|g' || die

	eautoreconf
}

src_configure() {
	local myconf
	myconf="${myconf} \
		--with-pcap-inc=${EPREFIX}/usr/include \
		--with-pcap-lib=${EPREFIX}/usr/$(get_libdir)"

	if use ssl; then
		myconf="${myconf} \
			--with-openssl-inc=${EPREFIX}/usr/include \
			--with-openssl-lib=${EPREFIX}/usr/$(get_libdir)"
	else
		myconf="${myconf} --without-openssl"
	fi

	econf ${myconf}
}

src_install() {
	dosbin ssldump || die
	doman ssldump.1 || die
	dodoc ChangeLog CREDITS README
}
