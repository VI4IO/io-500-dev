#include <aiori.h>

#include "io500.h"

// parallel recursive find

io500_find_results_t* io500_find(io500_options_t * opt){
  io500_find_results_t * res = malloc(sizeof(io500_find_results_t));
  memset(res, 0, sizeof(*res));

  ior_aiori_t * backend = aiori_select(opt->backend_name);

  return res;
}
