@echo off
setlocal EnableDelayedExpansion

set otp_version=26.1.2
for /f "delims=." %%a in ("%otp_version%") do set otp_release=%%a
set otp_dir=otp-%otp_version%
set elixir_version=1.15.7
set elixir_dir=elixir-%elixir_version%-otp-%otp_release%

call :main
goto :eof

:main
call :install_otp
echo checking OTP...
set PATH=%otp_dir%\bin;%PATH%
erl.exe -noshell -eval "io:put_chars(erlang:system_info(system_version)), halt()."
call :install_elixir
echo checking Elixir...
!elixir_dir!\bin\elixir --version
echo.
echo Add this to your shell:
echo.
echo    set PATH=!otp_dir!\bin;!elixir_dir!\bin;%%PATH%%
goto :eof

:install_otp
set otp_exe=otp_win64_%otp_version%.exe

if not exist "%otp_dir%" (
    set otp_url=https://github.com/erlang/otp/releases/download/OTP-%otp_version%/%otp_exe%
    echo downloading !otp_url!...
    curl --fail -LO !otp_url!
    echo running %otp_exe%...
    .\%otp_exe% /S /D=%CD%\%otp_dir%
)
goto :eof

:install_elixir
set elixir_zip=elixir-otp-%otp_release%.zip

if not exist "%elixir_dir%" (
    set elixir_url=https://github.com/elixir-lang/elixir/releases/download/v%elixir_version%/%elixir_zip%
    echo downloading !elixir_url!...
    curl --fail -LO !elixir_url!
    powershell -Command "Expand-Archive -LiteralPath !elixir_zip! -DestinationPath !elixir_dir!"
)
goto :eof
