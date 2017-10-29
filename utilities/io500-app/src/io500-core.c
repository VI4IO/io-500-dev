/*
 * License: MIT license
 */
#include <getopt.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#include <utilities.h>
#include <ior.h>
#include <mdtest.h>
#include "io500.h"

#define IOR_HARD_OPTIONS "ior -C -Q 1 -g -G 27 -k -e -t 47008 -b 47008"
#define IOR_EASY_OPTIONS "ior -k"
#define MDTEST_EASY_OPTIONS "mdtest -F"
#define MDTEST_HARD_OPTIONS "mdtest -w 3900 -e 3900 -t -F"

static int size;

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
  if(rank == 0)
    printf("  Invoking:");
  for(int i=0; str[i] != 0; i++){
    if(str[i] == '\n'){
      pos++;
      out_arr[pos] = & str[i+1];
      str[i] = 0;
      if(rank == 0)
        printf(" \"%s\"", out_arr[pos - 1]);
    }
  }
  if(rank == 0)
    printf(" \"%s\"\n", out_arr[pos]);
  return out_arr;
}

static void io500_print_help(io500_options_t * res){
  if(rank != 0) return;
  printf("\nIO500 benchmark\nSynopsis:\n"
      "\t-a <API>: API for I/O [POSIX|MPIIO|HDF5|HDFS|S3|S3_EMC|NCMPI] = %s\n"
      "\t-w <DIR>: The working directory for the benchmarks = \"%s\"\n"
      "\t-r <DIR>: The result directory for the individual results = \"%s\"\n"
      "Optional flags\n"
      "\t-C parallel delete of files in the working directory\n"
      "\t-e <IOR easy options>: any acceptable IOR easy option = \"%s\"\n"
      "\t-E <IOR hard options>: any acceptable IOR easy option = \"%s\"\n"
      "\t-s <seconds>: Stonewall timer for create = %d\n"
      "\t-S: Activate stonewall timer for read, too (default off), use twice to also activate stonewall for delete and prevent cleanup\n"
      "\t-I <N>: Max segments for iorhard = %d\n"
      "\t-f <N>: Max number of files for mdeasy = %d\n"
      "\t-F <N>: Max number of files for mdhard = %d\n"
      "\t-h: prints the help\n"
      "\t--help: prints the help without initializing MPI\n"
      "\t-l: Log all processes into individual result files, otherwise only rank 0\n"
      "\t-v: increase the verbosity, use multiple times to increase level = %d\n",
      res->backend_name,
      res->workdir,
      res->results_dir,
      res->ior_easy_options,
      res->ior_hard_options,
      res->stonewall_timer,
      res->iorhard_max_segments,
      res->mdeasy_max_files,
      res->mdhard_max_files,
      res->verbosity
    );
}

static io500_options_t * io500_parse_args(int argc, char ** argv, int force_print_help){
  io500_options_t * res = malloc(sizeof(io500_options_t));
  memset(res, 0, sizeof(io500_options_t));
  int print_help = force_print_help;

  res->backend_name = "POSIX";
  res->workdir = "./io500-run/";
  res->results_dir = "./io500-results/";
  res->verbosity = 0;

  res->ior_easy_options = strdup("-F -t 1m -b 1t");
  res->ior_hard_options = strdup("");
  res->mdtest_easy_options = strdup("-u -L");
  res->mdeasy_max_files = 100000000;
  res->mdhard_max_files = 100000000;
  res->stonewall_timer = 300;
  res->iorhard_max_segments = 100000000;

  int c;
  while (1) {
    c = getopt(argc, argv, "a:e:E:hvw:f:F:s:SI:Clr:");
    if (c == -1) {
        break;
    }

    switch (c) {
    case 'a':
        res->backend_name = strdup(optarg); break;
    case 'C':
        res->only_cleanup = TRUE; break;
    case 'e':
        res->ior_easy_options = strdup(optarg); break;
    case 'E':
        res->ior_hard_options = strdup(optarg); break;
    case 'f':
      res->mdeasy_max_files = atol(optarg); break;
    case 'F':
      res->mdhard_max_files = atol(optarg); break;
    case 'h':
      print_help = 1; break;
    case 'I':
      res->iorhard_max_segments = atol(optarg); break;
    case 'l':
      res->log_all_procs = TRUE; break;
    case 'm':
        res->mdtest_easy_options = strdup(optarg); break;
    case 'r':
        res->results_dir = strdup(optarg); break;
    case 's':
      res->stonewall_timer = atol(optarg);
      break;
    case 'S':
      if(res->stonewall_timer_reads){
        res->stonewall_timer_delete = TRUE;
      }
      res->stonewall_timer_reads = TRUE; break;
    case 'v':
      res->verbosity++; break;
    case 'w':
      res->workdir = strdup(optarg); break;
    }
  }
  if(print_help){
    io500_print_help(res);
    int init;
    MPI_Initialized( & init);
    if(init){
      MPI_Finalize();
    }
    exit(0);
  }
  io500_replace_str(res->ior_easy_options);
  io500_replace_str(res->ior_hard_options);
  io500_replace_str(res->mdtest_easy_options);
  return res;
}

