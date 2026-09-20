#include "../Headers/LifeSketch.h"

#include <iostream>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <ostream>
#include <string.h>

LifeSketch::LifeSketch(uint32_t d, uint32_t c, uint32_t interval) {
    this->d = d;
    this->c = c;
    time_interval = interval;
    srand(time(NULL));
    hash_seed = uint32_t(rand());
    fp_seed = uint32_t(rand());
    N = new unsigned *[d];
    S = new unsigned *[d];
    for (int i = 0; i < d; ++i) {
        N[i] = new unsigned[c];
        S[i] = new unsigned[c];
        for (int l = 0; l < c; ++l) {
            S[i][l] = 0;
            N[i][l] = MAXFP;
        }
    }
    G = new unsigned[d];
    memset(G, MAXFP, sizeof(uint32_t) * d);
}

LifeSketch::~LifeSketch() {
    delete[] G;
    for (int i = 0; i < d; ++i) {
        delete[] N[i];
        delete[] S[i];
    }
}

void LifeSketch::insert(uint32_t flow_id, uint32_t cur_time, uint32_t opt) {
    uint32_t hash_idx, hash_val, fp_val;
    char hash_input_str[5];
    memcpy(hash_input_str, &flow_id, 4);
    MurmurHash3_x86_32(hash_input_str, 4, hash_seed, &hash_val);
    hash_idx = hash_val % d;
    MurmurHash3_x86_32(hash_input_str, 4, fp_seed, &fp_val);
    fp_val = fp_val % MAXFP;
    if (opt == 1) {
        for (int i = 0; i < c; i ++) {
            if (cur_time - S[hash_idx][i] > time_interval) {
                N[hash_idx][i] = MAXFP;
                S[hash_idx][i] = cur_time;
            }
        }
        int empty_idx = -1;
        for (int i = 0; i < c; i++) {
            if (N[hash_idx][i] == MAXFP) {
                empty_idx = i;
            }
            if (N[hash_idx][i] == fp_val) {
                S[hash_idx][i] = cur_time;
                return;
            }
        }
        if (fp_val >= G[hash_idx]) {
            return;
        }
        if (empty_idx != -1) {
            N[hash_idx][empty_idx] = fp_val;
            S[hash_idx][empty_idx] = cur_time;
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
                G[hash_idx] = max_val;
                N[hash_idx][max_index] = fp_val;
                S[hash_idx][max_index] = cur_time;
            } else {
                G[hash_idx] = fp_val;
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
        /*uint32_t ofp = fp_val;
        uint32_t _fp = fp_val;
        uint32_t _cur = cur_time;
        bool seen_before = false;
        for (int i = 0; i < c; ++i) {
            if (cur_time >= time_interval + S[hash_idx][i]) {
                if (N[hash_idx][i] == _fp) {
                    S[hash_idx][i] = cur_time;
                    return;
                } else {
                    S[hash_idx][i] = cur_time;
                    N[hash_idx][i] = MAXFP;
                }
            } else {
                if ((seen_before == true) & (N[hash_idx][i] == ofp)) {
                    N[hash_idx][i] = MAXFP;
                    S[hash_idx][i] = cur_time;
                }
                if (N[hash_idx][i] == _fp) {
                    if (_fp == ofp) {
                        if (seen_before == false) {
                            seen_before = true;
                            S[hash_idx][i] = cur_time;
                        }
                    } else {
                        S[hash_idx][i] = MAX(S[hash_idx][i],_cur);
                    }
                    return;
                } else if (N[hash_idx][i] < _fp) {
                    continue;
                } else {
                    uint32_t tmp_fp = N[hash_idx][i];
                    N[hash_idx][i] = _fp;
                    _fp = tmp_fp;
                    uint32_t tmp_cur = S[hash_idx][i];
                    S[hash_idx][i] = _cur;
                    _cur = tmp_cur;
                }
            }
        }
        if (_fp != MAXFP) {
            G[hash_idx] = MIN(G[hash_idx],_fp);
        }
    } else {
        for (int i = 0; i < c; ++i) {
            if (N[hash_idx][i] == hash_val) {
                N[hash_idx][i] = MAXFP;
                S[hash_idx][i] = cur_time;
            }
        }
    }*/
}

uint32_t LifeSketch::estimate(uint32_t cur_time) {
    double est = 0.0;
    for (int i = 0; i < d; ++i) {
        uint32_t ncnt = 0;
        for (int j = 0; j < c; ++j) {
            if ((N[i][j] != MAXFP) & (cur_time - S[i][j] < time_interval) & (N[i][j] < G[i])) {
                ncnt ++;
            }
        }
        est += (1.0 * MAXFP) / (1.0 * G[i]) * (1.0 * ncnt);
    }
    return static_cast<uint32_t>(est);
}

void LifeSketch::show() {
    for (int i = 0; i < d; i ++)
        for (int j = 0; j < c; ++j) {
            std::cout << N[i][j] << " ";
        }
    std::cout << std::endl;
}