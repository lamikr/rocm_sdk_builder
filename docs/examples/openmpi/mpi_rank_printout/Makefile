CC=mpicc
# CFLAGS and LDFLAGS for openmpi header and library are actually not
# needed when using mpicc as a compiler. They would be needed if using
# clang or gcc directly instead.\
# With mpicc selection the selection which compiler mpicc uses
# can be made with options like
# OMPI_CC=clang
# OMPI_CXX=clang++
CFLAFS=${ROCM_HOME}/include
LDFLAGS=-L /opt/rocm_sdk_612/lib64 -lmpi
EXECUTABLE=mpi_rank_printout

default: build_and_test

build_and_test: mpi_rank_printout test

mpi_rank_printout: mpi_rank_printout.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(EXECUTABLE) mpi_rank_printout.c

test: $(EXECUTABLE)
	mpiexec -n 4 $(EXECUTABLE)

clean veryclean:
	$(RM) mpi_rank_printout.o $(EXECUTABLE)
