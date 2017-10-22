#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main (argc, argv)
     int argc;
     char *argv[];
{
  int rank, size;
  char cmd[10000],cmd2[1000],output[10000];
  MPI_Init (&argc, &argv);      /* starts MPI */
  MPI_Comm_rank (MPI_COMM_WORLD, &rank);        /* get current process id */
  MPI_Comm_size (MPI_COMM_WORLD, &size);        /* get number of processes */


    /* this program doesn't work anymore I'm afraid.
       It was written for an early version where only mdtest_easy directories
       were searched.  Now it is required to search all of them.
       So it needs to be revised.  Probably the way it needs to be done is
       for rank 0 to do some readdirs and ship out responsibility.
       Check the default ./io500_find.sh script to see the required input/output
    */
       
 rank=rank+1;
 sprintf(cmd2,"%s%s%d%s",argv[3],"mdtest_tree.",rank,".0");
 sprintf(output,"%s%s%d",argv[3],"../",rank);
 sprintf(cmd,"%s %s %s %s",argv[1],argv[2],cmd2,output);
 
  system(cmd);

  MPI_Finalize();
  return 0;
}
