@shift /0
@ECHO OFF
COLOR 3f
SETLOCAL ENABLEDELAYEDEXPANSION
SET APP_NAME=URTool 3.0 - Unpack Repack Tool
SET AUTHORS=[by JamFlux]
SET APP_DESCRIPTION=Extraccion y reempaquetado de archivos .DAT e .IMG en android 5 - 7
set CYGWIN=nodosfilewarning
TITLE %APP_NAME% %AUTHORS%

::Comprueba carpetas y las crea si no existen
IF NOT EXIST "1-Sources" MKDIR "1-Sources"
IF NOT EXIST "2-Converted_IMG" MKDIR "2-Converted_IMG"
IF NOT EXIST "3-IMG_Folder"  MKDIR "3-IMG_Folder"
IF NOT EXIST "3-IMG_Folder"\system MKDIR "3-IMG_Folder"\system
IF NOT EXIST "3-IMG_Folder"\boot MKDIR "3-IMG_Folder"\boot
IF NOT EXIST "3-IMG_Folder"\recovery MKDIR "3-IMG_Folder"\recovery
IF NOT EXIST "4-Folder_To_IMG" MKDIR "4-Folder_To_IMG"
IF NOT EXIST 5-New_DAT_Ready MKDIR 5-New_DAT_Ready

::Reconoce los archivos .zip y los enumera para su eleccion
:ZIP_FILES
CLS
ECHO ==============================================================================
ECHO ==                       %APP_NAME%                    ==
ECHO ==============================================================================
ECHO ==                                %AUTHORS%                              ==
ECHO ==============================================================================
ECHO =     %APP_DESCRIPTION%    =
ECHO ==============================================================================
ECHO.
ECHO.
ECHO.
ECHO Seleccione el archivo ROM zip que desea convertir:
ECHO.
ECHO.
SET /A i=1
FOR %%k IN (*.zip) DO (
	SET ZIP!i!=%%k
	ECHO !i! - %%k
	SET /A i+=1
)
ECHO.
ECHO.
SET /P NUMBER=Escriba un numero: 
IF NOT DEFINED NUMBER GOTO :ZIP_FILES
IF /I %NUMBER% GEQ %i% GOTO :ZIP_FILES
IF /I %NUMBER% LSS 1 GOTO :ZIP_FILES
SET FILE=!ZIP%NUMBER%!

IF NOT EXIST "%FILE%" GOTO :ZIP_FILES

:MENU
CLS
SET "LIMPIEZA="
ECHO ==============================================================================
ECHO ==                       %APP_NAME%                    ==
ECHO ==============================================================================
ECHO ==                                %AUTHORS%                              ==
ECHO ==============================================================================
ECHO =     %APP_DESCRIPTION%    =
ECHO ==============================================================================
ECHO.
ECHO.
ECHO Escoja una opcion:
ECHO.
ECHO 1- Convertir DAT a IMG                           6- Convertir IMG a CARPETA
ECHO 2- Convertir IMG a DAT                           7- Convertir CARPETA a IMG
ECHO 3- Desempaquetar boot.IMG                        8- Desempaquetar recovery.IMG
ECHO 4- Empaquetar boot.IMG                           9- Empaquetar recovery.IMG
ECHO 5- Actualizar ZIP de origen                      0- Actualizar ZIP de origen
ECHO.
ECHO.
SET /P NUMBER=Escriba un numero: 
IF "%NUMBER%"=="1" GOTO OPCION1
IF "%NUMBER%"=="2" GOTO OPCION2
IF "%NUMBER%"=="3" GOTO OPCION3
IF "%NUMBER%"=="4" GOTO OPCION4
IF "%NUMBER%"=="5" GOTO OPCION5
IF "%NUMBER%"=="6" GOTO OPCION6
IF "%NUMBER%"=="7" GOTO OPCION7
IF "%NUMBER%"=="8" GOTO OPCION8
IF "%NUMBER%"=="9" GOTO OPCION9
IF "%NUMBER%"=="0" GOTO OPCION0
GOTO MENU


