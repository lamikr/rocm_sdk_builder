/* 
 * This is free and unencumbered software released into the public domain.
 *
 * Anyone is free to copy, modify, publish, use, compile, sell, or
 * distribute this software, either in source code form or as a compiled
 * binary, for any purpose, commercial or non-commercial, and by any
 * means.
 *
 * In jurisdictions that recognize copyright laws, the author or authors
 * of this software dedicate any and all copyright interest in the
 * software to the public domain. We make this dedication for the benefit
 * of the public at large and to the detriment of our heirs and
 * successors. We intend this dedication to be an overt act of
 * relinquishment in perpetuity of all present and future rights to this
 * software under copyright law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * For more information, please refer to <http://unlicense.org>
 *
 * Author: Mika Laitio <lamikr@gmail.com>
 * Inspriration from https://gist.github.com/aandergr/ca25ace6c11dbae8237feca7758d1da8#file-queryocl-c
 * 
 * */
 
#include <iostream>
#include <fstream>
#include <sstream>

#include <CL/cl.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define CL_KERNEL_SOURCE_FNAME 		"hello_world.cl"
#define KERNEL_RESULT_ARRAY_SIZE	200

cl_platform_id *alloc_and_get_cl_platform_arr(cl_uint *cnt_cl_platform_arr) {
	cl_int			res;
	cl_platform_id	*ret;
	
	ret = NULL;
	res = clGetPlatformIDs(0, NULL, cnt_cl_platform_arr);
	if ((res == CL_SUCCESS) && (*cnt_cl_platform_arr > 0)) {
		printf("number of opencl platform devices: %u\n", *cnt_cl_platform_arr);
		ret = (cl_platform_id *)malloc(*cnt_cl_platform_arr * sizeof(cl_platform_id));
		clGetPlatformIDs(*cnt_cl_platform_arr, ret, NULL);
	}
	else {
		printf("Failed to find opencl platforms.\n");
		printf("Verify that opencl drivers are congired properly at\n");
		printf("    /etc/OpenCL/vendors/\n");
		printf("or on location defined by environment variable:\n");
		printf("    OCL_ICD_VENDORS\n");
	}
	return ret;
}

cl_device_id *alloc_and_get_cl_platform_device_ids(cl_platform_id *platform_id,
													cl_uint *cnt_cl_platform_device_ids) {
	cl_int			res;
	cl_device_id	*ret;
	
	ret = NULL;
	res = clGetDeviceIDs(*platform_id, CL_DEVICE_TYPE_ALL, 0, NULL, cnt_cl_platform_device_ids);
	if ((res == CL_SUCCESS) && (*cnt_cl_platform_device_ids > 0)) {
		printf("Number of devices found for platform: %u\n", *cnt_cl_platform_device_ids);
		ret = (cl_device_id *)malloc(*cnt_cl_platform_device_ids * sizeof(cl_device_id));
		clGetDeviceIDs(*platform_id, CL_DEVICE_TYPE_ALL, *cnt_cl_platform_device_ids, ret, NULL);
	}
	else {
		printf("Failed to find opencl devices for platform.\n");
	}
	return ret;
}

bool create_gpu_device(cl_device_id *result_id) {
	cl_platform_id	*cl_platform_arr;
	cl_uint			cnt_platform_arr;
	cl_device_id	*cl_device_arr;
	cl_uint			cnt_device_arr;
	cl_device_type	device_type;
	bool			ret;
	cl_uint			ii;
	cl_uint			jj;	
	
	// this could be done simpler simply by giving parameter to search only gpu devices
	// want to however test code this way
	ret	= false;
	cl_platform_arr = alloc_and_get_cl_platform_arr(&cnt_platform_arr);
	if (cl_platform_arr != NULL) {
		for (ii = 0; ii < cnt_platform_arr; ii++) {
			printf("Platform id: %i\n", ii);
			cl_device_arr = alloc_and_get_cl_platform_device_ids(&cl_platform_arr[ii], &cnt_device_arr);
			if (cl_device_arr != NULL) {
				for (jj = 0; jj < cnt_device_arr; jj++) {
					clGetDeviceInfo(cl_device_arr[jj], CL_DEVICE_TYPE, sizeof(cl_device_type), &device_type, NULL);
					if ((device_type & CL_DEVICE_TYPE_GPU) || (device_type & CL_DEVICE_TYPE_ACCELERATOR)) {
						ret	= true;
						*result_id = cl_device_arr[jj];
						break;
					}
				}
				free(cl_device_arr);
				if (ret == true) {
					break;
				}
			}
		}
		free(cl_platform_arr);
	}
	return ret;
}

