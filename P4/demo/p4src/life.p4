/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parsers.p4"

/* CONSTANTS */
#define BUCKET_NUM 16
#define CELL_SIZE 32
#define TIME_SIZE 32
#define TIME_INTER 1000000
#define FP_MAX 4294967295
#define PKT_INSTANCE_TYPE_RESUBMIT 6

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    // Guard cells
    register<bit<CELL_SIZE>>(BUCKET_NUM) G;
    // Normal cell in the first laryer (min)
    register<bit<CELL_SIZE>>(BUCKET_NUM) B1;
    register<bit<TIME_SIZE>>(BUCKET_NUM) T1;
    // Normal cell in the second laryer (mid)
    register<bit<CELL_SIZE>>(BUCKET_NUM) B2;
    register<bit<TIME_SIZE>>(BUCKET_NUM) T2;
    // Normal cell in the third laryer (max)
    register<bit<CELL_SIZE>>(BUCKET_NUM) B3;
    register<bit<TIME_SIZE>>(BUCKET_NUM) T3;

    // Time counter
    register<bit<32>>(1) TC;

    action ac_read_time_counter() {
        TC.read(meta.cur_time_stamp, 0);
    }

    table tb_read_time_counter {
        actions = {
            ac_read_time_counter;
        }
        size = 1;
        const default_action = ac_read_time_counter;
    }

    action ac_write_time_counter() {
        TC.write(0, meta.cur_time_stamp + 1);
    }

    table tb_write_time_counter{
        actions = {
            ac_write_time_counter;
        }
        size = 1;
        const default_action = ac_write_time_counter;
    }

    // read register from guard cell
    action ac_read_guard_cell() {
        G.read(meta.guard_val, hdr.myheader.hash_index);
    }

    table tb_read_guard_cell {
        actions = {
            ac_read_guard_cell;
        }
        size = 1;
        const default_action = ac_read_guard_cell;
    }

    // write register from guard cell
    action ac_write_guard_cell() {
        G.write(hdr.myheader.hash_index, hdr.myheader.update_val);
    }

    table tb_write_guard_cell {
        actions = {
            ac_write_guard_cell;
        }
        size = 1;
        const default_action = ac_write_guard_cell;
    }

    // read register from B1
    action ac_read_b1_cell(){
        B1.read(meta.b1_val, hdr.myheader.hash_index);
    }

    table tb_read_b1_cell {
        actions = {
            ac_read_b1_cell;
        }
        size = 1;
        const default_action = ac_read_b1_cell;
    }

    // write register from B1
    action ac_write_b1_cell(){
        B1.write(hdr.myheader.hash_index, meta.fingerprint);
    }

    table tb_write_b1_cell {
        actions = {
            ac_write_b1_cell;
        }
        size = 1;
        const default_action = ac_write_b1_cell;
    }

    // read time_stamp from T1
    action ac_read_t1_cell() {
        T1.read(meta.reg_time_stamp, hdr.myheader.hash_index);
    }

    table tb_read_t1_cell {
        actions = {
            ac_read_t1_cell;
        }
        size = 1;
        const default_action = ac_read_t1_cell;
    }

    // write time_stamp to t1
    action ac_write_t1_cell() {
        T1.write(hdr.myheader.hash_index, meta.time_stamp);
    }

    table tb_write_t1_cell {
        actions = {
            ac_write_t1_cell;
        }
        size = 1;
        const default_action = ac_write_t1_cell;
    }

    // read register from B2
    action ac_read_b2_cell() {
        B2.read(meta.b2_val, hdr.myheader.hash_index);
    }

    table tb_read_b2_cell {
        actions = {
            ac_read_b2_cell;
        }
        size = 1;
        const default_action = ac_read_b2_cell;
    }

    // write register from B2
    action ac_write_b2_cell() {
        B2.write(hdr.myheader.hash_index, meta.fingerprint);
    }

    table tb_write_b2_cell {
        actions = {
            ac_write_b2_cell;
        }
        size = 1;
        const default_action = ac_write_b2_cell;
    }

    // read time stamp from T2
    action ac_read_t2_cell() {
        T2.read(meta.reg_time_stamp, hdr.myheader.hash_index);
    }

    table tb_read_t2_cell {
        actions = {
            ac_read_t2_cell;
        }
        size = 1;
        const default_action = ac_read_t2_cell;
    }

    // write time stamp to T2
    action ac_write_t2_cell() {
        T2.write(hdr.myheader.hash_index, meta.time_stamp);
    }

    table tb_write_t2_cell {
        actions = {
            ac_write_t2_cell;
        }
        size = 1;
        const default_action = ac_write_t2_cell;
    }

    // read register from B3
    action ac_read_b3_cell() {
        B3.read(meta.b3_val, hdr.myheader.hash_index);
    }

    table tb_read_b3_cell {
        actions = {
            ac_read_b3_cell;
        }
        size = 1;
        const default_action = ac_read_b3_cell;
    }

    // write register from B3
    action ac_write_b3_cell() {
        B3.write(hdr.myheader.hash_index, meta.fingerprint);
    }

    table tb_write_b3_cell {
        actions = {
            ac_write_b3_cell;
        }
        size = 1;
        const default_action = ac_write_b3_cell;
    }

    // read time stamp from T3
    action ac_read_t3_cell() {
        T3.read(meta.reg_time_stamp, hdr.myheader.hash_index);
    }

    table tb_read_t3_cell {
        actions = {
            ac_read_t3_cell;
        }
        size = 1;
        const default_action = ac_read_t3_cell;
    }

    // write time stamp to T3
    action ac_write_t3_cell() {
        T3.write(hdr.myheader.hash_index, meta.time_stamp);
    }

    table tb_write_t3_cell {
        actions = {
            ac_write_t3_cell;
        }
        size = 1;
        const default_action = ac_write_t3_cell;
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action set_egress_port(bit<9> egress_port){
        standard_metadata.egress_spec = egress_port;
    }

    table forwarding {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            set_egress_port;
            drop;
            NoAction;
        }
        size = 64;
        default_action = drop;
    }

    apply {
        if (hdr.ipv4.isValid()){
            if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_RESUBMIT) {
                tb_write_guard_cell.apply();
            } else {
                meta.go_to_2 = 0x0;
                meta.go_to_3 = 0x0;
                meta.update_tag = 0x0;
                tb_read_time_counter.apply();
                tb_write_time_counter.apply();
                meta.time_stamp = meta.cur_time_stamp;
                hash(meta.old_fingerprint, HashAlgorithm.crc32_custom, (bit<16>) 0, {hdr.ipv4.srcAddr}, (bit<32>) FP_MAX);
                meta.fingerprint = meta.old_fingerprint;
                hash(hdr.myheader.hash_index, HashAlgorithm.crc32_custom, (bit<16>) 0, {hdr.ipv4.srcAddr}, (bit<32>) BUCKET_NUM);
                tb_read_guard_cell.apply();
                if (meta.fingerprint < meta.guard_val) {
                    // L1
                    tb_read_b1_cell.apply();
                    tb_read_t1_cell.apply();
                    if (meta.fingerprint <= meta.b1_val) {
                        if (meta.cur_time_stamp - meta.reg_time_stamp < TIME_INTER) {
                            if (meta.fingerprint == meta.b1_val) {
                                meta.go_to_2 = 0x0;
                            } else {
                                meta.go_to_2 = 0x1;
                            }
                        } else {
                            meta.go_to_2 = 0x0;
                        }
                        tb_write_b1_cell.apply();
                        tb_write_t1_cell.apply();
                        meta.fingerprint = meta.b1_val;
                        meta.time_stamp = meta.reg_time_stamp;
                    } else {
                        meta.go_to_2 = 0x1;
                    }
                    if (meta.go_to_2 == 0x1) {
                        // L2
                        tb_read_b2_cell.apply();
                        tb_read_t2_cell.apply();
                        if (meta.fingerprint <= meta.b2_val) {
                            if (meta.cur_time_stamp - meta.reg_time_stamp < TIME_INTER) {
                                if (meta.fingerprint == meta.b2_val) {
                                    meta.go_to_3 = 0x0;
                                } else {
                                    meta.go_to_3 = 0x1;
                                }
                            } else {
                                meta.go_to_3 = 0x0;
                            }
                            tb_write_b2_cell.apply();
                            tb_write_t2_cell.apply();
                            meta.fingerprint = meta.b2_val;
                            meta.time_stamp = meta.reg_time_stamp;
                        } else {
                            meta.go_to_3 = 0x1;
                        }
                    }
                    if (meta.go_to_3 == 0x1) {
                        // L3
                        tb_read_b3_cell.apply();
                        tb_read_t3_cell.apply();
                        if (meta.fingerprint <= meta.b3_val) {
                            if (meta.fingerprint == meta.b3_val) {
                                meta.update_tag = 0x0;
                            } else {
                                if (meta.cur_time_stamp - meta.reg_time_stamp < TIME_INTER) {
                                    hdr.myheader.update_val = meta.b3_val;
                                    meta.update_tag = 0x1;
                                } else {
                                    meta.update_tag = 0x0;
                                }
                            }
                            tb_write_b3_cell.apply();
                            tb_write_t3_cell.apply();
                        } else {
                            hdr.myheader.update_val = meta.fingerprint;
                            meta.update_tag = 0x1;
                        }
                    }
                    if (meta.update_tag == 0x1) {
                        if (hdr.myheader.update_val != FP_MAX) {
                            resubmit({hdr.myheader.hash_index, hdr.myheader.update_val});
                        }
                    }
                }
            }
            /*if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_RESUBMIT) {
                tb_write_guard_cell.apply();
            } else {
                tb_read_guard_cell.apply();
                if (meta.fingerprint < meta.guard_val) {
                    tb_read_b1_cell.apply();
                    if (meta.b1_val != meta.fingerprint) {
                        if (meta.b1_val > meta.fingerprint) {
                            tb_write_b1_cell.apply();
                            meta.fingerprint = meta.b1_val;
                        }
                        tb_read_b2_cell.apply();
                        if (meta.b2_val != meta.fingerprint) {
                            if (meta.b2_val > meta.fingerprint) {
                                tb_write_b2_cell.apply();
                                meta.fingerprint = meta.b2_val;
                            }
                            tb_read_b3_cell.apply();
                            if (meta.b3_val != meta.fingerprint) {
                                if (meta.fingerprint > meta.b3_val) {
                                    hdr.myheader.update_val = meta.fingerprint;
                                } else {
                                    hdr.myheader.update_val = meta.b3_val;
                                    tb_write_b3_cell.apply();
                                }
                            }
                        }
                    }
                }
                if (hdr.myheader.update_val != 0) {
                    //resubmit_preserving_field_list(0);
                    resubmit({hdr.myheader.update_val});
                }
            }*/
            forwarding.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {

    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
