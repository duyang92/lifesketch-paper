#include "../Headers/LifeSketchRE.h"

#include <iostream>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <ostream>
#include <string.h>

LifeSketchRE::LifeSketchRE(uint32_t d, uint32_t c, uint32_t interval) {
    this->d = d;
    this->c = c;
    ZCLimit = 1;
    time_interval = interval;
    srand(time(NULL));
    hash_seed = uint32_t(rand());
    fp_seed = uint32_t(rand());
    N = new unsigned *[d];
    S = new unsigned *[d];

    G = new unsigned[d];
    Z = new unsigned[d];
    Z_S = new unsigned[d];
    Z_C = new unsigned[d];

    for (int i = 0; i < d; ++i) {
        N[i] = new unsigned[c];
        S[i] = new unsigned[c];
        for (int l = 0; l < c; ++l) {
            S[i][l] = 0;
            N[i][l] = MAXFP;
        }

        G[i] = MAXFP;
        Z[i] = 0;
        Z_C[i] = ZCLimit;
        Z_S[i] = MAXZS;
    }
}

LifeSketchRE::~LifeSketchRE() {
    delete[] G;
    delete[] Z;
    for (int i = 0; i < d; ++i) {
        delete[] N[i];
        delete[] S[i];
    }
}

void LifeSketchRE::insert(uint32_t flow_id, uint32_t cur_time, uint32_t opt) {
    uint32_t hash_idx, hash_val, fp_val;
    char hash_input_str[5];
    memcpy(hash_input_str, &flow_id, 4);
    MurmurHash3_x86_32(hash_input_str, 4, hash_seed, &hash_val);
    hash_idx = hash_val % d;
    MurmurHash3_x86_32(hash_input_str, 4, fp_seed, &fp_val);
    fp_val = fp_val % MAXFP;
    if (opt == 1) {
        if (cur_time >= time_interval + Z_S[hash_idx]){
            G[hash_idx] = Z[hash_idx];
            Z_S[hash_idx] = MAXZS;
            Z_C[hash_idx] = ZCLimit;
        }

        int empty_idx = -1;
        for (int i = 0; i < c; i++) {
            if ((N[hash_idx][i] == MAXFP) || (cur_time >= S[hash_idx][i] + time_interval)) {
                empty_idx = i;
            }

            if (N[hash_idx][i] == fp_val) {
                S[hash_idx][i] = cur_time;
                return;
            }
        }
        if (empty_idx != -1) {
            N[hash_idx][empty_idx] = fp_val;
            S[hash_idx][empty_idx] = cur_time;

            if (Z[hash_idx] < fp_val && G[hash_idx] < fp_val && Z_C[hash_idx] > 0){
                Z[hash_idx] = fp_val;
                Z_S[hash_idx] = cur_time;
                Z_C[hash_idx] -= 1;
            }
            return;
        } else {
            int max_index = -1;
            // int max_val;
            uint32_t max_val = 0;
            for (int i = 0; i < c; i ++) {
                if (max_index == -1) {
                    max_index = i;
                    max_val = N[hash_idx][i];
                } else {
                    if (N[hash_idx][i] > max_val) {
                        max_val = N[hash_idx][i];
                        max_index = i;
                    }
                }
            }
            if (max_val > fp_val) {
                N[hash_idx][max_index] = fp_val;
                S[hash_idx][max_index] = cur_time;
                fp_val = max_val;
            }
            if (fp_val < G[hash_idx]){
                Z[hash_idx] = G[hash_idx];
                G[hash_idx] = fp_val;
            }
            if (fp_val < Z[hash_idx]) {
                Z[hash_idx] = fp_val;
            }

        }
    } else {
        for (int i = 0; i < c; ++i) {
            if (N[hash_idx][i] == fp_val) {
                N[hash_idx][i] = MAXFP;
                S[hash_idx][i] = cur_time;
            }
        }
    }
}

uint32_t LifeSketchRE::estimate(uint32_t cur_time) {
    double est = 0.0;
    for (int i = 0; i < d; ++i) {
        uint32_t ncnt = 0;
        for (int j = 0; j < c; ++j) {
            if ((N[i][j] != MAXFP) & (cur_time < time_interval + S[i][j]) & (N[i][j] < G[i])) {
                ncnt ++;
            }
        }
        est += (1.0 * MAXFP) / (1.0 * G[i]) * (1.0 * ncnt);
    }
    return static_cast<uint32_t>(est);
}

void LifeSketchRE::show(uint32_t cur_time) {
    for (int i = 0; i < d; i ++){
        std::cout << "Bucket " << i << ": [";
        for (int j = 0; j < c; ++j) {
            std::cout << N[i][j] << " @"<<S[i][j];

            if (j < c - 1) std::cout << ", ";
        }
        std::cout << "]    G: " << G[i] << ",    Z: " << Z[i]
            << ",    Z_S: " << Z_S[i] << ",    Z_C: " << Z_C[i] << std::endl;
    }
    std::cout << std::endl;
}