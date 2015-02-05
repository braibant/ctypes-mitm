#include <caml/mlvalues.h>
#include <pthread.h>
#include <stdlib.h>
#include <sys/types.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include "../api/api.h"
#include <dlfcn.h>
#include <assert.h>

extern void caml_main(char* argv[]);

static volatile int num_threads = 0;
static char** argv_global;

static void* thread_body(void* lib)
{
  pid_t tid;
  useconds_t sleep_before, sleep_after;
  tid = syscall(SYS_gettid);
  sleep_before = rand() % 10000; /* 10ms */
  sleep_after = rand() % 10000; /* 10ms */
  printf("thread_body tid %d, sleep before %ld us, sleep after %ld us, ",
         tid, sleep_before, sleep_after);
  printf("num active threads %d\n", ++num_threads);
  fflush(stdout);
  usleep(sleep_before);

  void* p;

  f_arith arith;
  f_function_list function_list;
  f_print print;

  int a,b,r;

  switch(rand () %2)
    {
    case 0:
      arith = dlsym(lib, "c_arith");
      if (!arith) abort();
      a = rand () % 1000;
      b = rand () % 1000;
      r = arith (a,b);
      usleep(sleep_after);
      break;
    case 1:
      function_list = dlsym(lib, "c_function_list");
      if (!function_list) abort();
      struct FUNCTION_LIST * functions;
      function_list(&functions);
      a = rand () % 1000;
      b = rand () % 1000;
      r = functions->c_arith (a,b);
      if (r != a + b) {printf("%d != %d\n", r, a + b);};
      usleep(sleep_after);
      /* free(functions); */
      break;
    default:
      break;
    };

  printf("tid %d exiting\n", tid);

  fflush(stdout);
  --num_threads;
  return NULL;
}

int main(int argc, char* argv[])
{
  void* lib;
  argv_global = argv;

  if (!(argc > 0)) abort ();
  lib = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
  if (!lib) {
    printf("dl %s\n", dlerror());
    fflush(stdout);
    abort();
  }

  printf("starting thread creation loop\n");
  fflush(stdout);
  while (1) {
    pthread_t handle;
    pthread_create(&handle, NULL, &thread_body, lib);
    usleep(1000); /* 100ms */
  }

  return 0;
}
