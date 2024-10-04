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
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"

int main(int argc, char *argv[])
{
    int rank_id;
    int rank_size;
    int msg_recv;
    char *msg_send_str;
    char *msg_recv_str;
    ssize_t msg_send_sz;
    ssize_t msg_recv_sz;
    const int tag = 201;
    int ii;

    /* init */
    MPI_Init(&argc, &argv);
    /* get job id */
    MPI_Comm_rank(MPI_COMM_WORLD, &rank_id);
    /* get total amount of jobs */
    MPI_Comm_size(MPI_COMM_WORLD, &rank_size);
    /* check message size */
    msg_send_sz = snprintf(NULL, 0, "ping_%d", rank_id);
    /* allocate space for send and received message */
    msg_send_str = malloc(msg_send_sz + 1);
    msg_recv_sz = msg_send_sz;
    msg_recv_str = malloc(msg_recv_sz + 1);
    msg_send_sz = snprintf(msg_send_str, msg_send_sz + 1, "ping_%d", rank_id);
    /* start sending and receiving messages to all other nodes */
    for (ii = 0; ii < rank_size; ii++) {
		if (ii != rank_id) {
			MPI_Send(msg_send_str, msg_send_sz, MPI_CHAR, ii, tag, MPI_COMM_WORLD);
			MPI_Recv(msg_recv_str, msg_recv_sz, MPI_CHAR, ii, tag, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
			printf("rank %d received value %s from mpi node %d\n", rank_id, msg_recv_str, ii);
		}
	}
	/* clean up */
	free(msg_send_str);
	free(msg_recv_str);
    MPI_Finalize();
    return 0;
}
