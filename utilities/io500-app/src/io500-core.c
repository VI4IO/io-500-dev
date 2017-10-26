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

static void io500_replace_str(char * str){
  for( ; *str != 0 ; str++ ){
    if(*str == ' '){
      *str = '\n';
    }
  }
}

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
static void io500_print_help(io500_options_t * res){
  printf("IO500 benchmark\nSynopsis:\n"
      "\t-a <API>: API for I/O [POSIX|MPIIO|HDF5|HDFS|S3|S3_EMC|NCMPI]\n"
      "\t-w <DIR>: The working directory for the benchmarks\n"
      "Optional flags\n"
      "\t-e <IOR easy options>: any acceptable IOR easy option, default: %s\n"
      "\t-s <seconds>: Stonewall timer for create, default: %d\n"
      "\t-m <N>: Max segments for ioreasy\n"
      "\t-M <N>: Max segments for iorhard\n"
      "\t-f <N>: Max number of files for mdeasy\n"
      "\t-F <N>: Max number of files for mdhard\n"
      "\t-h: prints the help\n"
      "\t-v: increase the verbosity\n",
      res->ior_easy_options,
      res->stonewall_timer
    );
  exit(0);
}

static io500_options_t * io500_parse_args(int argc, char ** argv){
  io500_options_t * res = malloc(sizeof(io500_options_t));

  res->backend_name = "POSIX";
  res->workdir = ".";
  res->verbosity = 0;

  res->ior_easy_options = strdup("-t 200m -b 200m -F");
  res->mdeasy_max_files = 100000000;
  res->mdhard_max_files = 100000000;
  res->stonewall_timer = 300;
  res->ioreasy_max_segments = 100000000;
  res->iorhard_max_segments = 100000000;

  int c;
  while (1) {
    c = getopt(argc, argv, "a:e:hvw:f:F:s:m:M:");
    if (c == -1) {
        break;
    }

    switch (c) {
    case 'a':
        res->backend_name = strdup(optarg); break;
    case 'e':
        res->ior_easy_options = strdup(optarg);
        break;
    case 's':
      res->stonewall_timer = atol(optarg); break;
    case 'h':
      io500_print_help(res);
    case 'v':
      res->verbosity++; break;
    case 'w':
      res->workdir = strdup(optarg); break;
    case 'm':
      res->ioreasy_max_segments = atol(optarg); break;
    case 'M':
      res->iorhard_max_segments = atol(optarg); break;
    case 'f':
      res->mdeasy_max_files = atol(optarg); break;
    case 'F':
      res->mdhard_max_files = atol(optarg); break;
    }
  }
  io500_replace_str(res->ior_easy_options);
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
  pos = sprintf(args, "ior -w -k ");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -D %d -O stoneWallingWearOut=1", options->stonewall_timer);
  pos += sprintf(& args[pos], " -s %d", options->ioreasy_max_segments);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_easy_options);

  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  IOR_test_t * res = ior_run(argc_count, args_array);
  free(args_array);
  return res;
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
  pos = sprintf(args, "mdtest -i 1 -u -L -F -C");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  pos += sprintf(& args[pos], " -n %d", options->mdeasy_max_files);
  pos += sprintf(& args[pos], " -W %d", options->stonewall_timer);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  io500_replace_str(args);
  pos += sprintf(& args[pos], "\n-d\n%s", options->workdir);

  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  table_t * table = mdtest_run(argc_count, args_array);
  free(args_array);
  return table;
}

static table_t * io500_md_easy_read(io500_options_t * options, table_t * create_stat){
  return NULL;
}

static table_t * io500_md_easy_delete(io500_options_t * options, table_t * create_stat){
    char args[10000];
    int argc_count;
    int pos;
    pos = sprintf(args, "mdtest -i 1 -u -L -F -r");
    pos += sprintf(& args[pos], " -a %s", options->backend_name);
    pos += sprintf(& args[pos], " -n %lld", create_stat->items);
    for(int i=0; i < options->verbosity; i++){ 
      pos += sprintf(& args[pos], " -v");
    }
    io500_replace_str(args);
    pos += sprintf(& args[pos], "\n-d\n%s", options->workdir);


    char ** args_array;
    args_array = io500_str_to_arr(args, & argc_count);
    table_t * table = mdtest_run(argc_count, args_array);
    free(args_array);
    return table;
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

static void io500_check_workdir(io500_options_t * options){
  // todo, ensure that the working directory contains no legacy stuff
}

int main(int argc, char ** argv){
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  if(rank == 0){
    printf("IO500 starting: %s\n", CurrentTimeString());
  }
  io500_options_t * options = io500_parse_args(argc, argv);

  io500_check_workdir(options);

  IOR_test_t * io_easy_create = io500_io_easy_create(options);
  IOR_test_t * io_hard_create = io500_io_hard_create(options);
  table_t *    md_easy_create = io500_md_easy_create(options);
  table_t *    md_hard_create = io500_md_hard_create(options);

  io500_find_results_t* io500_find(options);

  IOR_test_t * io_easy_read = io500_io_easy_read(options, io_easy_create);
  IOR_test_t * io_hard_read = io500_io_hard_read(options, io_hard_create);

  table_t *    md_easy_read = io500_md_easy_read(options, md_easy_create);
  table_t *    md_hard_read = io500_md_hard_read(options, md_hard_create);

  table_t *    md_easy_delete = io500_md_easy_delete(options, md_easy_create);
  table_t *    md_hard_delete = io500_md_hard_delete(options, md_hard_create);

  printf("IOR create count: %ld errors: %ld time: %fs size: %ld bytes \n", io_easy_create->results->pairs_accessed, totalErrorCount,
  io_easy_create->results->writeTime[0],
  io_easy_create->results->aggFileSizeFromXfer[0] );

  printf("Items: %lld\n", md_easy_create->items);
  for(int i=0; i < 10; i++){
    printf("%d = %f\n", i, md_easy_create->entry[i]);
  }

  if(rank == 0){
    printf("IO500 complete: %s\n", CurrentTimeString());
  }
  MPI_Finalize();
  return 0;
}
