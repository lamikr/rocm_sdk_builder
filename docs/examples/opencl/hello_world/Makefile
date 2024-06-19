CC      = hipcc
CFLAGS  = -g
LDFLAGS = -L${ROCM_HOME}/lib64 -lOpenCL
RM      = rm -f

default: all

all: hello_world

hello_world: hello_world.cpp
	$(CC) $(CFLAGS) $(LDFLAGS) -o hello_world hello_world.cpp

clean veryclean:
	$(RM) hello_world
