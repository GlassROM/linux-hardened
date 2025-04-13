# Maintainer: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: Daniel Micay <danielmicay@gmail.com>
# Contributor: Tobias Powalowski <tpowa@archlinux.org>
# Contributor: Thomas Baechler <thomas@archlinux.org>

pkgbase=linux-hardened
pkgname=linux-hardened
pkgver=6.13.7.hardened1
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
  rust
  rust-bindgen
  rust-src
  tar
  xz
  llvm
  clang
  lld
  polly
  rust
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
sha256sums=('3a39b62038b7ac2f43d26a1f84b4283e197804e1e817ad637e9a3d874c47801d'
            'SKIP'
            '0377d6a482c543e10a20e6120701f9c75f41afa24aad4fc26f8ee18ed3371068'
            'SKIP'
            'SKIP'
	    'SKIP')
b2sums=('dc9e71842d7e9d2e016ca2c6e791d627790c87cd445b404c73745dc565eb89617ec69f1150b228d7853a595ea7f6daf6acdb74f8383088af30d42bb4c062a129'
        'SKIP'
        '58fb1171cc796c72237ff12c267eb4c6a935aa2551364708115ffe8c2896da2aabdfbbcea0862eecc83dfb793540b2153f9d80463dd4ba0bb874c9676ee5d3a4'
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
  scripts/config --disable MODULES && scripts/config --enable TRIM_UNUSED_KSYMS
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
    'linux-firmware: firmware images needed for some devices'
    'scx-scheds: to use sched-ext schedulers'
    'wireless-regdb: to set the correct wireless channels of your country'
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
