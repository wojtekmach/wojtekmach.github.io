#!/bin/bash
set -euo pipefail

otp_version="26.1.2"
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
  os=`uname -s`
  case $os in
    Darwin) os=darwin ;;
    Linux) os=linux ;;
    *) echo "error: unsupported OS: $os." && exit 1
  esac

  arch=`uname -m`
  case $arch in
    "arm64") arch=aarch64 ;;
    *) true
  esac

  otp_basename="otp_${otp_version}_${os}_${arch}_ssl_1.1.1s"

  if [ ! -d $otp_dir ]; then
    url="https://github.com/wojtekmach/beam_builds/releases/download/OTP-$otp_version/$otp_basename.tar.gz"
    echo "downloading $url"
    curl --fail -LO $url
    tar xvzf $otp_basename.tar.gz
    mv $otp_basename $otp_dir
    (cd $otp_dir && ./Install -sasl $PWD)
  fi
}

install_elixir() {
  elixir_basename="elixir-otp-$otp_release.zip"

  if [ ! -d $elixir_dir ]; then
    url="https://github.com/elixir-lang/elixir/releases/download/v$elixir_version/elixir-otp-$otp_release.zip"
    echo "downloading $url"
    curl --fail -LO $url
    mkdir $elixir_dir
    unzip $elixir_basename -d $elixir_dir
  fi
}

main
