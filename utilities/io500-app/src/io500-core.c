/*
 * License: MIT license
 */
#include <getopt.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <utilities.h>
#include <ior.h>
#include <mdtest.h>
#include "io500.h"


#define IOR_HARD_OPTIONS "ior -C -Q 1 -g -G 27 -k -e -t 47008 -b 47008"
#define IOR_EASY_OPTIONS "ior -k"
#define MDTEST_EASY_OPTIONS "mdtest -F"
#define MDTEST_HARD_OPTIONS "mdtest -w 3901 -e 3901 -t -F"

static int size;
static char * workdir = "";
static int stdin_cp;

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
      "\t-E <IOR hard options>: any acceptable IOR easy option, default: %s\n"
      "\t-s <seconds>: Stonewall timer for create, default: %d\n"
      "\t-m <N>: Max segments for ioreasy\n"
      "\t-M <N>: Max segments for iorhard\n"
      "\t-f <N>: Max number of files for mdeasy\n"
      "\t-F <N>: Max number of files for mdhard\n"
      "\t-h: prints the help\n"
      "\t-v: increase the verbosity\n",
      res->ior_easy_options,
      res->ior_hard_options,
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
  res->ior_hard_options = strdup("");
  res->mdtest_easy_options = strdup("-u -L");
  res->mdeasy_max_files = 100000000;
  res->mdhard_max_files = 100000000;
  res->stonewall_timer = 300;
  res->ioreasy_max_segments = 100000000;
  res->iorhard_max_segments = 100000000;

  int c;
  while (1) {
    c = getopt(argc, argv, "a:e:hvw:f:F:s:c:C:m:");
    if (c == -1) {
        break;
    }

    switch (c) {
    case 'a':
        res->backend_name = strdup(optarg); break;
    case 'e':
        res->ior_easy_options = strdup(optarg); break;
    case 'E':
        res->ior_hard_options = strdup(optarg); break;
    case 'm':
        res->mdtest_easy_options = strdup(optarg); break;
    case 's':
      res->stonewall_timer = atol(optarg); break;
    case 'h':
      io500_print_help(res);
    case 'v':
      res->verbosity++; break;
    case 'w':
      res->workdir = strdup(optarg); break;
    case 'c':
      res->ioreasy_max_segments = atol(optarg); break;
    case 'C':
      res->iorhard_max_segments = atol(optarg); break;
    case 'f':
      res->mdeasy_max_files = atol(optarg); break;
    case 'F':
      res->mdhard_max_files = atol(optarg); break;
    }
  }
  io500_replace_str(res->ior_easy_options);
  io500_replace_str(res->ior_hard_options);
  io500_replace_str(res->mdtest_easy_options);
  return res;
}

static void io500_error(){
  if(rank == 0){
    printf("IO500 error: %s\n", CurrentTimeString());
  }
  exit(1);
}

static IOR_test_t * io500_io_hard_create(io500_options_t * options){
  //generic array holding the arguments to the subtests
  char args[10000];
  int argc_count;
  int pos;
  pos = sprintf(args, IOR_HARD_OPTIONS" -w");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -D %d -O stoneWallingWearOut=1", options->stonewall_timer);
  pos += sprintf(& args[pos], " -s %d", options->ioreasy_max_segments);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_hard/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_hard_options);

  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  IOR_test_t * res = ior_run(argc_count, args_array);
  free(args_array);
  return res;
}


static IOR_test_t * io500_io_hard_read(io500_options_t * options, IOR_test_t * create_read){
  //generic array holding the arguments to the subtests
  char args[10000];
  int argc_count;
  int pos;
  pos = sprintf(args, IOR_HARD_OPTIONS" -R");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -O stoneWallingWearOutIterations=%d", create_read->results->pairs_accessed);
  pos += sprintf(& args[pos], " -s %d", options->ioreasy_max_segments);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_hard/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_hard_options);

  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  IOR_test_t * res = ior_run(argc_count, args_array);
  free(args_array);
  return res;
}


static IOR_test_t * io500_io_easy_create(io500_options_t * options){
  //generic array holding the arguments to the subtests
  char args[10000];
  int argc_count;
  int pos;
  pos = sprintf(args, IOR_EASY_OPTIONS" -w");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -D %d -O stoneWallingWearOut=1", options->stonewall_timer);
  pos += sprintf(& args[pos], " -s %d", options->ioreasy_max_segments);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_easy/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_easy_options);

  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  IOR_test_t * res = ior_run(argc_count, args_array);
  free(args_array);
  return res;
}

