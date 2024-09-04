*----------------------------------------------------------------------------------------------------------------
* NOTIFICACI�N
*----------------------------------------------------------------------------------------------------------------

* Declaraci�n de la funci�n CreateProcess de la API de Windows
* Esta funci�n se utiliza para crear un nuevo proceso (ejecutar un programa).
DECLARE INTEGER CreateProcess IN kernel32;
   STRING lpApplicationName, ;            && Nombre de la aplicaci�n a ejecutar (puede ser nulo si se especifica en lpCommandLine)
   STRING lpCommandLine, ;                && L�nea de comandos que incluye el nombre del programa y sus argumentos
   INTEGER lpProcessAttributes, ;         && Atributos de seguridad del proceso (NULL en este caso)
   INTEGER lpThreadAttributes, ;          && Atributos de seguridad del hilo (NULL en este caso)
   INTEGER bInheritHandles, ;             && Indica si el proceso hijo heredar� los manejadores de la aplicaci�n
   INTEGER dwCreationFlags, ;             && Bandera que indica la prioridad y el modo de creaci�n del proceso
   INTEGER lpEnvironment, ;               && Variables de entorno del nuevo proceso (NULL para heredar las del padre)
   INTEGER lpCurrentDirectory, ;          && Directorio actual del proceso hijo (NULL para usar el directorio del padre)
   STRING @lpStartupInfo, ;               && Estructura que especifica c�mo se inicia el proceso (ventana oculta en este caso)
   STRING @lpProcessInformation           && Estructura que recibe informaci�n sobre el proceso e hilo creados

* Declaraci�n de la funci�n WaitForSingleObject de la API de Windows
* Esta funci�n se utiliza para esperar hasta que un objeto (como un proceso) est� en un estado se�alizado (completado).
DECLARE INTEGER WaitForSingleObject IN kernel32 ;
   INTEGER hHandle, ;                     && Manejador del proceso o hilo que se va a esperar
   INTEGER dwMilliseconds                 && Tiempo m�ximo de espera en milisegundos (-1 para esperar indefinidamente)

* Declaraci�n de la funci�n CloseHandle de la API de Windows
* Esta funci�n se utiliza para cerrar un manejador de proceso o hilo y liberar los recursos asociados.
DECLARE INTEGER CloseHandle IN kernel32 ;
   INTEGER hObject                        && Manejador del proceso o hilo que se desea cerrar

* Definici�n de constantes para el proceso
#DEFINE NORMAL_PRIORITY_CLASS 0x20        && Prioridad normal para el proceso
#DEFINE STARTF_USESHOWWINDOW 0x00000001   && Indica que la estructura STARTUPINFO contiene una bandera para el estado de la ventana
#DEFINE SW_HIDE 0                         && Oculta la ventana del proceso

* Variables locales para el comando, informaci�n de inicio y proceso
LOCAL lcCommand, lcStartupInfo, lcProcessInfo

* Obtener el directorio actual donde se est� ejecutando el PRG
LOCAL lcCurrentDir
lcCurrentDir = JUSTPATH(FULLPATH(SYS(16,0)))  && Obtiene el directorio completo del PRG en ejecuci�n

* Construir la ruta completa al script de Python en el directorio actual
LOCAL lcScriptPath
lcScriptPath = lcCurrentDir + "\notificacion.py"  && Asume que el script est� en el mismo directorio

* T�tulo y mensaje para la notificaci�n
LOCAL lcTitulo, lcMensaje
lcTitulo = "Alerta"
lcMensaje = "Este es un mensaje de prueba."

* Construir el comando para ejecutar el script de notificaci�n
lcCommand = "python " + lcScriptPath + " " + ;
            '"' + lcTitulo + '"' + " " + ;
            '"' + lcMensaje + '"'

* Inicializar las estructuras de STARTUPINFO y PROCESS_INFORMATION
lcStartupInfo = REPLICATE(CHR(0), 68)     && 68 bytes para STARTUPINFO
lcProcessInfo = REPLICATE(CHR(0), 16)     && 16 bytes para PROCESS_INFORMATION

* Configurar la estructura STARTUPINFO para ocultar la ventana del proceso
lcStartupInfo = LEFT(lcStartupInfo, 1) + ;
   CHR(SW_HIDE) + ;                       && Especifica que la ventana debe estar oculta
   SUBSTR(lcStartupInfo, 3)

* Llamar a CreateProcess para iniciar el proceso
IF CreateProcess(0, lcCommand, 0, 0, 1, NORMAL_PRIORITY_CLASS, 0, 0, @lcStartupInfo, @lcProcessInfo) != 0
   * Si CreateProcess devuelve distinto de 0, el proceso se cre� con �xito

   * Extraer el manejador del proceso desde lcProcessInfo
   LOCAL hProcess, hThread
   hProcess = ;
      ASC(SUBSTR(lcProcessInfo, 1, 1)) + ;         && Obtiene el primer byte y lo convierte a entero
      BITLSHIFT(ASC(SUBSTR(lcProcessInfo, 2, 1)), 8) + ;   && Desplaza el segundo byte 8 bits a la izquierda y suma
      BITLSHIFT(ASC(SUBSTR(lcProcessInfo, 3, 1)), 16) + ;  && Desplaza el tercer byte 16 bits a la izquierda y suma
      BITLSHIFT(ASC(SUBSTR(lcProcessInfo, 4, 1)), 24)      && Desplaza el cuarto byte 24 bits a la izquierda y suma

   * Extraer el manejador del hilo desde lcProcessInfo
   hThread = ;
      ASC(SUBSTR(lcProcessInfo, 5, 1)) + ;         && Similar al proceso, pero para el hilo
      BITLSHIFT(ASC(SUBSTR(lcProcessInfo, 6, 1)), 8) + ;
      BITLSHIFT(ASC(SUBSTR(lcProcessInfo, 7, 1)), 16) + ;
      BITLSHIFT(ASC(SUBSTR(lcProcessInfo, 8, 1)), 24)

   * Desactivar la consola de Visual FoxPro mientras espera que el proceso termine
   SET CONSOLE OFF

   * Esperar a que el proceso termine
   = WaitForSingleObject(hProcess, -1)    && Espera indefinidamente hasta que el proceso termine

   * Reactivar la consola de Visual FoxPro
   SET CONSOLE ON 

   * Cerrar los manejadores del proceso y del hilo para liberar recursos
   = CloseHandle(hThread)
   = CloseHandle(hProcess)
ELSE
   * Si CreateProcess falla, mostrar un mensaje de error
   MESSAGEBOX("Failed to execute process.")
ENDIF

* Cerrar cualquier base de datos abierta (si aplica)
CLOSE DATABASES
