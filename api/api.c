#include <dlfcn.h>
#include <caml/mlvalues.h>
#include <pthread.h>
#include <stdlib.h>
#include <sys/types.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>

#include "api.h"

int c_arith (int a, int b)
{
  return (a+b);
}

int c_print (char * a)
{
  printf("print %s\n", a);
  fflush(stdout);
}

int c_function_list (struct FUNCTION_LIST ** a)
{
  if (!a) abort ();
  *a = malloc(sizeof(struct FUNCTION_LIST));
  (*a)->c_arith = &c_arith;
  (*a)->c_print = &c_print;
  (*a)->c_function_list = &c_function_list;
};
