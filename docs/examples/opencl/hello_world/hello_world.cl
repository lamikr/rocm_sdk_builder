#pragma OPENCL EXTENSION cl_khr_byte_addressable_store : enable
__constant char hw[] = "Hello World\n";
__kernel void hello_world_kernel(__global float *res_float_arr)
{
    size_t tid = get_global_id(0);
    res_float_arr[tid] = 2 * tid;
}
