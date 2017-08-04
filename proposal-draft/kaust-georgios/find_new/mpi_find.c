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


 rank=rank+1;
 sprintf(cmd2,"%s%s%d%s",argv[3],"mdtest_tree.",rank,".0");
 sprintf(output,"%s%s%d",argv[3],"../",rank);
 sprintf(cmd,"%s %s %s %s",argv[1],argv[2],cmd2,output);
 
  system(cmd);

  MPI_Finalize();
  return 0;
}
