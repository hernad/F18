#include <stdio.h>

#include "zh_vm_pub.h"
#include "zh_trace.h"
//#include "zh_pcode.h"
#include "zh_init.h"
//#include "zh_xvm.h"

#if defined( _MSC_VER )
#include <windows.h>
#endif

ZH_FUNC_EXTERN( MAIN );

//ZH_FUNC_EXTERN( ZH_CODEPAGE_SL852 );
//ZH_FUNC_EXTERN( ZH_CODEPAGE_SLISO );
//ZH_FUNC_EXTERN( ZH_CODEPAGE_SLWIN );
//ZH_FUNC_EXTERN( DBFCDX );
//ZH_FUNC_EXTERN( DBFFPT );
//ZH_FUNC_EXTERN( ZH_GT_WIN );
//ZH_FUNC_EXTERN( ZH_GT_WIN_DEFAULT );
//ZH_FUNC_EXTERN( ARRAYRDD );
//ZH_FUNC_INITSTATICS();

ZH_INIT_SYMBOLS_BEGIN( zh_vm_SymbolInit_F18_ZH )
{ "MAIN", { ZH_FS_PUBLIC | ZH_FS_FIRST | ZH_FS_LOCAL }, { ZH_FUNCNAME( MAIN ) }, NULL }
ZH_INIT_SYMBOLS_EX_END( zh_vm_SymbolInit_F18_ZH, "", 0x0, 0x0003 )

//{ "(_INITSTATICS00001)", { ZH_FS_INITEXIT | ZH_FS_LOCAL }, { zh_INITSTATICS }, NULL }


//#define DLLIMPORT __declspec(dllimport)


//extern "C" DLLEXPORT void say_hello(char *);
//DLLIMPORT void dll_say_hello(char *message);

//ZH_IMPORT ZH_FUNC(MAIN);
// typedef int                 ZH_BOOL;
// #define ZH_TRUE  ( ! 0 )

//extern DLLIMPORT
//void     zh_vmInit( int bStartMainProc );
//int      zh_vmQuit( void ); /* Immediately quits the virtual machine, return ERRORLEVEL code */
//void     zh_cmdargInit( int argc, char * argv[] ); /* initialize command-line argument API's */

int main( int argc, char * argv[] )
{

   //dll_say_hello("Hello dll", "22");

/*
C:\dev\ziher\src>dumpbin /imports bazel-bin\test\run_hello_dbf_win.exe

Dump of file bazel-bin\test\run_hello_dbf_win.exe

File Type: EXECUTABLE IMAGE

  Section contains the following imports:

    dll_hello_dbf.dll
             14025BBA0 Import Address Table
             1402F1768 Import Name Table
                     0 time date stamp
                     0 Index of first forwarder reference

                         1EA dll_say_hello
*/

   //puts("************************** run_hello_dbf win *****************************");
   ZH_TRACE( ZH_TR_INFO, ( "main(%d, %p)", argc, ( void * ) argv ) );

   zh_cmdargInit( argc, argv );
   puts("-- 2 --");
   zh_vmInit( 1 );
   //puts("");
   puts("************************ end F18-klijent ****************************");

   return zh_vmQuit();
}
