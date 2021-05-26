#include "F18-klijent.h"
#include "zh_api.h"
#include "zh_item_api.h"
#include <Python.h>

ZH_FUNC_EXTERN( MAIN );
ZH_INIT_SYMBOLS_BEGIN( zh_vm_SymbolInit_F18_ZH )
{ "MAIN", { ZH_FS_PUBLIC | ZH_FS_FIRST | ZH_FS_LOCAL }, { ZH_FUNCNAME( MAIN ) }, NULL }
ZH_INIT_SYMBOLS_EX_END( zh_vm_SymbolInit_F18_ZH, "F18KLIJENT", 0x0, 0x0003 )

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

#if defined( SHARED_LIB )
int run_main( int argc, char * argv[] )
#else
int main( int argc, char * argv[] )
#endif
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
   zh_vmInit( 1, 1 );
   //puts("");
   puts("************************ end F18-klijent ****************************");

   return zh_vmQuit( ZH_TRUE );
}


void simple_printf(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
 
    while (*fmt != '\0') {
        if (*fmt == 'd') {
            int i = va_arg(args, int);
            printf("%d\n", i);
        } else if (*fmt == 'c') {
            // A 'char' variable will be promoted to 'int'
            // A character literal in C is already 'int' by itself
            int c = va_arg(args, int);
            printf("%c\n", c);
        } else if (*fmt == 'f') {
            double d = va_arg(args, double);
            printf("%f\n", d);
        }
        ++fmt;
    }
 
    va_end(args);
}


static PyObject *
f18lib_system(PyObject *self, PyObject *args)
{
    const char *command;
    int sts;

    if (!PyArg_ParseTuple(args, "s", &command))
        return NULL;
    sts = system(command);
    return PyLong_FromLong(sts);
}

static PyObject *
f18lib_f18(PyObject *self, PyObject *args)
{
   const char *command;
   //char *argv[1];
   char* f18_args[] = { "--help", NULL };
    //int sts;

   if (!PyArg_ParseTuple(args, "s", &command))
        return NULL;
   //sts = system(command);
   //argv[0] = command;
   
   ZH_TRACE( ZH_TR_INFO, ( "main(%d, %p)", 1, ( void * ) f18_args ) );

   printf("dynsymcount: %d\n", zh_dynsymCount());

   zh_cmdargInit( 1, f18_args );

   zh_vmInit( ZH_TRUE, ZH_TRUE );
   zh_vmQuit( ZH_FALSE );
   return PyLong_FromLong(0);
}

static PyObject *
f18lib_f18_1(PyObject *self, PyObject *args)
{
   const char *command;
   //char *argv[1];
   char* f18_args[] = { "--help", NULL };
    //int sts;

   if (!PyArg_ParseTuple(args, "s", &command))
        return NULL;
   //sts = system(command);
   //argv[0] = command;
   
   ZH_TRACE( ZH_TR_INFO, ( "main(%d, %p)", 1, ( void * ) f18_args ) );

   printf("dynsymcount: %d\n", zh_dynsymCount());

   //zh_cmdargInit( 1, f18_args );
   zh_memvarsClear(ZH_TRUE);

   zh_vmInit( ZH_TRUE, ZH_FALSE );
   zh_vmQuit( ZH_FALSE );

   return PyLong_FromLong(0);
}

static PyObject *
f18lib_vminit(PyObject *self, PyObject *args)
{

   zh_vmInit( ZH_FALSE, ZH_TRUE );

   zh_conRelease();

   return PyLong_FromLong(0);
}


static PyObject *
ziher_conInit(PyObject *self, PyObject *args)
{

   zh_conInit();

   return PyLong_FromLong(0);
}

static PyObject *
ziher_conRelease(PyObject *self, PyObject *args)
{

   zh_conRelease();

   return PyLong_FromLong(0);
}


static PyObject *
f18lib_run(PyObject *self, PyObject *args)
{

   char *sFunc;
   int initConsole = 0;
   int releaseConsole = 0;

   if (!PyArg_ParseTuple(args, "s|ii", &sFunc, &initConsole, &releaseConsole))
        return NULL;

   PZH_SYMBOL pDynSym =  zh_dynsymFind( sFunc );

   if (initConsole)
      zh_conInit();
      

   if( pDynSym )
   {
      zh_vmPushDynSym( pDynSym );
      zh_vmPushNil();
      zh_vmProc( 0 );
   } else {
       printf("nema ziher func %s\n", sFunc);
   }

   if (releaseConsole)
      zh_conRelease();

   return PyLong_FromLong(0);
}


