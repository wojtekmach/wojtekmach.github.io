#!/bin/bash
set -euo pipefail

os=`uname -s`
case $os in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  MINGW64*) os=windows ;;
  *) echo "error: unsupported OS: $os." && exit 1
esac

arch=`uname -m`
case $arch in
  "arm64") arch=aarch64 ;;
  *) true
esac

if [ "$os" = "darwin" ] && [ "$arch" = "x86_64" ]; then
  otp_version="25.3.2.3"
else
  otp_version="26.1.2"
fi
otp_release="${otp_version%%.*}"
otp_dir="otp-$otp_version"

elixir_version="1.15.7"
elixir_dir="elixir-$elixir_version-otp-$otp_release"

main() {
  install_otp
  echo "checking OTP..."
  PATH="$otp_dir/bin:$PATH"
  erl -noshell -eval "io:put_chars(erlang:system_info(system_version)), halt()."
  install_elixir
  echo "checking Elixir..."
  $elixir_dir/bin/elixir --version
  echo
  echo "Add this to your shell:"
  echo
  echo "    export PATH=$otp_dir/bin:$elixir_dir/bin:\$PATH"
  echo
}

install_otp() {
  if [ ! -d $otp_dir ]; then
    if [ "$os" = "windows" ]; then
      otp_exe="otp_win64_$otp_version.exe"

      if [ ! -f $otp_exe ]; then
        url="https://github.com/erlang/otp/releases/download/OTP-$otp_version/$otp_exe"
        echo "downloading $url"
        curl --fail -LO $url
      fi

      mkdir $otp_dir
      echo running $otp_exj
      sh -c "$otp_exe //D=`pwd -W`/$otp_dir"
      rm $otp_exe
    else
      otp_tgz="otp_${otp_version}_${os}_${arch}_ssl_1.1.1s.tar.gz"

      if [ ! -f $otp_tgz ]; then
        url="https://github.com/wojtekmach/beam_builds/releases/download/OTP-$otp_version/$otp_tgz"
        echo "downloading $url"
        curl --fail -LO $url
      fi

      echo "unpacking $otp_tgz to $otp_dir..."
      mkdir $otp_dir
      tar xzf $otp_tgz --strip-components 2 -C $otp_dir
      (cd $otp_dir && ./Install -sasl $PWD)
      rm $otp_tgz
    fi
  fi
}

install_elixir() {
  elixir_zip="elixir-otp-$otp_release.zip"

  if [ ! -d $elixir_dir ]; then
    if [ ! -f $elixir_zip ]; then
      url="https://github.com/elixir-lang/elixir/releases/download/v$elixir_version/$elixir_zip"
      echo "downloading $url"
      curl --fail -LO $url
    fi
    echo "unpacking $elixir_zip to $elixir_dir..."
    mkdir $elixir_dir
    unzip -q $elixir_zip -d $elixir_dir
    rm $elixir_zip
  fi
}

main
