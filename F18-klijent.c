#include "F18-klijent.h"
#include "zh_api.h"
#include "zh_item_api.h"
#include <Python.h>



extern void ext_zh_vm_SymbolInit_F18_UTILS_ZH( void );

/*
ZH_FUNC_EXTERN( MAIN );
//ZH_FUNC_EXTERN( FUNC_HELLO_ZIHER );
//ZH_FUNC_EXTERN( FUNC_HELLO_ZIHER_2 );

ZH_INIT_SYMBOLS_BEGIN( zh_vm_SymbolInit_F18_ZH )
 { "MAIN", { ZH_FS_PUBLIC | ZH_FS_FIRST | ZH_FS_LOCAL }, { ZH_FUNCNAME( MAIN ) }, NULL },
// { "FUNC_HELLO_ZIHER",   { ZH_FS_PUBLIC }, { ZH_FUNCNAME( FUNC_HELLO_ZIHER )  }, NULL },
// { "FUNC_HELLO_ZIHER_2", { ZH_FS_PUBLIC }, { ZH_FUNCNAME( FUNC_HELLO_ZIHER_2 ) }, NULL }
ZH_INIT_SYMBOLS_EX_END( zh_vm_SymbolInit_F18_ZH, "F18KLIJENT", 0x0, 0x0003 )
*/

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
f18lib_vminit(PyObject *self, PyObject *args)
{

   ZH_BOOL bStartMainProc = 0;
   ZH_BOOL bInitRT = 0;
   ZH_BOOL bReleaseConsole = 0;

   if (!PyArg_ParseTuple(args, "iii", &bStartMainProc, &bInitRT, &bReleaseConsole))
        return NULL;

   zh_vmInit( bStartMainProc, bInitRT );
   if (bReleaseConsole)
      zh_conRelease();
   return PyLong_FromLong(0);
}


static PyObject *
f18lib_vmquit(PyObject *self, PyObject *args)
{

   ZH_BOOL bInitRT = 0;

   if (!PyArg_ParseTuple(args, "i", &bInitRT))
        return NULL;

   return PyLong_FromLong(zh_vmQuit( bInitRT ));
}

static PyObject *
f18lib_fill_dyntable_0(PyObject *self, PyObject *args)
{
   //ext_zh_vm_SymbolInit_ZH_INIT_ZH();
}

