CC			= hipcc
CFLAGS		= -g
LDFLAGS		= -L${ROCM_HOME}/lib64 -lOpenCL
RM			= rm -f
EXECUTABLE	= ./hello_world

default: all

all: hello_world test

hello_world: hello_world.cpp
	$(CC) $(CFLAGS) $(LDFLAGS) -o hello_world hello_world.cpp
	
test: $(EXECUTABLE)
	$(EXECUTABLE)

clean veryclean:
	$(RM) hello_world
