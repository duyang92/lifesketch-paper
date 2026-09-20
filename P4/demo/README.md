### P4 BMv2 Implementation

The BMv2 implementation of **LifeSketch** is provided in [`./life.p4`](./life.p4) and is written in the P4 language. The demo uses a simple point-to-point topology consisting of two hosts and one switch (`h1-sw1-h2`).

---

### Requirements

* Mininet (version ≥ 2.3.0)
* BMv2/simple_switch (version ≥ 1.13.0)
* GCC (version ≥ 5.4.0)
* Ubuntu 16.04

---

### Compilation and Execution

#### 1. Compile the P4 Program

Build `life.p4`, which contains the parser, ingress, egress, and deparser modules, and generate the corresponding `topology.db`:

```bash
$ cd p4src
$ sudo p4run
```

#### 2. Initialize LifeSketch

Initialize the registers and RMT tables used by LifeSketch:

```bash
$ cd ..
$ chmod u+x ./start.sh
$ ./start.sh
```

#### 3. Send Packets from h1

Enter the h1 Mininet terminal and send packets to h2 through sw1:

```bash
$ mx h1
$ python send.py
```

#### 4. Retrieve Active-Flow Counting Results

Run the following script to retrieve the active-flow counting results:

```bash
$ chmod u+x get.sh
$ ./get.sh
```
