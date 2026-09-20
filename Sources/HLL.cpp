#include "../Headers/HLL.h"

#include <string.h>

HLL::HLL(uint32_t m) {
    this->m = m;
    if(m == 16)
        alpha = 0.673;
    else if(m == 32)
        alpha = 0.697;
    else if(m == 64)
        alpha = 0.709;
    else
        alpha = (0.7213 / (1 + (1.079 / m)));
    srand(time(NULL));
    this->hash_seed = uint32_t(rand());
    this->num_leading_bit = floor(log10(double(m))/log10(2.0));
    R = new unsigned[m];
    memset(R, 0, sizeof(uint32_t) * m);
}

HLL::~HLL() {
    delete[] R;
}

void HLL::insert(uint32_t flow_id, uint32_t time_stamp, uint32_t opt) {
    uint32_t ele_hash_val;
    char hash_input_str[5];
    memcpy(hash_input_str, &flow_id, 4);
    MurmurHash3_x86_32(hash_input_str, 4, hash_seed, &ele_hash_val);
    uint32_t p_part = ele_hash_val >> (32 - num_leading_bit);
    uint32_t q_part = ele_hash_val - (p_part << (32 - num_leading_bit));
    uint32_t left_most = 0;
    while(q_part) {
        left_most += 1;
        q_part = q_part >> 1;
    }
    left_most = 32 - num_leading_bit - left_most + 1;
    R[ele_hash_val % m] = MAX(R[ele_hash_val % m],left_most);
}

uint32_t HLL::estimate(uint32_t time_stamp) {
    double _est = 0.0;
    uint32_t zero_cnt = 0;
    for (int i = 0; i < m; ++i) {
        _est += pow(2.0, -double(R[i]));
        if (R[i] == 0)
            zero_cnt ++;
    }
    double flow_cardi = alpha * pow(m, 2) / _est;
    if (flow_cardi <= 2.5 * m) {
        if(zero_cnt != 0) {
            flow_cardi = - log(1.0 * zero_cnt / (1.0 * m)) * m;
        }
    } else if (flow_cardi > pow(2.0, 32) / 30) {
        flow_cardi = - pow(2.0, 32) * log(1 - flow_cardi / pow(2.0, 32));
    } else if (flow_cardi < pow(2.0, 32) / 30) {
        flow_cardi = flow_cardi;
    }
    return flow_cardi;
}
