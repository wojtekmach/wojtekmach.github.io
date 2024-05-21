#!/bin/bash
set -euo pipefail

otp_version="27.0"
elixir_version="1.16.3"


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

root_dir="$HOME/.elixir-install"
tmp_dir="$root_dir/tmp"
mkdir -p $tmp_dir

otp_release="${otp_version%%.*}"
otp_dir="$root_dir/otp/$otp_version"

if [[ "$otp_version" =~ ^27\..*$ ]]; then
  elixir_dir="$root_dir/elixir/$elixir_version-otp-26"
  elixir_zip="elixir-otp-26.zip"
else
  elixir_dir="$root_dir/elixir/$elixir_version-otp-$otp_release"
  elixir_zip="elixir-otp-$otp_release.zip"
fi

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
  echo $otp_dir
  if [ ! -d $otp_dir ]; then
    if [ "$os" = "windows" ]; then
      otp_exe="otp_win64_$otp_version.exe"

      if [ ! -f $otp_exe ]; then
        url="https://github.com/erlang/otp/releases/download/OTP-$otp_version/$otp_exe"
        echo "downloading $url"
        curl --fail -LO $url
      fi

      mkdir $otp_dir
      echo running $otp_exe
      cmd //c "$otp_exe //D=`pwd -W`/$otp_dir"
      rm $otp_exe
    fi

    if [ "$os" = "darwin" ]; then
      otp_tgz="otp-${otp_version}-macos-universal.tar.gz"

      if [ ! -f $tmp_dir/$otp_tgz ]; then
        url="https://github.com/elixir-install/otp_builds/releases/download/OTP-$otp_version/$otp_tgz"
        echo "downloading $url"
        curl --fail -L -o "$tmp_dir/$otp_tgz" $url
      fi

      echo "unpacking $otp_tgz to $otp_dir..."
      mkdir $otp_dir
      tar xzf "$tmp_dir/$otp_tgz" --strip-components 1 -C $otp_dir
      (cd $otp_dir && ./Install -sasl $PWD)
      rm "$tmp_dir/$otp_tgz"
    fi
  fi
}

install_elixir() {
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
