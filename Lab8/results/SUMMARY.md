# Lab 8 results (20M warmup + 20M simulated instructions, benchmark.trace.xz)

## Q1: baseline (prelab config)

| Cache | Accesses | Hits | Misses | Hit rate |
|---|---|---|---|---|
| L1I | 5,495,210 | 5,495,210 | 0 | 100.00% |
| L1D | 6,666,687 | 6,583,155 | 83,532 | 98.75% |
| L2C | 83,714 | 33,131 | 50,583 | 39.58% |
| LLC | 50,619 | 50,613 | 6 | 99.99% |

IPC = **1.163** (20,000,002 instructions in 17,203,576 cycles)

## Q2: doubling one cache level (capacity x2, latency x1.5 rounded up)

| Config | IPC | Cycles | Speedup vs baseline | L1D avg miss latency | L2C hit rate | L2C misses | LLC accesses |
|---|---|---|---|---|---|---|---|
| baseline | 1.163 | 17,203,576 | 1.0000 (+0.00%) | 13.49 cyc | 39.58% | 50,583 | 50,619 |
| L1D_double | 1.157 | 17,287,075 | 0.9952 (-0.48%) | 14.5 cyc | 39.42% | 50,583 | 50,619 |
| L2C_double | 1.200 | 16,662,196 | 1.0325 (+3.25%) | 7.011 cyc | 99.99% | 6 | 6 |
| LLC_double | 1.149 | 17,405,382 | 0.9884 (-1.16%) | 15.91 cyc | 39.58% | 50,583 | 50,619 |

Speedup = baseline cycles / new cycles (same instruction count, so = new IPC / baseline IPC).
