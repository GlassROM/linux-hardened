# Maintainer: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: Daniel Micay <danielmicay@gmail.com>
# Contributor: Tobias Powalowski <tpowa@archlinux.org>
# Contributor: Thomas Baechler <thomas@archlinux.org>

pkgbase=linux-hardened
pkgname=linux-hardened
pkgver=6.10.4.hardened1
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
  polly

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
  ibt.patch
)
validpgpkeys=(
  ABAF11C65A2970B130ABE3C479BE3E4300411886  # Linus Torvalds
  647F28654894E3BD457199BE38DBBDC86092693E  # Greg Kroah-Hartman
  E240B57E2C4630BA768E2F26FC1B547C8D8172C8  # Levente Polyak
)
# https://www.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc
sha256sums=('e2c69dfd5fa00c741ebac4560bed9f7be6abb727d05a719e4df9e99df11555f8'
            'SKIP'
            '071ca42e4d7301038facd322b06f3d0ee20b4c01561eb91a50899b606536d9c7'
            'SKIP'
            'SKIP'
	    'SKIP')
b2sums=('ea7e9a7d74621a6e76b2828ee80cf5df1fcf139469bb8877d93f30d7766f9145961324de5b2cadba29126d7df82a7eeba80303c82c7c1140be3fb46cf213e503'
        'SKIP'
        '1ba4dd4b613dc865f170a30cf54cbb7846120a920af317db434e985b5c5bcd3ef90831292b48b9ba65b145eca3edfd289d65703e9326ac472576010e2a526290'
        'SKIP'
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
  LLVM=1 LLVM_IAS=1 make olddefconfig
  diff -u ../config .config || :

  sed -i 's/-O2/-O3 -march=native -mtune=native -funroll-loops -Xclang -load -Xclang LLVMPolly.so -mllvm -polly -mllvm -polly-run-dce -mllvm -polly-run-inliner -mllvm -polly-ast-use-context -mllvm -polly-vectorizer=stripmine -mllvm -polly-invariant-load-hoisting/g' Makefile
  scripts/config --disable MODULES
  LLVM=1 LLVM_IAS=1 LSMOD=/home/builder/linux-hardened/lsmod make localyesconfig

  make -s kernelrelease > version
  echo "Prepared $pkgbase version $(<version)"
}

build() {
  cd $_srcname

  LLVM=1 LLVM_IAS=1 make all -j$(nproc --all)
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
