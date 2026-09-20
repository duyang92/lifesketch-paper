/* -*- P4_16 -*- */
#include<core.p4>
#if __TARGET_TOFINO__ == 2
#include<t2na.p4>
#else
#include<tna.p4>
#endif

#define BUCKET_NUM 1024
#define CELL_SIZE 32
#define TIME_SIZE 16
#define MAX_VAL 0x7FFFFFFF

const bit<16> TYPE_IPV4 = 0x800;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header udp_h {
	bit<16> src_port;
	bit<16> dst_port;
	bit<16> total_len;
	bit<16> checksum;
}

struct egress_headers_t {}
struct egress_metadata_t {}

header my_flow_h {
	bit<32> id;
#ifdef __TEST__
	bit<32> timestamp;
#endif
}

header my_record_h {
    bit<8>  resubmit_flag;
    bit<8>  outdated_flag1;
    bit<8>  outdated_flag2;
    bit<8>  resubmit_type;
    bit<16> time_count;
    bit<32> hash_index;
    bit<32> fingerprint1;
    bit<32> fingerprint2;
    bit<32> fingerprintG;
    bit<16> time_count2;
    bit<32> fp_delta1;
    bit<32> fp_delta2;
    bit<8>  has_recorded;
    bit<16> time_delta1;
    bit<16> time_delta2;
}