cl_program load_and_compile_cl_program(cl_context context,
									cl_device_id device,
									const char* cl_src_fname) {
	cl_program	ret;
	cl_program	prg;
	cl_int		res;
	
	ret	= NULL;
	//std::ifstream cl_file(cl_src_fname);
	std::ifstream cl_file(cl_src_fname, std::ios::in);
	if (cl_file.is_open()) {
		std::ostringstream oss;
		
		oss << cl_file.rdbuf();
		std::string src_str_std = oss.str();
		const char *src_str = src_str_std.c_str();
		prg = clCreateProgramWithSource(context,
										1,
                                        (const char**)&src_str,
                                        NULL,
                                        NULL);
		if (prg != NULL) {
			res = clBuildProgram(prg, 0, NULL, NULL, NULL, NULL);
			if (res == CL_SUCCESS) {
				ret = prg;
			}
			else {
				printf("Failed to build opencl program from source file: %s\n", cl_src_fname);
			}
		}
		else {
			printf("Failed to create opencl program from source file: %s\n", cl_src_fname);
		}
	}
	else {
		printf("Failed to open opencl program from source file: %s\n", cl_src_fname);
	}
	return ret;
}

int main(void) {
	cl_device_id		cl_device;
	cl_context			cl_cntx;
	bool				res_b;
	cl_int				res_i;
	cl_program			cl_prg;
	cl_kernel			cl_krnl;
	cl_mem				res_mem_obj;
	cl_command_queue	cl_cmd_queue;
	float 				krnl_result_arr[KERNEL_RESULT_ARRAY_SIZE];
	
	res_b = create_gpu_device(&cl_device);
	if (res_b == true) {
		cl_cntx	= clCreateContext(NULL,
								1,
								&cl_device,
								NULL,
								NULL,
								&res_i);
		if (cl_cntx != NULL) {
			printf("context created\n");
			// Create OpenCL program from HelloWorld.cl kernel source
			cl_prg = load_and_compile_cl_program(cl_cntx, cl_device, CL_KERNEL_SOURCE_FNAME);			
			if (cl_prg != NULL) {
				printf("program loaded\n");
				cl_krnl = clCreateKernel(cl_prg, "hello_world_kernel", &res_i);
				if (res_i == CL_SUCCESS) {
					printf("kernel created\n");
					
					res_mem_obj = clCreateBuffer(cl_cntx,
												CL_MEM_READ_WRITE,
												sizeof(float) * KERNEL_RESULT_ARRAY_SIZE,
												NULL,
												NULL);
					if (res_mem_obj != NULL) {
						res_i = clSetKernelArg(cl_krnl,
											0,
											sizeof(cl_mem),
											&res_mem_obj);
						if (res_i == CL_SUCCESS) {
							printf("Parameters set\n");
							cl_cmd_queue = clCreateCommandQueueWithProperties(cl_cntx,
																			cl_device,
																			0,
																			&res_i);
							if (cl_cmd_queue != NULL) {
								printf("Command queue created for kernel invocation requests\n");
								size_t work_sz_local[]	= {1};
								size_t work_sz_global[]	= {KERNEL_RESULT_ARRAY_SIZE};
								// extecute kernel on work groups
								res_i = clEnqueueNDRangeKernel(cl_cmd_queue,
													cl_krnl,
													1,
													NULL,
													work_sz_global,
													work_sz_local,
													0,
													NULL,
													NULL);
								if (res_i == CL_SUCCESS) {
									printf("Kernels set to kernel command queue\n");
									res_i = clEnqueueReadBuffer(cl_cmd_queue,
														res_mem_obj,
														CL_TRUE,
														0,
														KERNEL_RESULT_ARRAY_SIZE * sizeof(float),
														krnl_result_arr,
														0,
														NULL,
														NULL);
									if (res_i == CL_SUCCESS) {
										res_b = true;
										for (int ii = 0; ii < KERNEL_RESULT_ARRAY_SIZE; ii++) {
											if (2 * ii != (int)krnl_result_arr[ii]) {
												res_b = false;
											}
										}
										if (res_b == true) {
											printf("OpenCL test program success, all %d values read correctly to krnl_result_arr parameter\n", KERNEL_RESULT_ARRAY_SIZE);
										}
										else {
											printf("OpenCL test program failed to read values back correctly %d values from krnl_result_arr parameter\n", KERNEL_RESULT_ARRAY_SIZE);
										}
									}
									else {
										printf("Failed to read results back from kernel command queue\n");
									}
								}
								else {
									printf("Failed to execute kernels on command queue\n");
								}
							}
							else {
								printf("Failed to create command queue\n");
							}
						}
						else {
							printf("Failed to set parameters for opencl kernel: %s\n", CL_KERNEL_SOURCE_FNAME);
						}
					}
				}
				else {
					printf("Failed to create kernel for opencl code: %s\n", CL_KERNEL_SOURCE_FNAME);
				}
			}
			else {
				printf("Failed to load program: %s\n", CL_KERNEL_SOURCE_FNAME);
			}
		}
		else {
			printf("Failed to create opencl context, err: %d\n", res_i);	
		}
	}
	return 0;
}
