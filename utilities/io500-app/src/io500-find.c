#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>
#include <dirent.h>
#include <limits.h>
#include <sys/stat.h>

#include <aiori.h>
#include <libcircle.h>

// this version is based on mpistat
#include <utilities.h>

#include "io500.h"

// parallel recursive find

static struct timespec compare_time;
static off_t expected_size;
static char * compare_str = "01";

static int glob_delete;
static int glob_stonewall_timer;
static double glob_endtime;

static io500_find_results_t * res;

io500_find_results_t* io500_find(io500_options_t * opt){
  if(rank == 0){
    printf("Running find: %s\n", CurrentTimeString());
  }

  expected_size = 3900; // TODO make that adjustable

  {
    char fname[4096];
    sprintf(fname, "%s/TIMESTAMP", opt->workdir);
    struct stat buf;
    if(lstat(fname, & buf) != 0) {
      io500_error("Could not read timestamp file!");
    }
    compare_time = buf.st_ctim;
  }


  res = malloc(sizeof(io500_find_results_t));
  memset(res, 0, sizeof(*res));

  //ior_aiori_t * backend = aiori_select(opt->backend_name);
  double start = GetTimeStamp();
  io500_parallel_find_or_delete(opt->workdir, 0, opt->stonewall_timer_reads ? opt->stonewall_timer : 0 );
  double end = GetTimeStamp();
  res->runtime = end - start;
  res->rate = res->found_files / res->runtime;

  return res;
}

// globals
static char start_dir[8192]; // absolute path of start directory
static char item_buf[8192]; // buffer to construct type / path combos for queue items

static char  find_file_type(unsigned char c) {
    switch (c) {
        case DT_BLK :
            return 'b';
        case DT_CHR :
            return 'c';
        case DT_DIR :
            return 'd';
        case DT_FIFO :
            return 'F';
        case DT_LNK :
            return 'l';
        case DT_REG :
            return 'f';
        case DT_SOCK :
            return 's';
        default :
            return 'u';
    }
}

static void find_do_lstat(char *path) {
  printf("LSTAT \"%s\"\n", path);
  static struct stat buf;
  if (lstat(path+1,&buf) == 0) {
    res->found_files++;
      //fprintf(out,"%s\t%c\t%d\t%d\t%d\t%d\t%d\t%d\n", path+1, *path,
      //        buf.st_size, buf.st_uid, buf.st_gid, buf.st_atime,
      //        buf.st_mtime, buf.st_ctime);
  } else {
    res->errors++;
      //fprintf (stderr, "Cannot lstat '%s': %s\n", path+1, strerror (errno));
  }
}

static void find_do_readdir(char *path, CIRCLE_handle *handle) {
    int path_len=strlen(path+1);
    DIR *d = opendir (path+1);
    if (!d) {
        fprintf (stderr, "Cannot open '%s': %s\n", path+1, strerror (errno));
        return;
    }
    while (1) {
        struct dirent *entry;
        entry = readdir(d);
        if (glob_stonewall_timer && GetTimeStamp() >= glob_endtime ){
          break;
        }
        if (entry==0) {
            break;
        }
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") ==0) {
            continue;
        }
        char *tmp=(char*) malloc(path_len+strlen(entry->d_name)+3);
        *tmp= find_file_type(entry->d_type);
        strcpy(tmp+1,path+1);
        *(tmp+path_len+1)='/';
        strcpy(tmp+path_len+2,entry->d_name);
        handle->enqueue(tmp);
    }
    closedir(d);
}

// create work callback
// this is called once at the start on rank 0
// use to seed rank 0 with the initial dir to start
// searching from
static void find_create_work(CIRCLE_handle *handle) {
    handle->enqueue(item_buf);
}

// process work callback
static void find_process_work(CIRCLE_handle *handle)
{
    // dequeue the next item
    handle->dequeue(item_buf);
    if(! glob_delete){
      find_do_lstat(item_buf);
    }else{
      unlink(& item_buf[1]); // strip type
    }
    if (*item_buf == 'd') {
        find_do_readdir(item_buf, handle);
    }
}

// arguments :
// first argument is data directory to store the lstat files
// second argument is directory to start lstating from
int io500_parallel_find_or_delete(char * workdir, int delete, int stonewall_timer_s) {
  char * err = realpath(workdir, start_dir);

  glob_delete = delete;
  glob_stonewall_timer = stonewall_timer_s;
  glob_endtime = GetTimeStamp() + glob_stonewall_timer;

  DIR * sd=opendir(start_dir);
  if (err == NULL || ! sd) {
      fprintf (stderr, "Cannot open directory '%s': %s\n", start_dir, strerror (errno));
      exit (EXIT_FAILURE);
  }
  sprintf(item_buf, "%c%s", 'd', start_dir);

	// initialise MPI and the libcircle stuff
  int argc = 1;
  char *argv[] = {"test"};

	CIRCLE_init(argc, argv, CIRCLE_SPLIT_RANDOM);
	// set the create work callback
  CIRCLE_cb_create(& find_create_work);

	// set the process work callback
	CIRCLE_cb_process(& find_process_work);

	// enter the processing loop
	CIRCLE_begin();

	// wait for all processing to finish and then clean up
	CIRCLE_finalize();

	return 0;
}
