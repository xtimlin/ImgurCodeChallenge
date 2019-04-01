@echo off
CLS

echo start time %time%
@echo on

cd bin
main.exe
@echo done

echo end time %time%
@echo off
echo press any key to exit

pause >nul
exit