static PyObject *
f18lib_run_get(PyObject *self, PyObject *args)
{

   char *sFunc;
   int initConsole = 0;
   int releaseConsole = 0;
   const char *ret;
   PyObject *pyValue;

   // https://stackoverflow.com/questions/10625865/how-does-pyarg-parsetupleandkeywords-work


   if (!PyArg_ParseTuple(args, "s|ii", &sFunc, &initConsole, &releaseConsole))
        return NULL;

   PZH_SYMBOL pDynSym =  zh_dynsymFind( sFunc );

   if (initConsole)
      zh_conInit();
      
   if( pDynSym )
   {
      zh_vmPushDynSym( pDynSym );
      zh_vmPushNil();
      // vmdo je funkcija
      zh_vmDo( 0 );

      //PZH_ITEM pResult = zh_itemNew( zh_stackReturnItem() );
      //PZH_ITEM pResult = zh_stackReturnItem();
      const char * ret = zh_parc( -1 );
      printf("return: %s\n", ret);
      pyValue = Py_BuildValue("s", ret);
      
   
   } else {
       printf("nema ziher func %s\n", sFunc);
   }

   //#define zh_retc( szText )                    zh_itemPutC( zh_stackReturnItem(), szText )

   

/*
   if( pRetVal && ZH_IS_STRING( pRetVal ) ) {
       ret = zh_itemGetCPtr(pRetVal);
       pyValue = PyUnicode_FromString(ret);
   } else {
       pyValue = PyUnicode_FromString("");
   }

*/

   if (releaseConsole)
      zh_conRelease();

   //return PyUnicode_FromString(ret);
   return pyValue;
}


static PyObject *
f18lib_put_get(PyObject *self, PyObject *args)
{

   char *sFunc, *sParam;
   int initConsole = 0;
   int releaseConsole = 0;
   const char *ret;
   PyObject *pyValue;

   if (!PyArg_ParseTuple(args, "ss|ii", &sFunc, &sParam, &initConsole, &releaseConsole))
        return NULL;

   PZH_SYMBOL pDynSym = zh_dynsymFind( sFunc );

   if (initConsole)
      zh_conInit();
      
   if( pDynSym )
   {
      zh_vmPushDynSym( pDynSym );
      zh_vmPushNil(); //pSelf = zh_stackSelfItem();   /* NIL, OBJECT or BLOCK */

      //printf("sParam='%s'\n", sParam);
     
      zh_vmPushString(sParam, strlen( sParam ));
      //zh_vmPushLogical();
      //zh_vmPushInteger();
      //zh_vmPushItemRef();

      puts("step 4x");
      zh_vmDo( 1 ); // 1 param
      //zh_vmProc(1);
      puts("step 5x");

      const char * ret = zh_parc( -1 );
      printf("return: %s\n", ret);
      pyValue = Py_BuildValue("s", ret);
      
   
   } else {
       printf("nema ziher func %s\n", sFunc);
   }


   if (releaseConsole)
      zh_conRelease();

   //return PyUnicode_FromString(ret);
   return pyValue;
}

