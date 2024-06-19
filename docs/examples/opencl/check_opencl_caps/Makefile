CC      = hipcc
CFLAGS  = -g
LDFLAGS = -L${ROCM_HOME}/lib64 -lOpenCL
RM      = rm -f

default: all

all: check_opencl_caps

check_opencl_caps: check_opencl_caps.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o check_opencl_caps check_opencl_caps.c

clean veryclean:
	$(RM) check_opencl_caps
