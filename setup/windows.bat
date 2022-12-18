@echo off

:: SETUP NETWORK
for /f "skip=2 tokens=3*" %%a in ('netsh int show int') do (

  netsh int ip set address "%%b" static @address @netmask @gateway 1
)

:: COMPUTER NAME
wmic computersystem where name="%computername%" call rename name="%random%"

:: WRITE FILE
echo list volume > C:\disk.txt

:: FIND IDENTITY
for /f "skip=8 tokens=2,3" %%a in ('diskpart /s C:\disk.txt') do (

  :: IT MUST BE DRIVE C:\
  if %%b==C (

    :: WRITE FILE
    echo select volume %%a > C:\disk.txt & echo extend >> C:\disk.txt

    :: EXTEND DISK
    diskpart /s C:\disk.txt
  )
)

:: CHANGE PASSWORD
net user "@username" "@password"

:: LICENSE
slmgr.vbs //b -dlv
slmgr.vbs //b -rearm

:: DELETE FILE
del C:\disk.txt

:: DELETE FILE
del C:\setup.bat
