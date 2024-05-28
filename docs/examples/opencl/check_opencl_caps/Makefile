CC      = hipcc
CFLAGS  = -g -lOpenCL
RM      = rm -f

default: all

all: check_opencl_caps

find_opencl_devices: check_opencl_caps.c
	$(CC) $(CFLAGS) -o check_opencl_caps check_opencl_caps.c

clean veryclean:
	$(RM) check_opencl_caps
