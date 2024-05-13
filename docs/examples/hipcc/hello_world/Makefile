HIPCC=$(ROCM_PATH)/bin/hipcc

SOURCES = hello_world.cpp
OBJECTS = $(SOURCES:.cpp=.o)
EXECUTABLE=./hello_world
TARGET=all

.PHONY: exec
CXX=$(HIPCC)
CXXFLAGS =-g -fPIE

all: hello_world test

hello_world: $(OBJECTS)
	$(HIPCC) $(OBJECTS) -fPIE -o $@

test: $(EXECUTABLE)
	$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE)
	rm -f $(OBJECTS)
	rm -f $(ROCM_PATH)/src/*.o

