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

#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>

cl_platform_id *alloc_and_get_cl_platform_id_arr(cl_uint *cnt_cl_platform_id_arr) {
	cl_int			res;
	cl_platform_id	*ret;
	
	ret = NULL;
	res = clGetPlatformIDs(0, NULL, cnt_cl_platform_id_arr);
	if ((res == CL_SUCCESS) && (*cnt_cl_platform_id_arr > 0)) {
		printf("number of opencl platform devices: %u\n", *cnt_cl_platform_id_arr);
		ret = malloc(*cnt_cl_platform_id_arr * sizeof(cl_platform_id));
		clGetPlatformIDs(*cnt_cl_platform_id_arr, ret, NULL);
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
		ret = malloc(*cnt_cl_platform_device_ids * sizeof(cl_device_id));
		clGetDeviceIDs(*platform_id, CL_DEVICE_TYPE_ALL, *cnt_cl_platform_device_ids, ret, NULL);
	}
	else {
		printf("Failed to find opencl devices for platform.\n");
	}
	return ret;
}

void print_platform_info(cl_platform_id	*cl_platform_item, cl_platform_info enum_id) {
	cl_ulong size;
	char *ret;
	
	clGetPlatformInfo(*cl_platform_item, enum_id, 0, NULL, &size);
	ret = malloc(size);
	clGetPlatformInfo(*cl_platform_item, enum_id, size, ret, NULL);
	printf("%s\n", ret);
	free(ret);
}

void print_platform_device_info_uint(char *property_name, cl_device_id *cl_device_item, cl_device_info enum_info_id) {
	cl_uint val;
	
	clGetDeviceInfo(*cl_device_item, enum_info_id, sizeof(cl_uint), &val, NULL);
	printf("    %s: 0x%x\n", property_name, val);
}

void print_platform_device_type(cl_device_id *cl_device_item) {
	cl_device_type dt;
	
	clGetDeviceInfo(*cl_device_item, CL_DEVICE_TYPE, sizeof(cl_device_type), &dt, NULL);
	printf("    CL_DEVICE_TYPE: %s%s%s%s\n",
			dt & CL_DEVICE_TYPE_CPU ? " CPU" : "",
			dt & CL_DEVICE_TYPE_GPU ? " GPU" : "",
			dt & CL_DEVICE_TYPE_ACCELERATOR ? " ACCELERATOR" : "",
			dt & CL_DEVICE_TYPE_DEFAULT ? " DEFAULT" : "");
}

int main(void) {
	cl_platform_id	*cl_platform_id_arr;
	cl_uint			cnt_platform_id_arr;
	cl_device_id	*cl_pl_device_arr;
	cl_uint			cnt_pl_device_arr;
	cl_uint			ii;
	cl_uint			jj;
	
	cl_platform_id_arr = alloc_and_get_cl_platform_id_arr(&cnt_platform_id_arr);
	if (cl_platform_id_arr != NULL) {
		for (ii = 0; ii < cnt_platform_id_arr; ii++) {
			printf("==============================\n");
			printf("Platform id: %i\n", ii);
			print_platform_info(&cl_platform_id_arr[ii], CL_PLATFORM_NAME);
			print_platform_info(&cl_platform_id_arr[ii], CL_PLATFORM_VENDOR);
			print_platform_info(&cl_platform_id_arr[ii], CL_PLATFORM_VERSION);
			print_platform_info(&cl_platform_id_arr[ii], CL_PLATFORM_PROFILE);
			print_platform_info(&cl_platform_id_arr[ii], CL_PLATFORM_EXTENSIONS);
			cl_pl_device_arr = alloc_and_get_cl_platform_device_ids(&cl_platform_id_arr[ii], &cnt_pl_device_arr);
			if (cl_pl_device_arr != NULL) {
				for(jj = 0; jj < cnt_pl_device_arr; jj++) {
					printf("    ---------------------------\n");
					printf("    Device id: %i\n", jj);
					print_platform_device_info_uint("CL_DEVICE_VENDOR_ID", &cl_pl_device_arr[jj], CL_DEVICE_VENDOR_ID);
					print_platform_device_type(&cl_pl_device_arr[jj]);
					
					print_platform_device_info_uint("CL_DEVICE_VENDOR_ID", &cl_pl_device_arr[jj], CL_DEVICE_VENDOR_ID);
					print_platform_device_info_uint("CL_DEVICE_MAX_COMPUTE_UNITS", &cl_pl_device_arr[jj], CL_DEVICE_MAX_COMPUTE_UNITS);
					print_platform_device_info_uint("CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS", &cl_pl_device_arr[jj], CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS);
					print_platform_device_info_uint("CL_DEVICE_MAX_WORK_GROUP_SIZE", &cl_pl_device_arr[jj], CL_DEVICE_MAX_WORK_GROUP_SIZE);
					print_platform_device_info_uint("CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR", &cl_pl_device_arr[jj], CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR);
					print_platform_device_info_uint("CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT", &cl_pl_device_arr[jj], CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT);
					// see https://gist.github.com/aandergr/ca25ace6c11dbae8237feca7758d1da8#file-queryocl-c
					printf("    todo more information...\n");
					printf("   ---------------------------\n");
				}
				free(cl_pl_device_arr);
			}
			printf("==============================\n");
		}
		free(cl_platform_id_arr);
	}
	return 0;
}
