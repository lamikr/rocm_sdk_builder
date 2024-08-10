# fast verify benchmark
- run_and_save_benchmarks.sh will execute benchmarks which
  are fast to run and their results are automatically saved
  to timestamped files on the same directory
- problem sizes are relatively small on these tests
  that so that they can run even on memory constrained devices
  like gfx1035 igpu in a comparable way

- todo: 
  - add rocblas-benchmark which show the importance of having customized
    logic files for gfx1030 devices
  - add llama.cpp benchmark

# more demaning pytorch-gpu-benchmark
- https://github.com/lamikr/pytorch-gpu-benchmark
- please collect the results after execution from the
  new_results folder and create merge request to get them saved to git repository

# about results

## flash attenuation and optimized flash attenuation tests
- results from these are in pytorch_dot_products.txt files
- pytorch 2.3.1 did not have flash attenuation enabled.
  These results show -1 as a results for tests which required
  flash attenuation.
- first version of pytorch 2.4.0 has flash attenuation enabled
  but it is not optimized for any gfx103* or gfx11-cards
- second version of pytorch 2.4.1 has flash attenuation enabled
  and has also the optimization for gfx11* cards.
  Flash attenuation and optimization support are both provied
  by the libaotriation_v2.a library which is linked to pytorch 2.4
- results show that the optimization adds about 5-10x speed up
  for the simple flash attenuation test.
- comparison of cpu/vs gpu results show that even the gfx1035 iGPU
  does some tests much more efficiently than the CPU
