# Maintainer: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: Daniel Micay <danielmicay@gmail.com>
# Contributor: Tobias Powalowski <tpowa@archlinux.org>
# Contributor: Thomas Baechler <thomas@archlinux.org>

pkgbase=linux-hardened
pkgname=linux-hardened
pkgver=6.10.12.hardened1
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
sha256sums=('524858852f5869a9ef17de8b1e6e7faf05bcb2c462bc96b3c24dbf82ede373cf'
            'SKIP'
            '72e429209ba08788043dd580043850e09c35d9bbfa60eb857c3b496c892be31f'
            'SKIP'
            'SKIP'
	    'SKIP')
b2sums=('22cb2e7c59e65da55f1db0678f3e913376d343f8285666bbc2c4e6a2b1b45c492c8d01a10f9a0ab6f944745a676ed7da9270683d29ca4984f68c86f965dfe121'
        'SKIP'
        '0b3cd388f968c271424465fcc7662b4671149f16a373fb9d9d253c3933d0a0c98326b1714ab47463c275942b79b92bb43312dbcd7adc5a4171be350f40f4f0b7'
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