void io500_error(char * const str){
  if(rank == 0){
    printf("IO500 error: %s at %s\n", str, CurrentTimeString());
  }
  MPI_Abort(MPI_COMM_WORLD, 1);
}

static FILE * io500_prepare_out(char * suffix, int testID, io500_options_t * options){
  if(rank == 0 || options->log_all_procs){
    char out[10000];
    if(options->log_all_procs){
      sprintf(out, "%s/%s-%d-%d.log", options->results_dir, suffix, rank, testID);
    }else{
      sprintf(out, "%s/%s-%d.log", options->results_dir, suffix, testID);
    }
    // open an output file
    FILE * ret = fopen(out, "w");
    if (ret == NULL){
      io500_error("Could not open output file, aborting!");
    }
    return ret;
  }else{
    // messages from other processes are usually critical or verbose, let them through...
    FILE * null = fopen("/dev/null", "w");
    return null;
  }
}

static IOR_test_t * io500_run_ior_really(char * args, char * suffix, int testID, io500_options_t * options){
  int argc_count;
  char ** args_array;
  FILE * out;

  if(rank == 0){
    printf("Running %s: %s", suffix, CurrentTimeString());
  }

  args_array = io500_str_to_arr(args, & argc_count);
  out = io500_prepare_out(suffix, testID, options);
  IOR_test_t * res = ior_run(argc_count, args_array, MPI_COMM_WORLD, out);
  fclose(out);
  free(args_array);
  return res;
}

static IOR_test_t * io500_io_hard_create(io500_options_t * options){
  //generic array holding the arguments to the subtests
  char args[10000];
  int pos;
  pos = sprintf(args, IOR_HARD_OPTIONS" -w");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -D %d -O stoneWallingWearOut=1", options->stonewall_timer);
  pos += sprintf(& args[pos], " -s %d", options->iorhard_max_segments);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_hard/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_hard_options);

  return io500_run_ior_really(args, "ior_hard_create", 1, options);
}


static IOR_test_t * io500_io_hard_read(io500_options_t * options, IOR_test_t * create_read){
  //generic array holding the arguments to the subtests
  char args[10000];
  int pos;
  pos = sprintf(args, IOR_HARD_OPTIONS" -R");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -O stoneWallingWearOutIterations=%zu", create_read->results->pairs_accessed);
  if (options->stonewall_timer_reads){
    pos += sprintf(& args[pos], " -D %d -O stoneWallingWearOut=1", options->stonewall_timer);
  }
  pos += sprintf(& args[pos], " -s %d", options->iorhard_max_segments);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_hard/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_hard_options);

  return io500_run_ior_really(args, "ior_hard_read", 1, options);
}


static IOR_test_t * io500_io_easy_create(io500_options_t * options){
  //generic array holding the arguments to the subtests
  char args[10000];
  int pos;
  pos = sprintf(args, IOR_EASY_OPTIONS" -w");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -D %d -O stoneWallingWearOut=1", options->stonewall_timer);

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_easy/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_easy_options);

  return io500_run_ior_really(args, "ior_easy_create", 1, options);
}

static IOR_test_t * io500_io_easy_read(io500_options_t * options, IOR_test_t * create_read){
  //generic array holding the arguments to the subtests
  char args[10000];
  int pos;
  pos = sprintf(args, IOR_EASY_OPTIONS" -r");
  pos += sprintf(& args[pos], " -a %s", options->backend_name);
  for(int i=0; i < options->verbosity; i++){
    pos += sprintf(& args[pos], " -v");
  }
  pos += sprintf(& args[pos], " -O stoneWallingWearOutIterations=%zu", create_read->results->pairs_accessed);
  if (options->stonewall_timer_reads){
    pos += sprintf(& args[pos], " -D %d -O stoneWallingWearOut=1", options->stonewall_timer);
  }

  io500_replace_str(args); // make sure workdirs with space works
  pos += sprintf(& args[pos], "\n-o\n%s/ior_easy/file", options->workdir);
  pos += sprintf(& args[pos], "\n%s", options->ior_easy_options);

  return io500_run_ior_really(args, "ior_easy_create", 1, options);
}

