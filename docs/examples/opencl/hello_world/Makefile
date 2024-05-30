CC      = hipcc
CFLAGS  = -g -lOpenCL
RM      = rm -f

default: all

all: hello_world

hello_world: hello_world.cpp
	$(CC) $(CFLAGS) -o hello_world hello_world.cpp

clean veryclean:
	$(RM) hello_world
