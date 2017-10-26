#ifndef _IO500_H
#define _IO500_H

#include <stdint.h>

typedef struct{
  char * backend_name;
  char * workdir;

  char * ior_easy_options;

  int ioreasy_max_segments;
  int iorhard_max_segments;
  int mdhard_max_files;
  int mdeasy_max_files;
  int stonewall_timer;

  int verbosity;
} io500_options_t;

typedef struct{
  uint64_t errors;
} io500_find_results_t;

io500_find_results_t* io500_find(io500_options_t * opt);

#endif
