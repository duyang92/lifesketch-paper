#include "../Headers/SHE_BM.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

SHE_BM::SHE_BM(int _window, double _memory, int _hash_num, int _group_size, int _max_cell_num, uint64_t curTime) {
    current_time = curTime;
    start_time = curTime;
    srand(time(NULL));
    for (int i = 0; i < hash_num; i++) {
        hash[i] = uint32_t(rand());
    }
    hash_seed = uint32_t(rand());
    window = _window;
    memory = _memory;
    hash_num = _hash_num;
    group_size = _group_size;
    max_cell_num = _memory * group_size / (group_size + 1);
    relax_window_size = window * (1 + alpha);
}

SHE_BM::~SHE_BM() {
}

bool SHE_BM::get_timestamp(uint64_t tx, int pos) {
    // int t_add = hash_time_offset.run((char *)&pos, sizeof(int)) & ((1 << 29) - 1);
    int t_add = relax_window_size * pos / (max_cell_num);
    return ((tx + t_add - start_time) / relax_window_size) & 1;
}

void SHE_BM::check_timestamp(int pos) {
    int gid = pos / group_size;

    if (get_timestamp(current_time, pos) == time_stamp[gid])
        return;
    time_stamp[gid] = get_timestamp(current_time, pos);

    int st = pos / group_size * group_size;
    for (int i = st; i < st + group_size && i < max_cell_num; i++)
        bm[i] = 0;
}

void SHE_BM::insert(uint32_t flow_id, uint32_t curTime, uint32_t opt) {
    current_time = curTime;
    for (int i = 0; i < hash_num; i++) {
        uint32_t ele_hash_val;
        char hash_input_str[5];
        memcpy(hash_input_str, &flow_id, 4);
        MurmurHash3_x86_32(hash_input_str, 4, hash[i], &ele_hash_val);
        int pos = ele_hash_val % max_cell_num;
        check_timestamp(pos);
        bm[pos] = 1;
    }
}

uint32_t SHE_BM::estimate(uint32_t curTime) {
    int ns = 0;
    double u = 0;
    long double x;
    for (int i = 0; i < max_cell_num / group_size; i++) {
        check_timestamp(i * group_size);
        // int t_add = hash_time_offset.run((char*)&i, sizeof(int))&((1<<29)-1);

        int t_add = relax_window_size * i / (max_cell_num / group_size);

        x = (current_time + t_add - start_time) % relax_window_size;
        if (x < (1 - alpha) * window)
            continue;

        for (int j = i * group_size;
             j < i * group_size + group_size && j < max_cell_num; j++) {
            if (bm[j] == 0)
                u++;
            ns++;
        }
    }
    if (u == 0) {
        return static_cast<uint32_t>(max_cell_num * log(1.0 * max_cell_num));
    } else {
        return static_cast<uint32_t>(-max_cell_num * log(u / ns));
    }
}
