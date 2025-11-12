@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM ModelSim/QuestaSim Windows automation script (Linux-like)
REM ============================================================

REM --- Detect ModelSim if MODEL_TECH not set ---
if "%MODEL_TECH%"=="" (
    echo Searching for ModelSim installation...
    set "MODEL_TECH="
    for /f "tokens=*" %%D in ('dir /b /ad /o-n "C:\intelFPGA*" 2^>nul') do (
        if exist "C:\%%D\modelsim_ase\win64\vsim.exe" set "MODEL_TECH=C:\%%D\modelsim_ase\win64" & goto found
        if exist "C:\%%D\modelsim_ase\win32aloem\vsim.exe" set "MODEL_TECH=C:\%%D\modelsim_ase\win32aloem" & goto found
        if exist "C:\%%D\modelsim_ase\win32\vsim.exe" set "MODEL_TECH=C:\%%D\modelsim_ase\win32" & goto found
        if exist "C:\%%D\modelsim\win64\vsim.exe" set "MODEL_TECH=C:\%%D\modelsim\win64" & goto found
        if exist "C:\%%D\modelsim\win32\vsim.exe" set "MODEL_TECH=C:\%%D\modelsim\win32" & goto found
    )
)

:found
if "%MODEL_TECH%"=="" (
    echo ERROR: Could not find ModelSim installation.
    echo Please set the environment variable MODEL_TECH manually.
    exit /b 1
)

echo Using MODEL_TECH = %MODEL_TECH%
set "VSIM=%MODEL_TECH%\vsim.exe"
set "VLOG=%MODEL_TECH%\vlog.exe"
set "VMAP=%MODEL_TECH%\vmap.exe"
set "VLIB=%MODEL_TECH%\vlib.exe"

REM --- Simulation settings ---
set "TOPLEVEL=ucsbece154a_top_tb"
set "VSIM_OPTIONS=+acc=lprn +allow_unconnected"
set "PLUSARGS="
set "PARAMETERS="
set "EXTRA_OPTIONS=%VSIM_OPTIONS% %PLUSARGS% %PARAMETERS%"

REM --- VPI modules ---
set "VPI_MODULES="

REM --- Parse command ---
if "%1"=="" goto :help
if /I "%1"=="work" goto :work
if /I "%1"=="run" goto :run
if /I "%1"=="gui" goto :gui
if /I "%1"=="clean" goto :clean
goto :help

REM ============================================================
:work
echo.
echo === Creating work library ===
if exist work rmdir /S /Q work
"%VLIB%" work
"%VMAP%" -del work >nul 2>&1
"%VMAP%" work work

echo.
echo === Compiling RTL files via sim.tcl ===
"%VSIM%" -c -do "do sim.tcl; quit"
goto :eof

REM ============================================================
:run
echo.
echo === Running simulation (command-line) ===
if not exist work call "%~f0" work

REM Build VPI module options if any
set "VPI_ARGS="
for %%m in (%VPI_MODULES%) do set "VPI_ARGS=!VPI_ARGS! -pli %%m"

REM Run vsim with lenient flags and dummy signals
"%VSIM%" -c !VPI_ARGS! %EXTRA_OPTIONS% %TOPLEVEL% -do "run -all; quit -code [expr [coverage attribute -name TESTSTATUS -concise] >= 2 ? [coverage attribute -name TESTSTATUS -concise] : 0]"
goto :eof

REM ============================================================
:gui
echo.
echo === Launching GUI simulation ===
if not exist work call "%~f0" work
set "VPI_ARGS="
for %%m in (%VPI_MODULES%) do set "VPI_ARGS=!VPI_ARGS! -pli %%m"

"%VSIM%" !VPI_ARGS! %EXTRA_OPTIONS% %TOPLEVEL%
goto :eof

REM ============================================================
:clean
echo.
echo === Cleaning simulation artifacts ===
if exist work rmdir /S /Q work
if exist transcript del /Q transcript
if exist vsim.wlf del /Q vsim.wlf
if exist dump.fst del /Q dump.fst
echo Cleanup complete.
goto :eof

REM ============================================================
:help
echo.
echo Valid commands:
echo   work  → compile all RTL into work library via sim.tcl
echo   run   → run simulation in CLI with leniency flags
echo   gui   → launch GUI simulation
echo   clean → remove work and output files
echo.
goto :eof