static table_t * io500_run_mdtest_really(char * args, char * suffix, int testID, io500_options_t * options){
  int argc_count;
  char ** args_array;
  table_t * table;
  FILE * out;

  if(rank == 0){
    printf("Running %s: %s", suffix, CurrentTimeString());
  }

  args_array = io500_str_to_arr(args, & argc_count);
  out = io500_prepare_out(suffix, testID, options);
  table = mdtest_run(argc_count, args_array, MPI_COMM_WORLD, out);
  fclose(out);
  free(args_array);
  return table;
}

static table_t * io500_run_mdtest_easy(char mode, int maxfiles, int use_stonewall, const char * extra, char * suffix, int testID, io500_options_t * options){
  char args[10000];
  memset(args, 0, 10000);
  if(maxfiles == 0){
    io500_error("Error, mdtest does not support 0 files.");
  }

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

  return io500_run_mdtest_really(args, suffix, testID, options);
}

static table_t * io500_md_easy_create(io500_options_t * options){
  table_t * res = io500_run_mdtest_easy('C', options->mdeasy_max_files, 1, "", "mdtest_easy_create", 1, options);
  if(res->items == 0){
    io500_error("Stonewalling returned 0 created files, that is wrong.");
  }
  return res;
}

static table_t * io500_md_easy_read(io500_options_t * options, table_t * create_read){
  return io500_run_mdtest_easy('E', create_read->items, options->stonewall_timer_reads, "", "mdtest_easy_read", 1, options);
}

static table_t * io500_md_easy_stat(io500_options_t * options, table_t * create_read){
  return io500_run_mdtest_easy('T', create_read->items, options->stonewall_timer_reads, "", "mdtest_easy_stat", 1, options);
}


static table_t * io500_md_easy_delete(io500_options_t * options, table_t * create_read){
  return io500_run_mdtest_easy('r', create_read->items, options->stonewall_timer_delete, "", "mdtest_easy_delete", 1, options);
}


static table_t * io500_run_mdtest_hard(char mode, int maxfiles, int use_stonewall, const char * extra,  char * suffix, int testID, io500_options_t * options){
  char args[10000];
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

  return io500_run_mdtest_really(args, suffix, testID, options);
}

static table_t * io500_md_hard_create(io500_options_t * options){
  table_t * res = io500_run_mdtest_hard('C', options->mdhard_max_files, 1, "", "mdtest_hard_create", 1, options);
  if(res->items == 0){
    io500_error("Stonewalling returned 0 created files, that is wrong.");
  }
  return res;
}

static table_t * io500_md_hard_read(io500_options_t * options, table_t * create_read){
  return io500_run_mdtest_hard('E', create_read->items, options->stonewall_timer_reads, "","mdtest_hard_read", 1, options);
}

static table_t * io500_md_hard_stat(io500_options_t * options, table_t * create_read){
  return io500_run_mdtest_hard('T', create_read->items, options->stonewall_timer_reads, "","mdtest_hard_stat", 1, options);
}

static table_t * io500_md_hard_delete(io500_options_t * options, table_t * create_read){
  return io500_run_mdtest_hard('r', create_read->items, options->stonewall_timer_delete, "", "mdtest_hard_delete", 1, options);
}

static void io500_touch(char * const filename){
  if(rank != 0){
    return;
  }
  int fd = open(filename, O_CREAT | O_WRONLY, S_IWUSR | S_IRUSR);
  if(fd < 0){
    printf("%s ", strerror(errno));
    io500_error("Could not write file, verify permissions");
  }
  close(fd);
}

static void io500_cleanup(io500_options_t* options){
  if(rank == 0){
    printf("\nCleaning working directory: %s", CurrentTimeString());
  }
  io500_parallel_find_or_delete(stdout, options->workdir, NULL, 1, 0);
  if(rank == 0){
    printf("\nDone: %s", CurrentTimeString());
  }
}

static void io500_recursively_create(const char * dir, int touch){
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
      io500_recursively_create(tmp, 0);
      *p = '/';
    }
  }
  mkdir(tmp, S_IRWXU);

  if(touch){
    char tmp2[10000];
    snprintf(tmp2, sizeof(tmp2), "%s/%s", dir, "IO500-testfile");
    io500_touch(tmp2);
  }
}

static int io500_contains_workdir_tag(io500_options_t * options){
    char fname[4096];
    sprintf(fname, "%s/IO500-testfile", options->workdir);
    int fd = open(fname, O_RDONLY);
    int ret = (fd != -1);
    close(fd);
    return ret;
}

static void io500_create_workdir(io500_options_t * options){
  // todo, ensure that the working directory contains no legacy stuff
  char dir[10000];

  sprintf(dir, "%s/", options->results_dir);
  io500_recursively_create(dir, 0);

  sprintf(dir, "%s/ior_hard/", options->workdir);
  io500_recursively_create(dir, 1);
  sprintf(dir, "%s/ior_easy/", options->workdir);
  io500_recursively_create(dir, 1);
  sprintf(dir, "%s/mdtest_easy/", options->workdir);
  io500_recursively_create(dir, 1);
  sprintf(dir, "%s/mdtest_hard/", options->workdir);
  io500_recursively_create(dir, 1);

  sprintf(dir, "%s/IO500-testfile", options->workdir);
  io500_touch(dir);
}

