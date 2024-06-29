# Maintainer: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: Daniel Micay <danielmicay@gmail.com>
# Contributor: Tobias Powalowski <tpowa@archlinux.org>
# Contributor: Thomas Baechler <thomas@archlinux.org>

pkgbase=linux-hardened
pkgname=linux-hardened
pkgver=6.9.7.hardened1
pkgrel=1
pkgdesc='Security-Hardened Linux'
url='https://github.com/anthraxx/linux-hardened'
arch=(x86_64)
license=(GPL-2.0-only)
makedepends=(
  bc
  cpio
  gettext
  libelf
  pahole
  perl
  python
  tar
  xz
  llvm
  clang
  lld

  # htmldocs
  graphviz
  imagemagick
  python-sphinx
  python-yaml
  texlive-latexextra
)
options=(
  !debug
  !strip
)
_srcname=linux-${pkgver%.*}
_srctag=v${pkgver%.*}-${pkgver##*.}
source=(
  https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/${_srcname}.tar.{xz,sign}
  ${url}/releases/download/${_srctag}/${pkgbase}-${_srctag}.patch{,.sig}
  config  # the main kernel config file
)
validpgpkeys=(
  ABAF11C65A2970B130ABE3C479BE3E4300411886  # Linus Torvalds
  647F28654894E3BD457199BE38DBBDC86092693E  # Greg Kroah-Hartman
  E240B57E2C4630BA768E2F26FC1B547C8D8172C8  # Levente Polyak
)
# https://www.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc
sha256sums=('e4f588cd91eef9d461e5e14fdf9415feff8a72fbcc274089a0f768a58de001f8'
            'SKIP'
            'a2204110fd775a7657133bbd783b149be8e08bbd4ede6bd013dad6dcef85a8bd'
            'SKIP'
	    'SKIP')
b2sums=('67b49d64f8ceba02dc1eade59991c683c81a533eec7105466d235898de2cee692aa5730d538a33bb04f1b0260e9dcbf63b332ddfab42a7d44425c9a9d8410d77'
        'SKIP'
        'e734da48fc0e8723b40f8fa768ebea5562aeaad58d90041fa0f31c3767889945eae91c58ed46dacd8bd30c7c66211604455e9caf369a0260246dc0b411aedc88'
        'SKIP'
	'SKIP')

export KBUILD_BUILD_HOST=archlinux
export KBUILD_BUILD_USER=$pkgbase
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

prepare() {
  cd $_srcname

  echo "Setting version..."
  echo "-$pkgrel" > localversion.10-pkgrel
  echo "${pkgbase#linux}" > localversion.20-pkgname

  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    src="${src%.zst}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch $src..."
    patch -Np1 < "../$src"
  done

  echo "Setting config..."
  cp ../config .config
  LLVM=1 make olddefconfig
  diff -u ../config .config || :

  sed -i 's/-O2/-O3 -march=native -mtune=native/g' Makefile
  scripts/config --disable MODULES
  LLVM=1 LSMOD=/home/builder/linux-hardened/lsmod make localyesconfig

  make -s kernelrelease > version
  echo "Prepared $pkgbase version $(<version)"
}

build() {
  cd $_srcname

  LLVM=1 make all -j$(nproc --all)
  # make -C tools/bpf/bpftool vmlinux.h feature-clang-bpf-co-re=1
}

package() {
  pkgdesc="The $pkgdesc kernel and modules"
  depends=(
    coreutils
    initramfs
    kmod
  )
  optdepends=(
    'wireless-regdb: to set the correct wireless channels of your country'
    'linux-firmware: firmware images needed for some devices'
    'usbctl: deny_new_usb control'
  )
  provides=(
    KSMBD-MODULE
    VIRTUALBOX-GUEST-MODULES
    WIREGUARD-MODULE
  )
  replaces=(
  )

  cd $_srcname
  local modulesdir="$pkgdir/usr/lib/modules/$(<version)"

  echo "Installing boot image..."
  # systemd expects to find the kernel here to allow hibernation
  # https://github.com/systemd/systemd/commit/edda44605f06a41fb86b7ab8128dcf99161d2344
  install -Dm644 "$(make -s image_name)" "$modulesdir/vmlinuz"

  # Used by mkinitcpio to name the kernel
  echo "$pkgbase" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

  echo "Installing modules..."
  ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 \
    DEPMOD=/doesnt/exist modules_install  # Suppress depmod

  # remove build link
  rm -f "$modulesdir"/build
}

# vim:set ts=8 sts=2 sw=2 et:
