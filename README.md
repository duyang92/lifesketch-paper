## LifeSketch

### Introduction

Accurate active flow counting is critical for network security and management tasks like DDoS detection and load balancing. Existing sketches approximate active flows as those seen within a fixed or sliding window, systematically misestimating flows due to their inability to track true lifecycle states: they undercount long-lived low-rate flows and overcount short-lived ones due to residual entries. We present LifeSketch, the first hardware-deployable sketch that enables lifecycle-aware active flow counting, bridging the gap between theoretical cardinality estimation and operational needs for real-time lifecycle awareness in high-speed network measurement. LifeSketch explicitly models per-flow state transitions (i.e., active, timeout, and closed) with $O(1)$ insertion and deletion operations. It combines adaptive flow sampling, a virtual bucket array for compact per-flow state tracking, and a rejuvenation mechanism to stabilize performance under traffic dynamics. We derive a tight error bound and implement LifeSketch on an Intel Tofino switch, overcoming data plane constraints such as circular dependencies. Evaluations on real-world traces show LifeSketch reduces estimation error by up to 46.73$\times$ compared to state-of-the-art methods while maintaining line-rate processing.

### About this repo

The core **LifeSketch** structure is implemented in the **/headers** and **/sources** folders.

Other baseline methods are also implemented in the same headers and sources directories.

The dataset files are placed under the **/data** directory.

The main function is the **main.cpp** file.

The **main.sh** script is provided to compile and run the project conveniently.

The **CMakeLists.txt** file is used for building the project with CMake.

### Requirements

- Linux (we recommend Ubuntu 20.04.6)
- g++ (gcc-version >= 13.1.0)
- cmake (cmake-version >= 3.29.6)

### Dataset

Please note that the dataset needs to have its IP addresses converted to integers beforehand. Each line should consist of six unsigned integers separated by a space, as shown below:
```
<timestamp> <source IP> <destination IP> <source port> <destination port> <operation>
```
where `<operation>` is either 1 (for insertion) or 0 (for deletion), which is determined based on SYN/FIN signals.

Due to the large size of the original dataset, we do not include it in this repository. Instead, we provide a small demo dataset in the data folder for illustration and testing.

### How to build

You can use the following commands to build and run.

```sh
$ chmod u+x ./main.sh
$./main.sh
```