static PyObject *
f18lib_hash(PyObject *self, PyObject *args) {

   char *sFunc, *sParam;
   int initConsole = 0;
   int releaseConsole = 0;
   PyObject *pyValue = NULL;
   char *cKey1 = "key1";
   char *cValue1 = "value 1";

   if (!PyArg_ParseTuple(args, "s|ii", &sFunc, &sParam, &initConsole, &releaseConsole))
        return NULL;

   PZH_SYMBOL pDynSym = zh_dynsymFind( sFunc );

   if (initConsole)
      zh_conInit();
      
   if( pDynSym )
   {
      zh_vmPushDynSym( pDynSym );
      zh_vmPushNil(); //pSelf = zh_stackSelfItem();   /* NIL, OBJECT or BLOCK */

puts("step 1");     
     PZH_ITEM pHash = zh_hashNew( NULL );

     //for( iParam = 1; iParam <= iPCount; iParam += 2 )
     PZH_ITEM pKey = zh_itemNew( NULL );
     PZH_ITEM pValue = zh_itemNew( NULL );
     //zh_vmPushString( cKey1, strlen( cKey1 ));
     //PZH_ITEM pValue = zh_vmPushString( cValue1, strlen( cValue1 ));
     zh_itemPutC( pKey, "key1" );
     zh_itemPutC( pValue, "value1");
     zh_hashAdd( pHash, pKey, pValue );
puts("step 2");  
     //zh_itemRelease( pKey );
     //zh_itemRelease( pValue );

puts("step 3");  
     zh_vmPush(pHash);

puts("step 4");  
     zh_vmDo( 1 );

puts("step 5");
     PZH_ITEM pHashRet = zh_param( -1, ZH_IT_HASH);
     int len = zh_hashLen( pHashRet );
     // https://stackoverflow.com/questions/51632300/python-c-api-problems-trying-to-build-a-dictionary
     
     pyValue = PyDict_New();
     for( int i = 1; i <= len; i++) {
        PZH_ITEM pKey = zh_hashGetKeyAt( pHashRet, i );
        PZH_ITEM pValue = zh_hashGetValueAt( pHashRet, i );
        char *cKey = "00", *cValue = "?";
        if( ( zh_itemType( pKey ) & ZH_IT_STRING ) && ( zh_itemType( pValue ) & ZH_IT_STRING ) ) {
           //const char * szText = zh_itemGetCPtr( pText );
           //int iWidth, iDec, iLen = ( int ) zh_itemGetCLen( pText );
           cKey = zh_itemGetCPtr( pKey );
           cValue = zh_itemGetCPtr( pValue);
           printf("key=%s value=%s\n", cKey, cValue);
        }
        //Py_BuildValue("{s:i,s:O}",
        //   cKey, cValue);
        PyDict_SetItemString(pyValue, cKey, Py_BuildValue("s", cValue));
     }

    }

    if (releaseConsole)
      zh_conRelease();

    return pyValue;
}

static PyObject *
f18lib_razrijedi(PyObject *self, PyObject *args)
{

   char *sParam1;

   if (!PyArg_ParseTuple(args, "s", &sParam1))
        return NULL;

   //puts("step 3");
   //zh_memvarsClear(ZH_TRUE);

   PZH_ITEM func = zh_itemPutCPtr(NULL, "RAZRIJEDI");
   PZH_ITEM p1 = zh_itemPutC(NULL, sParam1);
   PZH_ITEM pResult = zh_itemDo( func, 1, p1, 0);
   if (!ZH_IS_STRING(pResult))
      printf("\nrezultat nije string ?!\n");
   
   const char *ret = zh_itemGetCPtr(pResult);
   printf("evo rezultat razrijedi: %s", ret);
   
   return PyLong_FromLong(0);
}

static PyMethodDef F18LibMethods[] = {
    {"system",  f18lib_system, METH_VARARGS, "Execute a shell command."},
    {"f18",  f18lib_f18, METH_VARARGS, "Execute f18 command."},
    {"vminit",  f18lib_vminit, METH_VARARGS, "Execute f18 command /1."},
    {"con_init",  ziher_conInit, METH_VARARGS, "ziher initialize console"},
    {"con_release",  ziher_conRelease, METH_VARARGS, "ziher release console"},
    {"run",  f18lib_run, METH_VARARGS, "run ziher func"},
    {"run_get",  f18lib_run_get, METH_VARARGS, "run ziher func"},
    {"put_get",  f18lib_put_get, METH_VARARGS, "run ziher func"},
    {"razrijedi",  f18lib_razrijedi, METH_VARARGS, "Execute f18 command /2."},
    {"hash",  f18lib_hash, METH_VARARGS, "in/out hash"},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef F18klijentLibModule = {
    PyModuleDef_HEAD_INIT,
    "f18klijentlib",   /* name of module */
    NULL, /* module documentation, may be NULL */
    -1,       /* size of per-interpreter state of the module,
                 or -1 if the module keeps state in global variables. */
    F18LibMethods
};


PyMODINIT_FUNC
PyInit_f18klijentlib(void)
{
    
    // zh_itemDoC( "init_ziher_py", 0, 0);
    return PyModule_Create(&F18klijentLibModule);
}
