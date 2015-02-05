/* the api that we implement */

typedef struct FUNCTION_LIST FL;


typedef int (*f_arith) (int,int);
typedef void (*f_print) (char*);
typedef void (*f_function_list) (FL **);

struct FUNCTION_LIST {
  f_arith c_arith;
  f_print c_print;
  f_function_list c_function_list;
};

int arith (int,int);
void print (char*);
void function_list (FL**);
