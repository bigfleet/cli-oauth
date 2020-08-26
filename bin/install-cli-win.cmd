REM In CMD.exe install-cli-win.cmd
@echo off
setlocal
call :setESC
cls
set BLUE=%ESC%[44m %ESC%[0m
set RED=%ESC%[41m %ESC%[0m

echo.
echo %BLUE%%BLUE%%BLUE%                    %BLUE%%BLUE%%BLUE%                 %BLUE%%BLUE%%BLUE%                         %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%
echo %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%                %BLUE%%BLUE%%BLUE%                 %BLUE%%BLUE%%BLUE%                %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%    %BLUE%%BLUE%%BLUE%  
echo   %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%             %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%    %BLUE%%BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%              %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%
echo       %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%         %BLUE%%BLUE%%BLUE%    %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%    %BLUE%%BLUE%%BLUE%             %BLUE%%BLUE%%BLUE%%BLUE%        %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%
echo   %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%             %BLUE%%BLUE%%BLUE%     %BLUE%%BLUE%%BLUE% %BLUE%%BLUE%%BLUE%     %BLUE%%BLUE%%BLUE%             %BLUE%%BLUE%%BLUE%%BLUE%        %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%
echo %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%    %RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%  %BLUE%%BLUE%%BLUE%      %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%      %BLUE%%BLUE%%BLUE%  %RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%    %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%
echo %BLUE%%BLUE%%BLUE%     %RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%  %BLUE%%BLUE%%BLUE%       %BLUE%%BLUE%%BLUE%       %BLUE%%BLUE%%BLUE%  %RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%%RED%    %BLUE%%BLUE%%BLUE%%BLUE%%BLUE%    %BLUE%%BLUE%%BLUE%   %BLUE%%BLUE%%BLUE%

REM Turn on emojis
chcp.com 65001

REM Set by web/app.rb
SET # CLI_GIT_NAME=
SET # CLI_GIT_EMAIL=
SET # CLI_GITHUB_USER=
SET # CLI_GITHUB_TOKEN=
SET # CLI_LOG_TOKEN=
SET CLI_ISSUES_URL=https://github.com/GetLevvel/lvl_cli/issues/new

rmdir /S /Q %USERPROFILE%\appdata\local\levvel\.lvl_cli
mkdir %USERPROFILE%\appdata\local\levvel\.lvl_cli\repo
pushd %USERPROFILE%\appdata\local\levvel\.lvl_cli\repo
call git clone https://%CLI_GITHUB_USER%:%CLI_GITHUB_TOKEN%@github.com/GetLevvel/lvl_cli.git
chdir %USERPROFILE%\appdata\local\levvel\.lvl_cli\repo\lvl_cli
call git checkout -b release -t origin/release
call yarn
call npm link --force
chdir %USERPROFILE%\appdata\local\levvel\.lvl_cli\repo\lvl_cli\packages\lvl_cli
call npm link --force

lvl.cmd login %CLI_GITHUB_TOKEN%
lvl.cmd log:set-token %CLI_LOG_TOKEN%

popd

echo %ESC%[91mlvl_cli has been installed successfully! Run lvl -h to get started.%ESC%[0m

:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /B 0
)
exit /B 0