static IOR_test_t * io500_io_easy_read(io500_options_t * options, IOR_test_t * create_read){
  //generic array holding the arguments to the subtests
  char args[10000];
  int argc_count;
  int pos;
  pos = sprintf(args, IOR_EASY_OPTIONS" -r");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -O stoneWallingWearOutIterations=%d", create_read->results->pairs_accessed);
  pos += sprintf(& args[pos], " -s %d", options->ioreasy_max_segments);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_easy/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_easy_options);

  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  IOR_test_t * res = ior_run(argc_count, args_array);
  free(args_array);
  return res;
}

static table_t * io500_run_mdtest_easy(io500_options_t * options, char mode, int maxfiles, int use_stonewall, const char * extra){
  char args[10000];
  memset(args, 0, 10000);

  int argc_count;
  int pos;
  pos = sprintf(args, MDTEST_EASY_OPTIONS" -%c", mode);
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  pos += sprintf(& args[pos], " -n %d", maxfiles);
  if(use_stonewall){
    pos += sprintf(& args[pos], " -W %d", options->stonewall_timer);
  }
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], "%s", extra);
  io500_replace_str(args);
  pos += sprintf(& args[pos], "\n-d\n%s/mdtest_easy", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->mdtest_easy_options);

  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  table_t * table = mdtest_run(argc_count, args_array);
  free(args_array);
  return table;
}

