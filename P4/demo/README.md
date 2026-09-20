### P4 BMv2 Implementation

The BMv2 version of **LifeSketch** is implemented in [`./life.p4`](./life.p4) using the P4 language.

---

### Requirements

* Mininet (version ≥ 2.3.0)
* BMv2/simple_switch (version ≥ 1.13.0)
* gcc (version ≥ 5.4.0)
* Ubuntu 16.04

---

### Compilation and Execution

We assume that the environment variable `$SDE` has been configured to point to the P4 SDE installation directory. You can compile, analyze, and run **LifeSketch** as follows:

1. **Compile the P4 program**
   Build `life.p4`, which contains the parser, ingress, egress, and deparser modules:

   ```bash
   $SDE/p4_build.sh ./P4/life.p4
   ```

2. **Inspect hardware resource usage**
   To check the resource consumption on the Tofino switch:

   ```bash
   $SDE/p4i.sh
   ```

   Afterward, open **p4insight** via the output port provided by the command.

3. **Run LifeSketch**
   Launch LifeSketch and enter the BFRT shell:

   ```bash
   $SDE/run_switchd.sh -p life
   ```

