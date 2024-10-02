EXECUTABLE=mpi_msg_ping
MPICC?=mpicc

all: ${EXECUTABLE} test

mpi_msg_ping: mpi_msg_ping.c
        ${MPICC} -o $(EXECUTABLE) mpi_msg_ping.c

test: $(EXECUTABLE)
        mpiexec -n 4 $(EXECUTABLE)

clean:
        rm -f ${EXECUTABLE}
