#  Naïve RISC-V CPU

## Introduction

This is a naïve RISC-V CPU with RV32I Base Instruction Set implemented in Verilog. 

## Features

* It's a five stages pipeline with a controller to solve hazards.
* It has a branch predictor implemented by 2-bit saturating counters.
* It has a 1 KB directed mapped instruction cache.
* It has a 1 KB directed mapped data cache.
* It can run on FPGA at 100 MHz.

## Reference

* J. L. Hennessy and D. A. Patterson, Computer Architecture: A Quantitative Approach, 5th Edition
* 雷思磊《自己动手写CPU》
* 夏宇闻 《Verilog经典教程》

## Testcases

| Testcase       | Correctness |
| -------------- | ----------- |
| array_test1    | Pass        |
| array_test2    | Pass        |
| basicopt1      | Pass        |
| bulgarian      | Pass        |
| expr           | Pass        |
| gcd            | Pass        |
| hanoi          | Pass        |
| lvalue2        | Pass        |
| magic          | Pass        |
| manyarguments  | Pass        |
| multiarray     | Pass        |
| pi             | Pass        |
| qsort          | Pass        |
| queens         | Pass        |
| statement_test | Pass        |
| superloop      | Pass        |
| tak            | Pass        |
| testsleep      | Pass        |