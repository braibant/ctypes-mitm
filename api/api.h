/* the api that we implement */

typedef struct FUNCTION_LIST FL;


typedef int (*f_arith) (int,int);
typedef int (*f_print) (char*);
typedef int (*f_function_list) (FL **);

struct FUNCTION_LIST {
  f_arith c_arith;
  f_print c_print;
  f_function_list c_function_list;
};

int c_arith (int a,int b);
int c_print (char* a);
int c_function_list (struct FUNCTION_LIST ** f);
