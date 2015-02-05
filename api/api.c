#include <dlfcn.h>
#include <caml/mlvalues.h>
#include <pthread.h>
#include <stdlib.h>
#include <sys/types.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>

#include "api.h"

int arith (int a, int b)
{
  return (a+b);
}

void print (char * a)
{
  printf("%s\n", a);
}

void function_list (FL ** a)
{
  if (!*a) abort ();
  (*a)->c_arith = arith;
  (*a)->c_print = print;
  (*a)->c_function_list = function_list;
};
