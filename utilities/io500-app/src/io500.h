#ifndef _IO500_H
#define _IO500_H

#include <stdint.h>

typedef struct{
  char * backend_name;
  char * workdir;

  char * ior_easy_options;
  char * ior_hard_options;
  char * mdtest_easy_options;

  int ioreasy_max_segments;
  int iorhard_max_segments;
  int mdhard_max_files;
  int mdeasy_max_files;
  int stonewall_timer;
  int stonewall_timer_reads;
  int stonewall_timer_delete;

  int only_cleanup;

  int verbosity;
} io500_options_t;

typedef struct{
  uint64_t errors;

  uint64_t found_files;
  uint64_t total_files;

  double rate;
  double runtime;
} io500_find_results_t;

io500_find_results_t* io500_find(io500_options_t * opt);

void io500_error(char * const str);
int io500_parallel_find_or_delete(char * workdir, char * const filename_pattern, int delete, int stonewall_timer_s);
#endif
