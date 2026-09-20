#ifndef SHE_BM_H
#define SHE_BM_H
#include "Sketch.h"
#include <bitset>

#define MAX(a,b) (a)>(b)?(a):(b)

class SHE_BM : public Sketch {
public:
    SHE_BM(int, double, int, int, int, uint64_t);
    ~SHE_BM();
    void insert(uint32_t, uint32_t, uint32_t);
    uint32_t estimate(uint32_t);
    bool get_timestamp(uint64_t, int);
    void check_timestamp(int);
    void init() {
        //bm.clear();
    }
private:
    constexpr static const double alpha = 0.2;
    static const int
        MAX_CELL_NUM = 32 * 1e5 + 5,
        MAX_HASH_NUM = 50;
    int
        window,
        memory,
        hash_num,
        max_cell_num,
        group_size;
    long long relax_window_size;
    std::bitset<MAX_CELL_NUM> bm;
    bool time_stamp[MAX_CELL_NUM];
    uint32_t hash_seed;
    uint32_t hash[MAX_HASH_NUM];
    uint64_t current_time, start_time;
};

#endif //SHE_BM_H