static table_t * io500_md_easy_create(io500_options_t * options){
  if(rank == 0){
    printf("Running MD_EASY_CREATE: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_easy(options, 'C', options->mdeasy_max_files, 1, "");
}

static table_t * io500_md_easy_read(io500_options_t * options, table_t * create_read){
  if(rank == 0){
    printf("Running MD_EASY_READ: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_easy(options, 'E', create_read->items, 0, "");
}

static table_t * io500_md_easy_stat(io500_options_t * options, table_t * create_read){
  if(rank == 0){
    printf("Running MD_EASY_STAT: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_easy(options, 'T', create_read->items, 0, "");
}


static table_t * io500_md_easy_delete(io500_options_t * options, table_t * create_read){
  if(rank == 0){
    printf("Running MD_EASY_DELETE: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_easy(options, 'r', create_read->items, 0, "");
}


static table_t * io500_run_mdtest_hard(io500_options_t * options, char mode, int maxfiles, int use_stonewall, const char * extra){
  char args[10000];
  int argc_count;
  int pos;
  pos = sprintf(args, MDTEST_HARD_OPTIONS" -%c", mode);
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  pos += sprintf(& args[pos], " -n %d", maxfiles);
  if(use_stonewall){
    pos += sprintf(& args[pos], " -W %d", options->stonewall_timer);
  }
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], "%s", extra);
  io500_replace_str(args);
  pos += sprintf(& args[pos], "\n-d\n%s/mdtest_hard", options->workdir);
  //pos += sprintf(& args[pos], "\n%s", options->mdtest_easy_options);
  char ** args_array;
  args_array = io500_str_to_arr(args, & argc_count);
  table_t * table = mdtest_run(argc_count, args_array);
  free(args_array);
  return table;
}

static table_t * io500_md_hard_create(io500_options_t * options){
  if(rank == 0){
    printf("Running MD_HARD_CREATE: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_hard(options, 'C', options->mdhard_max_files, 1, "");
}

static table_t * io500_md_hard_read(io500_options_t * options, table_t * create_read){
  if(rank == 0){
    printf("Running MD_HARD_READ: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_hard(options, 'E', create_read->items, 0, "");
}

static table_t * io500_md_hard_stat(io500_options_t * options, table_t * create_read){
  if(rank == 0){
    printf("Running MD_HARD_Stat: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_hard(options, 'T', create_read->items, 0, "");
}

static table_t * io500_md_hard_delete(io500_options_t * options, table_t * create_read){
  if(rank == 0){
    printf("Running MD_HARD_DELETE: %s\n", CurrentTimeString());
  }
  return io500_run_mdtest_hard(options, 'r', create_read->items, 0, "");
}

static void io500_recursively_create(const char * dir){
  char tmp[10000]; // based on https://stackoverflow.com/questions/2336242/recursive-mkdir-system-call-on-unix
  char *p = NULL;
  size_t len;
  snprintf(tmp, sizeof(tmp),"%s",dir);
  len = strlen(tmp);
  if(tmp[len - 1] == '/'){
    tmp[len - 1] = 0;
  }
  for(p = tmp + 1; *p; p++){
    if(*p == '/') {
      *p = 0;
      io500_recursively_create(tmp);
      *p = '/';
    }
  }
  mkdir(tmp, S_IRWXU);
}

static void io500_check_workdir(io500_options_t * options){
  // todo, ensure that the working directory contains no legacy stuff
  char dir[10000];
  sprintf(dir, "%s/ior_hard/", options->workdir);
  io500_recursively_create(dir);
  sprintf(dir, "%s/ior_easy/", options->workdir);
  io500_recursively_create(dir);
  sprintf(dir, "%s/mdtest_easy/", options->workdir);
  io500_recursively_create(dir);
  sprintf(dir, "%s/mdtest_hard/", options->workdir);
  io500_recursively_create(dir);
}

static void io500_cleanup(){
  printf("TODO cleanup !\n");
}

static void io500_print_bw(const char * prefix, int id, IOR_test_t * stat, int read){
  double timer = read ? stat->results->readTime[0] : stat->results->writeTime[0];
  printf("IOR %d %s time: %fs size: %ld bytes bw: %.3f GiB/s\n",
  id, prefix,
  timer,
  stat->results->aggFileSizeFromXfer[0],
  stat->results->aggFileSizeFromXfer[0] / 1024.0 / 1024.0 / 1024.0 / timer);
}

static void io500_print_md(const char * prefix, int id, int pos, table_t * stat){
  double val = stat->entry[pos] / 1000;
  //for(int i=0; i < 10; i++){
  //  if(stat->entry[i] != 0){
  //    printf("%d %f\n", i, stat->entry[i]);
  //  }
  //}

  printf("mdtest %d %s %.3f kioops\n", id, prefix, val);
}


int main(int argc, char ** argv){
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);
  if(rank == 0){
    printf("IO500 starting: %s\n", CurrentTimeString());
  }
  io500_options_t * options = io500_parse_args(argc, argv);

  if(rank == 0){
    io500_check_workdir(options);
  }

  IOR_test_t * io_easy_create = io500_io_easy_create(options);
  table_t *    md_easy_create = io500_md_easy_create(options);

  // touch ...
  IOR_test_t * io_hard_create = io500_io_hard_create(options);
  table_t *    md_hard_create = io500_md_hard_create(options);

  // mdreal...
  io500_find_results_t* io500_find(options);

  IOR_test_t * io_easy_read = io500_io_easy_read(options, io_easy_create);
  table_t *    md_easy_read = io500_md_easy_read(options, md_easy_create);
  table_t *    md_hard_stat = io500_md_hard_stat(options, md_hard_create);

  IOR_test_t * io_hard_read = io500_io_hard_read(options, io_hard_create);
  table_t *    md_hard_read = io500_md_hard_read(options, md_hard_create);
  table_t *    md_easy_stat = io500_md_easy_stat(options, md_easy_create);

  table_t *    md_hard_delete = io500_md_hard_delete(options, md_hard_create);
  table_t *    md_easy_delete = io500_md_easy_delete(options, md_easy_create);

  if(rank == 0){
    printf("IO500 complete: %s\n", CurrentTimeString());

    printf("\n");
    printf("=== IO-500 submission ===\n");

    io500_print_bw("ior_easy_write", 1, io_easy_create, 0);
    io500_print_bw("ior_easy_read", 2, io_easy_read, 1);
    io500_print_bw("ior_hard_write", 3, io_hard_create, 0);
    io500_print_bw("ior_hard_read", 4, io_hard_read, 1);

    io500_print_md("mdtest_easy_create", 1, 4, md_easy_create);
    io500_print_md("mdtest_easy_read",   2, 6, md_easy_read);
    io500_print_md("mdtest_easy_stat",   3, 5, md_easy_stat);
    io500_print_md("mdtest_easy_delete", 4, 7, md_easy_delete);

    io500_print_md("mdtest_hard_create", 5, 4, md_hard_create);
    io500_print_md("mdtest_hard_read",   6, 6, md_hard_read);
    io500_print_md("mdtest_hard_stat",   7, 5, md_hard_stat);
    io500_print_md("mdtest_hard_delete", 8, 7, md_hard_delete);
    io500_cleanup();
  }
  MPI_Finalize();
  return 0;
}
