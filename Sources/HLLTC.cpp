#include "../Headers/HLLTC.h"

#include <time.h>
#include <math.h>
#include <string.h>

HLLTC::HLLTC(uint32_t m) {
    this->m = m;
    if(m == 16)
        alpha = 0.673;
    else if(m == 32)
        alpha = 0.697;
    else if(m == 64)
        alpha = 0.709;
    else
        alpha = (0.7213 / (1 + (1.079 / m)));
    this->B = 0;
    this->K = 15;
    this->R = new unsigned[m];
    memset(R, 0, sizeof(uint32_t) * m);
    srand(time(NULL));
    hash_seed = uint32_t(rand());
    this->num_leading_bit = floor(log10(double(m))/log10(2.0));
}

void HLLTC::insert(uint32_t flow_id, uint32_t cur_time, uint32_t opt) {
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

    int diff;
    if (left_most > B)
        diff = left_most - B;
    else
        diff = 0;

    if (diff > K) {
        int min_val = 0, min_idx = -1;
        for (int i = 0; i < m; i ++) {
            if (min_idx == -1) {
                min_idx = i;
                min_val = R[i];
            } else {
                if (R[i] < min_val) {
                    min_idx = i;
                    min_val = R[i];
                }
            }
        }
        if (min_val > 0) {
            B = MIN(B + min_val,31);
            for (int i = 0; i < m; ++i) {
                R[i] = R[i] - min_val;
            }
        }
    }

    R[p_part] = MAX(R[p_part],MIN(diff, K));
}

uint32_t HLLTC::estimate(uint32_t cur_time) {
    double _est = 0.0;
    uint32_t zero_cnt = 0;
    for (int i = 0; i < m; ++i) {
        double exp_val = R[i] + B;
        double temp_val = pow(2.0, -exp_val);
        _est += temp_val;
        if (R[i] + B == 0)
            zero_cnt ++;
    }
    double flow_cardi = alpha * pow(m, 2) / _est;
    if (flow_cardi <= 2.5 * m) {
        if(zero_cnt != 0) {
            flow_cardi = - log(1.0 * zero_cnt / (1.0 * m)) * m;
        }
    } else if (flow_cardi > pow(2.0, 32) / 30) {
        flow_cardi = - pow(2.0, 32) * log(1 - flow_cardi / pow(2.0, 32));
    }
    return flow_cardi;
}