::Convierte DAT A IMG y lo extrae
:OPCION1
CD "%~dp0"
CLS
ECHO -------------------------------------
ECHO Extrayendo archivos desde el zip ROM
ECHO -------------------------------------
ECHO.
ECHO.
ECHO En breve el proceso terminara...
Tools\7za.exe e "%FILE%" n system.new.dat -o1-Sources>nul
Tools\7za.exe e "%FILE%" n system.transfer.list -o1-Sources>nul
Tools\7za.exe e "%FILE%" n file_contexts -o1-Sources>nul
CLS
Tools\sdat2img 1-Sources\system.transfer.list 1-Sources\system.new.dat 2-Converted_IMG\system.img
CLS
ECHO ---------------------------------------------
ECHO Pasando system.IMG a carpeta en 3-IMG_Folder
ECHO ---------------------------------------------
ECHO.
Tools\ImgExtractor.exe 2-Converted_IMG\system.img 3-IMG_Folder\system
CLS
ECHO --------------------
ECHO Terminado con exito
ECHO --------------------
ECHO.
ECHO.
ECHO Ahora puede modificar cosas en la carpeta 3-IMG_Folder\system
ECHO.
ECHO.
ECHO ----------------------
ECHO ENTER para ir al MENU
ECHO ----------------------
PAUSE>NUL
GOTO MENU

::Convierte del IMG extraido a DAT
:OPCION2
CLS
FOR /R "%~p0"\2-Converted_IMG %%A IN (*) DO SET SIZE=%%~zA
tools\make_ext4fs -T 0 -S 1-Sources\file_contexts -l %SIZE% -a system 4-Folder_To_IMG\my_new_system.img 3-IMG_Folder\system\
IF NOT EXIST "%~dp0"\4-Folder_To_IMG\my_new_system.img goto OPCION2.1

:OPCION2.1
CLS
FOR %%A IN ("2-Converted_IMG"\system.img) DO SET SIZE=%%~zA
tools\make_ext4fs -T 0 -S 1-Sources\file_contexts -l %SIZE% -a system 4-Folder_To_IMG\my_new_system.img 3-IMG_Folder\system\
GOTO OPCION2.2

:OPCION2.2
CLS
ECHO Creando sistema esparcido...
ECHO.
Tools\ext2simg -v 4-Folder_To_IMG\my_new_system.img 4-Folder_To_IMG\system_sparse.img
CLS
ECHO --------------------------------------------
ECHO Elija la version android actual del ZIP ROM
ECHO --------------------------------------------
ECHO.
ECHO.
Tools\img2sdat.py 4-Folder_To_IMG\system_sparse.img
CLS
MOVE system.new.dat 5-New_DAT_Ready
MOVE system.transfer.list 5-New_DAT_Ready
XCOPY 1-Sources\file_contexts 5-New_DAT_Ready
DEL system.patch.dat
DEL 4-Folder_To_IMG\system_sparse.img
CD "%~dp0"
CD Tools
DEL blockimgdiff.pyc
DEL common.pyc
DEL rangelib.pyc
DEL sparse_img.pyc
CLS
ECHO ---------------------
ECHO Terminado con exito
ECHO ---------------------
ECHO.
ECHO.
ECHO ------------------------------------------------------
ECHO Los archivos finales fueron movidos a 5-New_DAT_Ready
ECHO ------------------------------------------------------
ECHO.
ECHO ENTER para ir al MENU
PAUSE>NUL
GOTO MENU

::Desempaquetar boot.img de la ROM
:OPCION3
CLS
CD "%~dp0"
Tools\7za.exe e "%FILE%" n boot.img -o3-IMG_Folder\boot
CD "%~dp0"
XCOPY Tools\bootimg.exe 3-IMG_Folder\boot
CD 3-IMG_Folder\boot
bootimg.exe --unpack-bootimg
RENAME boot.img boot-original.img
DEL boot-old.img
CLS
ECHO Puede editar los archivos de la carpeta initrd en 3-IMG_Folder\boot
ECHO.
ECHO ENTER para volver al MENU
PAUSE>NUL
GOTO MENU

