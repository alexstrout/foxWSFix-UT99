@Echo off
del ..\System\foxWSFix99.*
echo Starting Compile Job...
..\System\UCC make
echo.
pause
