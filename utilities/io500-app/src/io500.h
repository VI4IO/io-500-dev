#ifndef _IO500_H
#define _IO500_H

#include <stdint.h>

typedef struct{
  char * backend_name;
  char * workdir;
  int verbosity;
} io500_options_t;

typedef struct{
  uint64_t errors;
} io500_find_results_t;

io500_find_results_t* io500_find(io500_options_t * opt);

#endif