struct metadata{
    bit<32> diff_val;
    bit<32> reg_fingerprint1;
    bit<32> reg_fingerprint2;
    bit<32> cmp_Z_val;
    bit<8>  time_valid1;
    bit<16> time_count1;
    bit<16> time_count2;
    bit<8>  time_valid2;
    bit<8>  go_to_G;
    bit<8>  update_flag;
    bit<8>  time_update_tag;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_h        udp;
    my_flow_h   myflow;
	my_record_h myrecord;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                out metadata meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
		packet.extract(ig_intr_md);
		packet.advance(PORT_METADATA_SIZE);
		transition parse_ethernet;
    }
	
	state parse_ethernet {
		packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
	}
	
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol)
        {
            (bit<8>) 17 : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
		packet.extract(hdr.udp);
		transition parse_myflow;
	}

	state parse_myflow {
		packet.extract(hdr.myflow);
		transition select(ig_intr_md.resubmit_flag) {
			0: parse_origin;
			1: parse_resubmit;
		}
	}

	state parse_origin {
		hdr.myrecord.setValid();
		transition accept;
	}
	
	state parse_resubmit {
		packet.extract(hdr.myrecord);
		transition accept;
	}

}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  in ingress_intrinsic_metadata_t ig_intr_md,
				  in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
				  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
				  inout ingress_intrinsic_metadata_for_tm_t ig_tm_md
					) {

    Register<bit<TIME_SIZE>,bit<32>>(1) TC;

    RegisterAction<bit<TIME_SIZE>, bit<32>, bit<TIME_SIZE>>(TC) reg_update_TC = {
		void apply(inout bit<TIME_SIZE> register_data, out bit<TIME_SIZE> result) {
			result = register_data;
            register_data = register_data + 1;
		}
	};

    action ac_update_TC() {
        hdr.myrecord.time_count = reg_update_TC.execute(0);
    }

    table tb_update_TC {
        actions = {
            ac_update_TC;
        }
        size = 1;
        const default_action = ac_update_TC;
    }

    // hash functions used in different algorithms
	CRCPolynomial<bit<32>>(coeff=0x04C11DB7,reversed=true, msb=false, extended=false, init=0xFFFFFFFF, xor=0xFFFFFFFF) crc_fp;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc_fp) hash_fp;

	CRCPolynomial<bit<32>>(coeff=0x1131AA27,reversed=true, msb=false, extended=false, init=0xFFFFFFFF, xor=0xFFFFFFFF) crc_loc;
	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, crc_loc) hash_loc;

    // get hash index of each active flow
    action ac_get_hash_index() {
        hdr.myrecord.hash_index = (bit<32>)hash_loc.get({hdr.ipv4.srcAddr})[9:0];
    }

    table tb_get_hash_index {
        actions = {
            ac_get_hash_index;
        }
        size = 1;
        const default_action = ac_get_hash_index;
    }

    // get fingerprint of each active flow
    action ac_get_fingerprint1() {
        hdr.myrecord.fingerprint1 = hash_fp.get({hdr.ipv4.srcAddr});
    }

    table tb_get_fingerprint1 {
        actions = {
            ac_get_fingerprint1;
        }
        size = 1;
        const default_action = ac_get_fingerprint1;
    }

    action ac_diff_fps1() {
        hdr.myrecord.fp_delta1 = hdr.myrecord.fingerprint1 - meta.reg_fingerprint1;
    }

    table tb_diff_fps1{
        key = {
            meta.time_valid1 : exact;
        }
        actions = {
            ac_diff_fps1;
            NoAction;
        }
        size = 8;
        const default_action = NoAction;
        const entries = {
            1 : ac_diff_fps1;
        }
    }

    Register<bit<TIME_SIZE>, bit<32>>(BUCKET_NUM) T1;

    RegisterAction<bit<TIME_SIZE>, bit<32>, bit<TIME_SIZE>>(T1) reg_read_T1 = {
		void apply(inout bit<TIME_SIZE> register_data, out bit<TIME_SIZE> result) {
            result = register_data;
		}
	};

    action ac_read_T1() {
        meta.time_count1 = reg_read_T1.execute(hdr.myrecord.hash_index);
    }

    table tb_read_T1 {
        actions = {
            ac_read_T1;
        }
        size = 1;
        const default_action = ac_read_T1;
    }

    action ac_diff_cur_reg_time1() {
        hdr.myrecord.time_delta1 = hdr.myrecord.time_count - meta.time_count1;
    }

    table tb_diff_cur_reg_time1 {
        actions = {
            ac_diff_cur_reg_time1;
        }
        size = 1;
        const default_action = ac_diff_cur_reg_time1;
    }

    /*action ac_get_time_valid1() {
        meta.time_valid1 = 1;
    }

    action ac_get_time_invalid1() {
        meta.time_valid1 = 0;
    }

    table tb_get_time_valid1 {
        key = {
            hdr.myrecord.time_delta1 : range;
        }
        actions = {
            ac_get_time_valid1;
            ac_get_time_invalid1;
            NoAction;
        }
        size = 16;
        const default_action = NoAction;
        const entries = {
            0..10240 : ac_get_time_valid1;
            10240..65535 : ac_get_time_invalid1;
        }
    }*/

    // All registers should be initialized to INF
    Register<bit<CELL_SIZE>, bit<32>>(BUCKET_NUM) B1;

    RegisterAction<bit<CELL_SIZE>, bit<32>, bit<CELL_SIZE>>(B1) reg_update_B1 = {
		void apply(inout bit<CELL_SIZE> register_data, out bit<CELL_SIZE> result) {
            result = register_data;
			if (register_data > hdr.myrecord.fingerprint1) {
                register_data = hdr.myrecord.fingerprint1;
            }
		}
	};

    action ac_update_B1() {
        meta.reg_fingerprint1 = reg_update_B1.execute(hdr.myrecord.hash_index);
    }

    table tb_update_B1 {
        key = {
            //meta.time_valid1 : exact;
            hdr.myrecord.time_delta1 : range;
        }
        size = 8;
        actions = {
            ac_update_B1;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            0..10240 : ac_update_B1;
        }
    }

    action ac_get_fingerprint2_reg() {
        hdr.myrecord.fingerprint2 = meta.reg_fingerprint1;
        hdr.myrecord.time_count2 = meta.time_count1;
        hdr.myrecord.has_recorded = 1;
    }

    action ac_get_fingerprint2_fingerprint1() {
        hdr.myrecord.fingerprint2 = hdr.myrecord.fingerprint1;
        hdr.myrecord.time_count2 = hdr.myrecord.time_count;
        hdr.myrecord.has_recorded = 0;
    }

    action ac_set_outdate_time1() {
        hdr.myrecord.resubmit_flag = 1;
        hdr.myrecord.outdated_flag1 = 1;
        hdr.myrecord.has_recorded = 1;
    }

    table tb_get_fingerprint2 {
        key = {
            //meta.time_valid1 : exact;
            hdr.myrecord.time_delta1 : range;
            hdr.myrecord.fp_delta1 : ternary;
        }
        actions = {
            ac_get_fingerprint2_reg;
            ac_get_fingerprint2_fingerprint1;
            ac_set_outdate_time1;
            NoAction;
        }
        size = 16;
        const default_action = ac_get_fingerprint2_fingerprint1;
        const entries = {
            (0..10240, 0x80000000 &&& 0x80000000) : ac_get_fingerprint2_reg;
            (0..10240, 0x00000000 &&& 0xFFFFFFFF) : ac_set_outdate_time1;
        }
    }

    /******************************LEVEL 2**********************************/

    Register<bit<TIME_SIZE>, bit<32>>(BUCKET_NUM) T2;

    RegisterAction<bit<TIME_SIZE>, bit<32>, bit<TIME_SIZE>>(T2) reg_read_T2 = {
		void apply(inout bit<TIME_SIZE> register_data, out bit<TIME_SIZE> result) {
            result = register_data;
		}
	};

    action ac_read_T2() {
        meta.time_count2 = reg_read_T2.execute(hdr.myrecord.hash_index);
    }

    table tb_read_T2 {
        actions = {
            ac_read_T2;
        }
        size = 1;
        const default_action = ac_read_T2;
    }

    action ac_diff_cur_reg_time2() {
        hdr.myrecord.time_delta2 = hdr.myrecord.time_count2 - meta.time_count2;
    }

    table tb_diff_cur_reg_time2 {
        actions = {
            ac_diff_cur_reg_time2;
        }
        size = 1;
        const default_action = ac_diff_cur_reg_time2;
    }

    // All registers should be initialized to INF
    Register<bit<CELL_SIZE>, bit<32>>(BUCKET_NUM) B2;

    RegisterAction<bit<CELL_SIZE>, bit<32>, bit<CELL_SIZE>>(B2) reg_update_B2 = {
		void apply(inout bit<CELL_SIZE> register_data, out bit<CELL_SIZE> result) {
            result = register_data;
			if (register_data > hdr.myrecord.fingerprint2) {
                register_data = hdr.myrecord.fingerprint2;
            }
		}
	};

    action ac_update_B2() {
        meta.reg_fingerprint2 = reg_update_B2.execute(hdr.myrecord.hash_index);
    }

    table tb_update_B2 {
        key = {
            hdr.myrecord.has_recorded : exact;
            hdr.myrecord.time_delta2 : range;
        }
        size = 8;
        actions = {
            ac_update_B2;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            (0, 0..10240) : ac_update_B2;
        }
    }

    action ac_diff_fps2() {
        hdr.myrecord.fp_delta2 = hdr.myrecord.fingerprint2 - meta.reg_fingerprint2;
    }

    table tb_diff_fps2{
        key = {
            hdr.myrecord.has_recorded : exact;
            hdr.myrecord.time_delta2 : range;
        }
        actions = {
            ac_diff_fps2;
            NoAction;
        }
        size = 8;
        const default_action = NoAction;
        const entries = {
            (0, 0..10240) : ac_diff_fps2;
        }
    }

    action ac_get_fingerprintG_reg() {
        hdr.myrecord.fingerprintG = meta.reg_fingerprint2;
        meta.go_to_G = 1;
    }

    action ac_get_fingerprintG_fingerprint2() {
        hdr.myrecord.fingerprintG = hdr.myrecord.fingerprint2;
        meta.go_to_G = 1;
    }

    action ac_set_outdate_time2() {
        hdr.myrecord.resubmit_flag = 1;
        hdr.myrecord.outdated_flag2 = 1;
        hdr.myrecord.has_recorded = 2;
        meta.go_to_G = 0;
    }

    action ac_set_skip_G() {
        meta.go_to_G = 0;
    }

    table tb_get_fingerprintG {
        key = {
            hdr.myrecord.has_recorded : exact;
            hdr.myrecord.time_delta2 : range;
            hdr.myrecord.fp_delta2 : ternary;
        }
        actions = {
            ac_get_fingerprintG_reg;
            ac_get_fingerprintG_fingerprint2;
            ac_set_outdate_time2;
            ac_set_skip_G;
            NoAction;
        }
        size = 16;
        const default_action = ac_get_fingerprintG_fingerprint2;
        const entries = {
            (0, 0..10240, 0x80000000 &&& 0x80000000) : ac_get_fingerprintG_reg;
            (0, 0..10240, 0x00000000 &&& 0xFFFFFFFF) : ac_set_outdate_time2;
            (1, 0..65535, 0x00000000 &&& 0x00000000) : ac_set_skip_G;
        }
    }

    /***********************GUARD CELLs**************************/

    Register<bit<CELL_SIZE>, bit<32>>(BUCKET_NUM) G;

    // update guard cell in the hash bucket
    RegisterAction<bit<CELL_SIZE>, bit<32>, bit<CELL_SIZE>>(G) reg_update_G = {
		void apply(inout bit<CELL_SIZE> register_data, out bit<CELL_SIZE> result) {
			if (register_data > hdr.myrecord.fingerprintG) {
                register_data = hdr.myrecord.fingerprintG;
            } else {
                register_data = register_data;
            }
		}
	};

    action ac_update_G() {
        reg_update_G.execute(hdr.myrecord.hash_index);
    }

    table tb_update_G {
        key = {
            meta.go_to_G : exact;
        }
        actions = {
            ac_update_G;
            NoAction;
        }
        size = 8;
        const default_action = NoAction;
        const entries = {
            1 : ac_update_G;
        }
    }

    /*
		Basic forwarding
	*/
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }
	
    action ipv4_forward(egressSpec_t port) {
	    ig_tm_md.ucast_egress_port = port;
    }
	
	@pragma stage 0
    table ipv4_lpm {
        key = {
		    hdr.ipv4.dstAddr: lpm;
        }

        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }

        size = 32;

        default_action = NoAction();
    }

    /***********************Recirculation**************************/

    RegisterAction<bit<TIME_SIZE>, bit<32>, bit<TIME_SIZE>>(T1) reg_write_T1 = {
		void apply(inout bit<TIME_SIZE> register_data, out bit<TIME_SIZE> result) {
            register_data = hdr.myrecord.time_count;
		}
	};

    action ac_write_T1() {
        reg_write_T1.execute(hdr.myrecord.hash_index);
    }

    table tb_write_T1 {
        key = {
            hdr.myrecord.time_delta1 : range;
            hdr.myrecord.has_recorded : exact;
        }
        actions = {
            ac_write_T1;
            NoAction;
        }
        size = 8;
        const default_action = NoAction;
        const entries = {
            (10240..65535, 0) : ac_write_T1;
            (10240..65535, 1) : ac_write_T1;
            (0..10240, 1) : ac_write_T1;
        }
    }

    RegisterAction<bit<TIME_SIZE>, bit<32>, bit<TIME_SIZE>>(T2) reg_write_T2 = {
		void apply(inout bit<TIME_SIZE> register_data, out bit<TIME_SIZE> result) {
            register_data = hdr.myrecord.time_count;
		}
	};

    action ac_write_T2() {
        reg_write_T2.execute(hdr.myrecord.hash_index);
    }

    table tb_write_T2 {
        key = {
            hdr.myrecord.time_delta2 : range;
            hdr.myrecord.has_recorded : exact;
        }
        actions = {
            ac_write_T2;
            NoAction;
        }
        size = 8;
        const default_action = NoAction;
        const entries = {
            (10240..65535, 0) : ac_write_T2;
            (10240..65535, 2) : ac_write_T2;
            (0..10240, 2) : ac_write_T2;
        }
    }

    RegisterAction<bit<CELL_SIZE>, bit<32>, bit<CELL_SIZE>>(B1) reg_reset_B1 = {
		void apply(inout bit<CELL_SIZE> register_data, out bit<CELL_SIZE> result) {
            register_data = MAX_VAL;
		}
	};

    action ac_reset_B1() {
        reg_reset_B1.execute(hdr.myrecord.hash_index);
    }

    table tb_reset_B1 {
        key = {
            hdr.myrecord.time_delta1 : range;
        }
        size = 8;
        actions = {
            ac_reset_B1;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            10240..65535 : ac_reset_B1;
        }
    }

    RegisterAction<bit<CELL_SIZE>, bit<32>, bit<CELL_SIZE>>(B2) reg_reset_B2 = {
		void apply(inout bit<CELL_SIZE> register_data, out bit<CELL_SIZE> result) {
            register_data = MAX_VAL;
		}
	};

    action ac_reset_B2() {
        reg_reset_B2.execute(hdr.myrecord.hash_index);
    }

    table tb_reset_B2 {
        key = {
            hdr.myrecord.time_delta2 : range;
        }
        size = 8;
        actions = {
            ac_reset_B2;
            NoAction;
        }
        const default_action = NoAction;
        const entries = {
            10240..65535 : ac_reset_B2;
        }
    }

    apply {
        //only if IPV4 the rule is applied. Therefore other packets will not be forwarded.
        if (hdr.ipv4.isValid()){
            if (ig_intr_md.resubmit_flag == 0) {
                tb_update_TC.apply();
                tb_get_fingerprint1.apply();
                tb_get_hash_index.apply();
                // L1
                tb_read_T1.apply();
                tb_diff_cur_reg_time1.apply();
                tb_update_B1.apply();  //the smaller cell has been updated to the current fingerprint.
                tb_diff_fps1.apply();
                tb_get_fingerprint2.apply();
                // L2
                tb_read_T2.apply();
                tb_diff_cur_reg_time2.apply();
                tb_update_B2.apply();
                tb_diff_fps2.apply();
                tb_get_fingerprintG.apply();
                tb_update_G.apply();
            } else {
                tb_write_T1.apply();
                tb_write_T2.apply();
                tb_reset_B1.apply();
                tb_reset_B2.apply();
                hdr.myrecord.resubmit_flag = 0;
            }
			ipv4_lpm.apply();
        }
    }
}

control IngressDeparser(packet_out packet,
	inout headers hdr,
	in metadata meta,
	in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    Resubmit() resubmit;
	apply{
        if (hdr.myrecord.resubmit_flag == 1) {
			resubmit.emit();
		}
		packet.emit(hdr);
	}
}
/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/
parser EgressParser(packet_in packet,
	out egress_headers_t hdr,
	out egress_metadata_t meta,
	out egress_intrinsic_metadata_t eg_intr_md)
{
	state start{
		packet.extract(eg_intr_md);
		transition accept;
	}
}

control Egress(inout egress_headers_t hdr,
				inout egress_metadata_t meta,
				in egress_intrinsic_metadata_t eg_intr_md,
				in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
				inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
				inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) 
{

    apply { 
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control EgressDeparser(packet_out packet, 
						inout egress_headers_t hdr, 
						in egress_metadata_t meta, 
						in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    apply {
        //parsed headers have to be added again into the packet.
		packet.emit(hdr);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
Pipeline(
MyParser(),
MyIngress(),
IngressDeparser(),
EgressParser(),
Egress(),
EgressDeparser()
) pipe;

Switch(pipe) main;