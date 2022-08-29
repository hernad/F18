#include <stdio.h>
#include <Python.h>

#define SHARED_LIB

#include "zh_vm_pub.h"
#include "zh_trace.h"
//#include "zh_pcode.h"
#include "zh_init.h"
//#include "zh_xvm.h"

#if defined( _MSC_VER )
#include <windows.h>
#endif

#if defined( SHARED_LIB )
int run_main( int argc, char * argv[] );
#else
int main( int argc, char * argv[] );
#endif

void simple_printf(const char* fmt, ...);

PyObject *f18lib_set_callback(PyObject *self, PyObject *args);