::Empaquetar boot.img de la ROM
:OPCION4
CLS
CD "%~dp0"
CD "3-IMG_Folder"\boot
bootimg.exe --repack-bootimg
RENAME boot-new.img boot.img
XCOPY boot.img "%~dp0"\4-Folder_To_IMG
XCOPY boot.img "%~dp0"
DEL bootimg.exe boot.img boot-original.img
CD "%~dp0"
Tools\7za.exe a "%FILE%" -o+ boot.img
DEL boot.img
CLS
ECHO El nuevo boot.img editado fue puesto en el zip de origen y
ECHO tambien lo encontrara en la carpeta 4-Folder_To_IMG
ECHO.
ECHO ENTER para volver al MENU
PAUSE>NUL
GOTO MENU

::Actualiza el zip original con los nuevos cambios
:OPCION5
ECHO Preparando entorno de trabajo...
move 1-Sources\file_contexts "%~dp0"
move 5-New_DAT_Ready\system.new.dat "%~dp0"
move 5-New_DAT_Ready\system.transfer.list "%~dp0"
CLS
ECHO -----------------------------
ECHO Actualizando zip original...
ECHO -----------------------------
ECHO.
CD "%~dp0"
CLS
Tools\7za.exe a "%FILE%" -o+ system.new.dat 
Tools\7za.exe a "%FILE%" -o+ system.transfer.list
Tools\7za.exe a "%FILE%" -o+ file_contexts
CLS
ECHO --------------------
ECHO Terminado con exito
ECHO --------------------
ECHO.
ECHO.
CLS   ===============================================================================
ECHO  ================= Desea hacer una limpieza de los directorios? ================
ECHO.
ECHO.
ECHO  ======= Limpiar: S ============================================ Menu: N =======
ECHO.
ECHO.
ECHO.
SET /P LIMPIEZA=Tome una decision:
IF "%LIMPIEZA%" == "n" GOTO MENU
IF "%LIMPIEZA%" == "N" GOTO MENU
IF "%LIMPIEZA%" == "S" GOTO CLEAN
IF "%LIMPIEZA%" == "s" GOTO CLEAN

:CLEAN
RMDIR /Q /S 1-Sources
RMDIR /Q /S 2-Converted_IMG
RMDIR /Q /S 3-IMG_Folder
RMDIR /Q /S 4-Folder_To_IMG
RENAME 5-New_DAT_Ready Nuevo_DAT
RMDIR /Q /S Nuevo_DAT
DEL system.new.dat system.transfer.list file_contexts
CLS
ECHO Limpieza terminada
del C:\Users\%username%\AppData\Local\Temp /f /s /q *.bat
rd C:\Users\%username%\AppData\Local\Temp /s /q *.bat
del c:\Windows\Temp /f /s /q *.bat
rd c:\Windows\Temp /s /q *.bat
del %Temp% /f /s /q *.bat
rd %Temp% /s /q *.bat
GOTO SALIR

:CLEAN2
RMDIR /Q /S 1-Sources
RMDIR /Q /S 2-Converted_IMG
RMDIR /Q /S 3-IMG_Folder
RMDIR /Q /S 4-Folder_To_IMG
RMDIR /Q /S 5-New_DAT_Ready
DEL system.img
CLS
ECHO Limpieza terminada
del C:\Users\%username%\AppData\Local\Temp /f /s /q *.bat
rd C:\Users\%username%\AppData\Local\Temp /s /q *.bat
del c:\Windows\Temp /f /s /q *.bat
rd c:\Windows\Temp /s /q *.bat
del %Temp% /f /s /q *.bat
rd %Temp% /s /q *.bat
GOTO SALIR

::Convierte IMG a CARPETA desde el zip de origen
:OPCION6
CLS
CD "%~dp0"
Tools\7za.exe e "%FILE%" n system.img -o2-Converted_IMG
Tools\7za.exe e "%FILE%" n file_contexts -o1-Sources
CLS
ECHO NOTA: Si no cuenta un zip que contenga system.img copie y pegue 
ECHO system.img a la carpeta 2-Converted_IMG
ECHO Necesitara para empaquetar de nuevo el archivo file_contexts adecuado
ECHO.
ECHO Pasando system.IMG a carpeta en 3-IMG_Folder
ECHO.
tools\ImgExtractor.exe 2-Converted_IMG\system.img 3-IMG_Folder\system
CLS
ECHO Terminado con exito
ECHO Ahora puede modificar cosas en la carpeta 3-IMG_Folder\system
ECHO.
ECHO ENTER para ir al MENU
PAUSE>NUL
GOTO MENU


