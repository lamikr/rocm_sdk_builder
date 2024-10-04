#include <mpi.h>
#include <stdio.h>
#include <sys/utsname.h>

int main(int argc, char **argv)
{
  int myrank;
  struct utsname unam;

  MPI_Init(&argc, &argv);
  uname(&unam);
  MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
  printf("Hello from rank %d on host %s\n", myrank, unam.nodename);
  MPI_Finalize();

  return 0;
}
