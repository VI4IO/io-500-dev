/*
 * License: MIT license
 */
#include <getopt.h>

#include <utilities.h>
#include <ior.h>
#include <mdtest.h>
#include "io500.h"

static int size;
static char * workdir = "";

static char ** io500_str_to_arr(char * str, int * out_count){
  // str is separated on "\n"
  int cnt = 1;
  for(int i=0; str[i] != 0; i++){
    if(str[i] == '\n'){
      cnt++;
    }
  }
  char ** out_arr = malloc(sizeof(void*) * cnt);
  *out_count = cnt;

  int pos = 0;
  out_arr[pos] = & str[0];
  for(int i=0; str[i] != 0; i++){
    if(str[i] == '\n'){
      pos++;
      out_arr[pos] = & str[i+1];
      str[i] = 0;
    }
  }
  return out_arr;
}
static void io500_print_help(){
  printf("IO500 benchmark\nSynopsis:\n"
      "\t-a <API>: API for I/O [POSIX|MPIIO|HDF5|HDFS|S3|S3_EMC|NCMPI]\n"
      "\t-h: prints the help\n"
      "\t-v: increase the verbosity\n"
      "\t-w <DIR>: The working directory for the benchmarks\n"
    );
  exit(0);
}

static io500_options_t * io500_parse_args(int argc, char ** argv){
  io500_options_t * res = malloc(sizeof(io500_options_t));

  res->backend_name = "POSIX";
  res->workdir = ".";
  res->verbosity = 0;

  int c;
  while (1) {
    c = getopt(argc, argv, "a:hvw:");
    if (c == -1) {
        break;
    }

    switch (c) {
    case 'a':
        res->backend_name = strdup(optarg); break;
    case 'h':
      io500_print_help();
    case 'v':
      res->verbosity++; break;
    case 'w':
      res->workdir = strdup(optarg); break;
    }
  }
  return res;
}

static void io500_error(){
  if(rank == 0){
    printf("IO500 error: %s\n", CurrentTimeString());
  }
  exit(1);
}

static void io500_io_easy(io500_options_t * options){

}

static IOR_test_t * io500_io_easy_create(io500_options_t * options){
  //generic array holding the arguments to the subtests
  char args[10000];
  int argc_count;
  int pos;
  char ** args;
  pos = sprintf(args, "ior\n-w\n-k\n-s\n1");
  pos += sprintf(& args[pos], "\n-o\n%s/file", options->workdir);
  pos += sprintf(& args[pos], "\n-a\n%s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], "\n-v");
  }
  args = io500_str_to_arr(args, & argc_count);
  return ior_run(argc_count, args);
}

static IOR_test_t * io500_io_hard_create(io500_options_t * options){
  return NULL;
}

static IOR_test_t * io500_io_easy_read(io500_options_t * options, IOR_test_t * create_stat){
  return NULL;
}

static IOR_test_t * io500_io_hard_read(io500_options_t * options, IOR_test_t * create_stat){
  return NULL;
}


static table_t * io500_md_easy_create(io500_options_t * options){
  char args[10000];
  int argc_count;
  int pos;
  char ** args;
  pos = sprintf(args, "mdtest\n-i\n1\n-n\n1");
  pos += sprintf(& args[pos], "\n-d\n%s", options->workdir);
  pos += sprintf(& args[pos], "\n-a\n%s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], "\n-v");
  }
  args = io500_str_to_arr(args, & argc_count);
  return mdtest_run(argc_count, args);
}

static table_t * io500_md_easy_read(io500_options_t * options, table_t * create_stat){
  return NULL;
}

static table_t * io500_md_easy_delete(io500_options_t * options, table_t * create_stat){
  return NULL;
}

static table_t * io500_md_hard_create(io500_options_t * options){
  return NULL;
}

static table_t * io500_md_hard_read(io500_options_t * options, table_t * create_stat){
  return NULL;
}

static table_t * io500_md_hard_delete(io500_options_t * options, table_t * create_stat){
  return NULL;
}


int main(int argc, char ** argv){
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  if(rank == 0){
    printf("IO500 starting: %s\n", CurrentTimeString());
  }
  io500_options_t * options = io500_parse_args(argc, argv);

  IOR_test_t * io_easy_create = io500_io_easy_create(options);
  IOR_test_t * io_hard_create = io500_io_hard_create(options);
  table_t *    md_easy_create = io500_md_easy_create(options);
  table_t *    md_hard_create = io500_md_hard_create(options);

  io500_find_results_t* io500_find(options);

  IOR_test_t * io_easy_read = io500_io_easy_read(options, io_easy_create);
  IOR_test_t * io_hard_read = io500_io_hard_read(options, io_hard_create);

  table_t *    md_easy_read = io500_md_easy_read(options, io_easy_create);
  table_t *    md_hard_read = io500_md_hard_read(options, io_hard_create);

  table_t *    md_easy_delete = io500_md_easy_delete(options, io_easy_create);
  table_t *    md_hard_delete = io500_md_hard_delete(options, io_hard_create);

  printf("IOR create count: %ld errors: %ld time: %fs size: %ld bytes \n", io_easy_create->results->pairs_accessed, totalErrorCount,
  io_easy_create->results->writeTime[0],
  io_easy_create->results->aggFileSizeFromXfer[0] );

  for(int i=0; i < 10; i++){
    printf("%d = %f\n", i, mdtable->entry[i]);
  }

  if(rank == 0){
    printf("IO500 complete: %s\n", CurrentTimeString());
  }
  MPI_Finalize();
  return 0;
}
