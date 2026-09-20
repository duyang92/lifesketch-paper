#ifndef LIFESKETCHRE_H
#define LIFESKETCHRE_H
#include "Sketch.h"
#include <utility>
#define MAXFP 4294967295
#define MAXZS 2147483647
#define MAX(a,b) (a)>(b)?(a):(b)
#define MIN(a,b) (a)>(b)?(b):(a)
class LifeSketchRE : public Sketch {
public:
    LifeSketchRE(uint32_t, uint32_t, uint32_t);
    ~LifeSketchRE();

    void insert(uint32_t, uint32_t, uint32_t);
    uint32_t estimate(uint32_t);

    void show(uint32_t);

    void init() {}

private:
    uint32_t d, c;
    uint32_t time_interval;
    uint32_t **N, *G, *Z, *Z_S, *Z_C;
    uint32_t **S;
    uint32_t max_time = 0;
    uint32_t hash_seed, fp_seed;
    int ZCLimit;
};

#endif //LIFESKETCHRE_H