static PyObject *
f18lib_fill_dyntable(PyObject *self, PyObject *args)
{

  printf("dynsymcount prije: %d\n", zh_dynsymCount());
  
  if( zh_rddRegister( "DBF", 1 ) <= 1 )
  {
      zh_rddRegister( "DBFFPT", 1 );
      if( zh_rddRegister( "DBFCDX", 1 ) <= 1 )
         return;
  }


  printf("dynsymcount poslije: %d\n", zh_dynsymCount());

  //zh_vmProcessSymbols( symbols_table, ZH_SIZEOFARRAY( symbols_table ), "F18KLIJENT", 0, 0 );

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
   int returnType = 0;

   const char *ret;
   PyObject *pyValue;

   // https://stackoverflow.com/questions/10625865/how-does-pyarg-parsetupleandkeywords-work

   if (!PyArg_ParseTuple(args, "s|iii", &sFunc, &initConsole, &releaseConsole, &returnType))
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

      if (returnType == 0) {
         const char * ret = zh_parc( -1 );
         //printf("return: %s\n", ret);
         pyValue = Py_BuildValue("s", ret);
      } else {
         int ret = zh_parni( -1 );
         //printf("return: %s\n", ret);
         pyValue = Py_BuildValue("i", ret);
      }
   
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

// >>> import f18klijentlib; f18klijentlib.vminit()
// >>> f18klijentlib.hash("PP_2",1,1)
// init console
//    
// (hash): key1 / value1 ; release console                                                                                                       
// 
// key=1 value=OK
// key=2 value=OK2
// {'1': 'OK', '2': 'OK2'}

static PyObject *
f18lib_hash(PyObject *self, PyObject *args) {

   char *sFunc;
   int initConsole = 0;
   int releaseConsole = 0;
   PyObject *pyValue = NULL;
   char *cKey1 = "key1";
   char *cValue1 = "value 1";

   if (!PyArg_ParseTuple(args, "s|ii", &sFunc, &initConsole, &releaseConsole))
        return NULL;

   if (initConsole) {
      puts("init console");
      zh_conInit();
   }

   PZH_SYMBOL pDynSym = zh_dynsymFind( sFunc );
      
   if( pDynSym )
   {
      zh_vmPushDynSym( pDynSym );
      zh_vmPushNil(); //pSelf = zh_stackSelfItem();   /* NIL, OBJECT or BLOCK */
   
     PZH_ITEM pHash = zh_hashNew( NULL );

     //for( iParam = 1; iParam <= iPCount; iParam += 2 )
     PZH_ITEM pKey = zh_itemNew( NULL );
     PZH_ITEM pValue = zh_itemNew( NULL );
     //zh_vmPushString( cKey1, strlen( cKey1 ));
     //PZH_ITEM pValue = zh_vmPushString( cValue1, strlen( cValue1 ));
     zh_itemPutC( pKey, "key1" );
     zh_itemPutC( pValue, "value1");
     zh_hashAdd( pHash, pKey, pValue );
 
     //zh_itemRelease( pKey );
     //zh_itemRelease( pValue );
 
     zh_vmPush(pHash);
     zh_vmDo( 1 );

     if (releaseConsole) {
      puts("release console");
      zh_conRelease();
     }

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

    

    return pyValue;
}

// void qsort(void *base, size_t nitems, size_t size, int (*compar)(const void *, const void*))
// base − This is the pointer to the first element of the array to be sorted.
// nitems − This is the number of elements in the array pointed by base.
// size − This is the size in bytes of each element in the array.
// compar − This is the function that compares two elements.

// ova funkcija prima argumente u c formatu, izvrsava ranije setovanu python callback funkciju  
// i rezultat vraca u c formatu 

//static PyObject *s_py_callback_func = NULL;


// ziher: py_callback(2, 3 ) => python => ret number
//ZH_FUNC( PY_CALLBACK )
//{
//   //char *       pszFree;
//   //const char * pszFileName = zh_fsNameConv( zh_parcx( 2 ), &pszFree );
//
//   int zhArg1 = zh_parni( 1 ); /* retrieve a numeric parameter as a integer */
//   int zhArg2 = zh_parni( 2 );
//
//   // zh_retni - integer to ziher numbeer
//   zh_retni( c_consumer_py_callback( zhArg1, zhArg2 ) );
//
//   //if( pszFree )
//   //   zh_xfree( pszFree );
//}

//int c_consumer_py_callback(int cva, int cvb) {
//
//   int retvalue = 0;
//   const PyObject *pya = Py_BuildValue("i", cva);
//   const PyObject *pyb = Py_BuildValue("i", cvb);
//
//    // Build up the argument list tuple
//    PyObject *arglist = Py_BuildValue("(OO)", pya, pyb);
//
//    // ...for calling the Python function
//    PyObject *result = PyEval_CallObject(s_py_callback_func, arglist);
//
//    if (result && PyLong_Check(result)) {
//        retvalue = PyLong_AsLong(result);
//    }
//
//    Py_XDECREF(result);
//    Py_DECREF(arglist);
//
//    return retvalue;
//}


// https://www.oreilly.com/library/view/python-cookbook/0596001673/ch16s07.html

// python side

// >>> def callback_2(a,b):
// ...     return (a+b)*10
// >>> f18klijentlib.set_callback(callback)
// >>> f18klijentlib.hash("PP_2",1,1)
// init console
//    
// py_callback(10,10):        200                                                                                                                
// (hash): key1 / value1 ; release console
// 
// key=1 value=OK
// key=2 value=OK2
// {'1': 'OK', '2': 'OK2'}
// >>> def callback_2(a,b):
// ...     return (a+b)*5
// ... 
// >>> f18klijentlib.set_callback(callback_2)
// >>> f18klijentlib.hash("PP_2",1,1)
// init console
//    
// py_callback(10,10):        100                                                                                                                
// (hash): key1 / value1 ; release console
// 
// key=1 value=OK
// key=2 value=OK2
// {'1': 'OK', '2': 'OK2'}

// ziher strana

//FUNCTION pp_2( x )
//
//  ...
//   ? "py_callback(10,10):", py_callback(10,10)
//
//   ? _tmp
//   RETURN hRet

//static PyObject *
//f18lib_set_callback(PyObject *self, PyObject *args)
//{
//
//  
//  PyObject *pyCallback;
//  //PyObject *list;
//  if (!PyArg_ParseTuple(args, "O", &pyCallback))
//       return NULL;
//
//   if (!PyCallable_Check(pyCallback)) {
//        PyErr_SetString(PyExc_TypeError, "Need a callable object!");
//    } else {
//        // Save the compare function. This obviously won't work for multithreaded
//        // programs and is not even a reentrant, alas -- qsort's fault!
//        s_py_callback_func = pyCallback;
//        /*
//        if (PyList_Check(list)) {
//            int size = PyList_Size(list);
//            int i;
//
//            // Make an array of (PyObject *), because qsort does not know about
//            // the PyList object
//            PyObject **v = (PyObject **) malloc( sizeof(PyObject *) * size );
//            for (i=0; i<size; ++i) {
//                v[i] = PyList_GetItem(list, i);
//                // Increment the reference count, because setting the list 
//                // items below will decrement the reference count
//                Py_INCREF(v[i]);
//            }
//            c_consumer_callback(v, size, sizeof(PyObject*), pyCallback);
//            for (i=0; i<size; ++i) {
//                PyList_SetItem(list, i, v[i]);
//                // need not do Py_DECREF - see above
//            }
//            free(v);
//        }
//        */
//    }
//    Py_INCREF(Py_None);
//    return Py_None;
//}

static PyMethodDef F18LibMethods[] = {
    {"system",  f18lib_system, METH_VARARGS, "Execute a shell command."},
    {"f18",  f18lib_f18, METH_VARARGS, "Execute f18 command."},
    {"vminit",  f18lib_vminit, METH_VARARGS, "Execute f18 command /1."},
    {"vmquit",  f18lib_vmquit, METH_VARARGS, "Quit ziher VM"},
    {"fill_dyntable",  f18lib_fill_dyntable, METH_VARARGS, "fill dyn table"},
    {"fill_dyntable_0",  f18lib_fill_dyntable_0, METH_VARARGS, "fill dyn table_0"},
    {"con_init",  ziher_conInit, METH_VARARGS, "ziher initialize console"},
    {"con_release",  ziher_conRelease, METH_VARARGS, "ziher release console"},
    {"run",  f18lib_run, METH_VARARGS, "run ziher func"},
    {"run_get",  f18lib_run_get, METH_VARARGS, "run ziher func"},
    {"put_get",  f18lib_put_get, METH_VARARGS, "run ziher func"},
    {"hash",  f18lib_hash, METH_VARARGS, "in/out hash"},
//    {"set_callback",  f18lib_set_callback, METH_VARARGS, "set callback function"},
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