::Convierte CARPETA a IMG
:OPCION7
CLS
FOR /R "%~p0"\2-Converted_IMG %%A IN (*) DO SET SIZE=%%~zA
tools\make_ext4fs -T 0 -S 1-Sources\file_contexts -l %SIZE% -a system 4-Folder_To_IMG\my_new_system.img 3-IMG_Folder\system\
IF NOT EXIST "%~dp0"\4-Folder_To_IMG\my_new_system.img goto OPCION7.1

:OPCION7.1
CLS
FOR %%A IN ("2-Converted_IMG"\system.img) DO SET SIZE=%%~zA
CD "%~dp0"
tools\make_ext4fs -T 0 -S 1-Sources\file_contexts -l %SIZE% -a system 4-Folder_To_IMG\my_new_system.img 3-IMG_Folder\system\
CLS
ECHO --------------------
ECHO Terminado con exito
ECHO --------------------
ECHO.
ECHO.
ECHO -----------------------------------------------------------
ECHO En la carpeta 4-Folder_To_IMG encontrara my_new_system.img
ECHO -----------------------------------------------------------
ECHO.
ECHO ENTER para ir al MENU
PAUSE>NUL
GOTO MENU

::Desempaquetado del recovery.img
:OPCION8
CLS
CD "%~dp0"
Tools\7za.exe e "%FILE%" n recovery.img -o3-IMG_Folder\recovery
CD "%~dp0"
CLS
ECHO NOTA: Si no cuenta un zip que contenga recovery.img copie y pegue 
ECHO recovery.img a la carpeta 3-IMG_Folder\recovery
ECHO.
XCOPY Tools\bootimg.exe 3-IMG_Folder\recovery
CD 3-IMG_Folder\recovery
RENAME recovery.img boot.img
bootimg.exe --unpack-bootimg
RENAME boot.img recovery-original.img
DEL boot-old.img
CLS
ECHO Puede editar los archivos de la carpeta initrd en 3-IMG_Folder\recovery
ECHO.
ECHO ENTER para volver al MENU
PAUSE>NUL
GOTO MENU

::Empaquetado del recovery.img
:OPCION9
CLS
CD "%~dp0"
CD "3-IMG_Folder"\recovery
bootimg.exe --repack-bootimg
RENAME boot-new.img recovery.img
XCOPY recovery.img "%~dp0"\4-Folder_To_IMG
XCOPY recovery.img "%~dp0"
DEL bootimg.exe recovery.img recovery-original.img
CD "%~dp0"
Tools\7za.exe a "%FILE%" -o+ recovery.img
DEL recovery.img
CLS
ECHO El nuevo recovery.img editado fue puesto en el zip de origen y
ECHO tambien lo encontrara en la carpeta 4-Folder_To_IMG
ECHO.
ECHO ENTER para volver al MENU
PAUSE>NUL
GOTO MENU

::Actualiza el zip original con los nuevos cambios
:OPCION0
CLS
CD "%~dp0"
ECHO Preparando entorno de trabajo...
CD 4-Folder_To_IMG
RENAME my_new_system.img system.img
MOVE system.img "%~dp0"
CLS
CD "%~dp0"
ECHO Actualizando zip original...
ECHO.
Tools\7za.exe a "%FILE%" -o+ system.img
CLS
ECHO Terminado con exito
ECHO.
ECHO.
CLS   ===============================================================================
ECHO  ================= Desea hacer una limpieza de los directorios? ================
ECHO.
ECHO.
ECHO  ======= Limpiar: S ============================================ Menu: N =======
ECHO.
ECHO.
ECHO.
SET /P LIMPIEZA=Tome una decision:
IF "%LIMPIEZA%" == "n" GOTO MENU
IF "%LIMPIEZA%" == "N" GOTO MENU
IF "%LIMPIEZA%" == "S" GOTO CLEAN2
IF "%LIMPIEZA%" == "s" GOTO CLEAN2

