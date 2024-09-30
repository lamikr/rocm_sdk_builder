EXECS=mpi_msg_ping
MPICC?=mpicc

all: ${EXECS}

mpi_msg_ping: mpi_msg_ping.c
	${MPICC} -o mpi_msg_ping mpi_msg_ping.c

clean:
	rm -f ${EXECS}
