#if __AIEARCH__ == 20
  #include "aiev2_locks.h"
#else 
  #if __AIEARCH__ == 21
    #include "aie2p_locks.h"
  #endif
#endif

#define ACQ_LOCK 48
#define REL_LOCK 49

extern float _anonymous0[1];

int main() {
  acquire_greater_equal(ACQ_LOCK, 1);
  _anonymous0[0] = 5 * 3.14159;
  release(REL_LOCK, 1);
  return 0;
}
