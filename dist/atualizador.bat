@echo off
setlocal enabledelayedexpansion
title Atualizador da Extensao HubSoft
cd /d "%~dp0"

echo ============================================
echo   ATUALIZADOR DA EXTENSAO HUBSOFT
echo ============================================
echo.
echo [1/3] Verificando atualizacoes no GitHub...

set SELF_UPDATE=0
if exist atualizador_novo.bat del atualizador_novo.bat

:: Base publica dos arquivos (repo publico, sem token)
:: Os arquivos ficam dentro da pasta dist/ do repositorio
set REPO_URL=https://raw.githubusercontent.com/PauloG357Fribeiro/API-HUBSOFT-JAMES/main/dist

:: -f  = falha de verdade em erro HTTP (nao grava pagina de erro dentro do arquivo)
:: -sS = silencioso, mas mostra a mensagem se der erro
:: Headers de no-cache forcam o GitHub CDN a entregar o arquivo mais recente,
:: evitando que versao antiga em cache mascare uma atualizacao publicada.
set CURL=curl -fsS -H "Cache-Control: no-cache" -H "Pragma: no-cache"

:: ---------- versao instalada ----------
if not exist manifest.json (
    echo ERRO: manifest.json nao encontrado.
    echo Rode este arquivo de dentro da pasta da extensao.
    goto fim
)

for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"version\"" manifest.json') do set LOCAL_VER=%%a
set LOCAL_VER=%LOCAL_VER:"=%
set LOCAL_VER=%LOCAL_VER: =%
:: Remove carriage return (\r) que pode vir de arquivos gerados no Linux/Mac
:: e que torna a comparacao de string falsa mesmo com versoes iguais.
for /f "delims=" %%a in ("%LOCAL_VER%") do set LOCAL_VER=%%a

:: ---------- versao publicada ----------
if exist temp_manifest.json del temp_manifest.json

%CURL% -o temp_manifest.json "%REPO_URL%/manifest.json"
if errorlevel 1 (
    echo.
    echo ERRO: nao foi possivel baixar o manifest do GitHub.
    echo Verifique sua internet e tente de novo.
    if exist temp_manifest.json del temp_manifest.json
    goto fim
)

for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"version\"" temp_manifest.json') do set REMOTE_VER=%%a
set REMOTE_VER=%REMOTE_VER:"=%
set REMOTE_VER=%REMOTE_VER: =%
:: Remove \r do valor remoto (arquivos do GitHub podem ter terminacao Unix)
for /f "delims=" %%a in ("%REMOTE_VER%") do set REMOTE_VER=%%a

:: Sem versao remota valida, NAO mexe em nada
if "%REMOTE_VER%"=="" (
    echo.
    echo ERRO: o arquivo baixado nao parece um manifest valido.
    echo Nada foi alterado. Avise o Paulo.
    del temp_manifest.json
    goto fim
)

echo     Versao instalada: %LOCAL_VER%
echo     Versao no GitHub: %REMOTE_VER%
echo.

if "%LOCAL_VER%"=="%REMOTE_VER%" (
    echo [2/3] A extensao ja esta atualizada. Nenhuma acao necessaria.
    del temp_manifest.json
    goto fim
)

echo [2/3] Nova versao encontrada. Baixando arquivos...

:: ---------- baixa TUDO em temporarios antes de aplicar ----------
set FALHOU=0

for %%F in (content.js hubsoft_auto.js content.css background.js icon.png) do (
    %CURL% -o "temp_%%F" "%REPO_URL%/%%F?t=%RANDOM%"
    if errorlevel 1 (
        echo     AVISO: falha ao baixar %%F
        set FALHOU=1
    )
)

if "!FALHOU!"=="1" (
    echo.
    echo ERRO: algum arquivo nao pode ser baixado.
    echo Nada foi alterado, sua extensao continua funcionando.
    echo Tente de novo em alguns minutos.
    if exist temp_manifest.json del temp_manifest.json
    for %%F in (content.js hubsoft_auto.js content.css background.js icon.png) do if exist "temp_%%F" del "temp_%%F"
    goto fim
)

:: ---------- baixa a versao nova deste proprio atualizador (nao fatal) ----------
:: Fica em arquivo separado; so e trocado no FINAL (um .bat nao pode se
:: sobrescrever enquanto esta rodando, o cmd le o arquivo aos poucos).
%CURL% -o atualizador_novo.bat "%REPO_URL%/atualizador.bat?t=%RANDOM%"
if errorlevel 1 (
    echo     AVISO: nao foi possivel baixar a nova versao do atualizador.
    echo            A extensao sera atualizada normalmente.
    if exist atualizador_novo.bat del atualizador_novo.bat
) else (
    findstr /c:"@echo off" atualizador_novo.bat >nul
    if errorlevel 1 (
        if exist atualizador_novo.bat del atualizador_novo.bat
    ) else (
        rem igual ao atual? entao nao precisa trocar
        fc /b "%~f0" atualizador_novo.bat >nul
        if not errorlevel 1 (
            del atualizador_novo.bat
        ) else (
            set SELF_UPDATE=1
        )
    )
)

:: ---------- so agora aplica; manifest por ultimo ----------
for %%F in (content.js hubsoft_auto.js content.css background.js icon.png) do (
    move /y "temp_%%F" "%%F" >nul
)
move /y temp_manifest.json manifest.json >nul

echo.
echo [3/3] Atualizacao concluida! Versao %REMOTE_VER% instalada.
if "!SELF_UPDATE!"=="1" echo     O proprio atualizador tambem foi atualizado.
echo.

:: ---------- fim ----------
echo =======================================================
echo  PRONTO! Agora volte para a aba do James e clique em
echo  "JA ATUALIZEI, TENTAR DE NOVO" na janela da extensao.
echo  Ela vai recarregar sozinha.
echo =======================================================
echo.

:fim
echo.
pause
if "%SELF_UPDATE%"=="1" goto autoatualizar
goto :eof

:autoatualizar
:: "(goto) 2>nul" encerra o contexto do .bat (libera o arquivo) e o comando
:: seguinte ainda executa: troca este atualizador pelo novo. Sem saida na tela.
(goto) 2>nul & move /y "atualizador_novo.bat" "%~f0" >nul
