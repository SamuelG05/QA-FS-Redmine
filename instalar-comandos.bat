@echo off
chcp 65001 >nul
echo.
echo  Instalando slash commands do QA-FS-Redmine...
echo.

set "DEST=%USERPROFILE%\.claude\commands"

if not exist "%DEST%" (
    mkdir "%DEST%"
    echo  Pasta criada: %DEST%
)

copy /Y "commands\inicia-teste.md"        "%DEST%\" >nul
copy /Y "commands\plano-teste.md"         "%DEST%\" >nul
copy /Y "commands\registrar-situacao.md"  "%DEST%\" >nul
copy /Y "commands\finalizar-caso.md"      "%DEST%\" >nul
copy /Y "commands\refinar-caso.md"        "%DEST%\" >nul
copy /Y "commands\criterios-aceitacao.md" "%DEST%\" >nul

echo  Comandos instalados em: %DEST%
echo.
echo  /inicia-teste
echo  /plano-teste
echo  /registrar-situacao
echo  /finalizar-caso
echo  /refinar-caso
echo  /criterios-aceitacao
echo.
echo  Pronto! Reinicie o Claude Code para usar os comandos.
echo.
pause
