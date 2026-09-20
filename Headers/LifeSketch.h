#ifndef LIFESKETCH_H
#define LIFESKETCH_H
#include "Sketch.h"
#define MAXFP 4294967295
#define MAX(a,b) (a)>(b)?(a):(b)
#define MIN(a,b) (a)>(b)?(b):(a)
class LifeSketch : public Sketch {
public:
    LifeSketch(uint32_t, uint32_t, uint32_t);
    ~LifeSketch();

    void insert(uint32_t, uint32_t, uint32_t);
    uint32_t estimate(uint32_t);

    void show();
    
    void init() {}
    
private:
    uint32_t d, c;
    uint32_t time_interval;
    uint32_t **N, *G;
    uint32_t **S;
    uint32_t max_time = 0;
    uint32_t hash_seed, fp_seed;
};
#endif //LIFESKETCH_H