from mpi4py import MPI

# this code is from https://medium.com/@thiwankajayasiri/mpi-tutorial-for-machine-learning-part-2-3-ebe72d0a0b04

def main():
    comm = MPI.COMM_WORLD
    rank_id = comm.Get_rank()
    rank_size = comm.Get_size()

    print("rank_id: " + str(rank_id) + ", rank_size: " + str(rank_size))
    if rank_id == 0:
        send_target=rank_id + 1
        recv_target=rank_size - 1
        print(str(rank_id) + " sending message to " + str(send_target))
        msg_ping = "ping_" + str(rank_id)
        comm.send(msg_ping, dest=send_target)
        print(str(rank_id) + " send message: " + msg_ping + " to " + str(send_target))
        msg_ping = comm.recv(source=recv_target)
        print(str(rank_id) + " reveived message: " + msg_ping + " from " + str(recv_target))
    else:
        send_target=rank_id + 1
        if send_target == rank_size:
            send_target = 0
        recv_target=rank_id - 1
        print(str(rank_id) + " waiting message from " + str(recv_target))
        msg_ping = comm.recv(source=recv_target)
        print(str(rank_id) + " reveived message: " + msg_ping + " from " + str(recv_target))
        msg_ping = "ping_" + str(rank_id)
        comm.send(msg_ping, dest=send_target)
        print(str(rank_id) + " send message: " + msg_ping + " to " + str(send_target))
    print(str(rank_id) + " exit")

if __name__ == "__main__":
    main()
