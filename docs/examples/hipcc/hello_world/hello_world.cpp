/*
Copyright (c) 2015-2016 Advanced Micro Devices, Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include <hip/hip_runtime.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <fstream>

#define SUCCESS 0
#define FAILURE 1

using namespace std;

// store the input-char + 1 value to index ii specified by hipThreadId_x, hipBlockDim_x and hipBlockIdx
// Once, finished, value in output shoud be "HelloWorld"
__global__ void gpu_memcpy_callback_helloworld(char* in, char* out)
{
	int ii = hipThreadIdx_x + hipBlockDim_x * hipBlockIdx_x;
	out[ii] = in[ii] + 1;
}

int main(int argc, char* argv[])
{
	int ret;
	hipDeviceProp_t devProp;
	hipError_t  res;
	
	ret = FAILURE;
	res = hipGetDeviceProperties(&devProp, 0);
	if (res == hipSuccess) {
		/* Initial input and output for the host and create memory objects for the kernel*/
		const char* input = "GdkknVnqkc";
		size_t strlength = strlen(input);
		char *output = (char *)malloc(strlength + 1);
		char* inputBuffer;
		char* outputBuffer;

		cout << " System minor: " << devProp.minor << endl;
		cout << " System major: " << devProp.major << endl;
		cout << " Agent name: " << devProp.name << endl;
		cout << "Kernel input: " << input << endl;
		cout << "Expecting that kernel increases each character from input string by one" << endl;
		res = hipMalloc((void**)&inputBuffer, (strlength + 1) * sizeof(char));
		if (res == hipSuccess) {
			res = hipMalloc((void**)&outputBuffer, (strlength + 1) * sizeof(char));
			if (res == hipSuccess) {
				res = hipMemcpy(inputBuffer, input, (strlength + 1) * sizeof(char), hipMemcpyHostToDevice);
				if (res == hipSuccess) {
					hipLaunchKernelGGL(gpu_memcpy_callback_helloworld,
								  dim3(1),
								  dim3(strlength),
								  0,
								  0,
								  inputBuffer,
								  outputBuffer);
					res = hipMemcpy(output,	outputBuffer, (strlength + 1) * sizeof(char), hipMemcpyDeviceToHost);
					if (res == hipSuccess) {
						output[strlength] = '\0';	//Add the terminal character to the end of output.
						cout << "Kernel output string: " << output << endl;
						if (strcmp(output, "HelloWorld") == 0) {
							cout << "Output string matched with HelloWorld" << endl;
							ret = SUCCESS;
						}
						else {
							cout << "Error, output string did not match with HelloWorld" << endl;
						}
					}
					else {
						cout << "Error, Kernel response copy failed" << endl;
					}
					res = hipFree(outputBuffer);
					if (res != hipSuccess) {
						cout << "warning, hipFree(outputBuffer) failed" << endl; 
					}
				}
				else {
				    cout << "Error, input string copy to kernel failed" << endl;
				}
			}
			res = hipFree(inputBuffer);
			if (res != hipSuccess) {
				cout << "warning, hipFree(inputbuffer) failed" << endl; 
			}
		}
		free(output);
	}
	if (ret == SUCCESS) {
		std::cout << "Test ok!" << endl;
	}
	else {
		std::cout << "Test failed!" << endl;
	}
	return ret;
}
