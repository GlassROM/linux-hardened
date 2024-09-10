# Maintainer: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: Daniel Micay <danielmicay@gmail.com>
# Contributor: Tobias Powalowski <tpowa@archlinux.org>
# Contributor: Thomas Baechler <thomas@archlinux.org>

pkgbase=linux-hardened
pkgname=linux-hardened
pkgver=6.10.8.hardened1
pkgrel=2
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
sha256sums=('c0923235779d4606bba87f72b6fe11f796e9e40c1ca9f4d5dbe04cd47ee3c595'
            'SKIP'
            '1cdc8bffd7eb2e17e4f82e98d888fe8b3e2e12c8c364ba0965b9663cfd3748d4'
            'SKIP'
            'SKIP'
	    'SKIP')
b2sums=('01a004ce8886b00be4ca927ca6b1ce10b5d31535687022accf0b9d1f4aa9b47a1622a82611bd9544abb2c90ad914ad227392d0525d7c93eefbb38fa25ba6c809'
        'SKIP'
        '9654b815f99696bc367e278ea06dee1ff96c0bcc0ea58abe1422d3222c60e9ad5cba6dc8cb6363287155c12ac566268af1552450f234ab799fcb6866d0877db0'
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