static void io500_print_bw(const char * prefix, int id, IOR_test_t * stat, int read){
  double timer = read ? stat->results->readTime[0] : stat->results->writeTime[0];
  printf("IOR %d %s time: %fs size: %lld bytes bw: %.3f GiB/s\n",
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
  // output help with --help to enable running without mpiexec
  for(int i=0; i < argc; i++){
    if (strcmp(argv[i], "--help") == 0){
      argv[i][0] = 0;
      rank = 0;
      io500_parse_args(argc, argv, 1);
      exit(0);
    }
  }

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  if(rank == 0){
    printf("IO500 starting: %s\n", CurrentTimeString());
    printf("nproc=%d\n", size);
    printf("\n");
  }
  io500_options_t * options = io500_parse_args(argc, argv, 0);

  if(options->only_cleanup){
    // make sure there exists the file IO500_TIMESTAMP
    if(! io500_contains_workdir_tag(options)){
      io500_error("I will not delete the directory in parallel as the file "
        "IO500-testfile does not exist,\n"
        "maybe it's the wrong directory!\n"
        "If you are sure create the file\n");
    }

    io500_cleanup(options);
    MPI_Finalize();
    exit(0);
  }

  if(io500_contains_workdir_tag(options)){
      if(rank == 0){
        printf("Error, the working directory contains IO500-testfile already, so I will clean that directory for you before I start!");
      }
      io500_cleanup(options);
  }

  if(rank == 0){
    io500_create_workdir(options);
  }
  MPI_Barrier(MPI_COMM_WORLD);

  IOR_test_t * io_easy_create = io500_io_easy_create(options);
  table_t *    md_easy_create = io500_md_easy_create(options);

  {
    char fname[4096];
    sprintf(fname, "%s/IO500_TIMESTAMP", options->workdir);
    io500_touch(fname);
  }
  MPI_Barrier(MPI_COMM_WORLD);

  IOR_test_t * io_hard_create = io500_io_hard_create(options);
  table_t *    md_hard_create = io500_md_hard_create(options);

  // mdreal...
  FILE * out = io500_prepare_out("find", 1, options);
  io500_find_results_t* find = io500_find(out, options);
  fclose(out);

  IOR_test_t * io_easy_read = io500_io_easy_read(options, io_easy_create);
  //table_t *    md_easy_read = io500_md_easy_read(options, md_easy_create);
  table_t *    md_hard_stat = io500_md_hard_stat(options, md_hard_create);

  IOR_test_t * io_hard_read = io500_io_hard_read(options, io_hard_create);
  table_t *    md_hard_read = io500_md_hard_read(options, md_hard_create);
  table_t *    md_easy_stat = io500_md_easy_stat(options, md_easy_create);

  table_t *    md_hard_delete = io500_md_hard_delete(options, md_hard_create);
  table_t *    md_easy_delete = io500_md_easy_delete(options, md_easy_create);

  if(rank == 0){
    printf("\nIO500 complete: %s\n", CurrentTimeString());

    printf("\n");
    printf("=== IO-500 submission ===\n");

    io500_print_bw("ior_easy_write", 1, io_easy_create, 0);
    io500_print_bw("ior_easy_read", 2, io_easy_read, 1);
    io500_print_bw("ior_hard_write", 3, io_hard_create, 0);
    io500_print_bw("ior_hard_read", 4, io_hard_read, 1);

    io500_print_md("mdtest_easy_create", 1, 4, md_easy_create);
    //io500_print_md("mdtest_easy_read",   2, 6, md_easy_read);
    io500_print_md("mdtest_easy_stat",   3, 5, md_easy_stat);
    io500_print_md("mdtest_easy_delete", 4, 7, md_easy_delete);

    io500_print_md("mdtest_hard_create", 5, 4, md_hard_create);
    io500_print_md("mdtest_hard_read",   6, 6, md_hard_read);
    io500_print_md("mdtest_hard_stat",   7, 5, md_hard_stat);
    io500_print_md("mdtest_hard_delete", 8, 7, md_hard_delete);

    printf("find err: %ld found: %ld (scanned %ld files) time: %fs rate: %.3f kiops/s\n", find->errors, find->found_files, find->total_files, find->runtime, find->rate / 1000);
  }
  if(! options->stonewall_timer_delete){
    io500_cleanup(options);
  }
  MPI_Finalize();
  return 0;
}
