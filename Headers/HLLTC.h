#ifndef HLLTC_H
#define HLLTC_H

#include "Sketch.h"

#define MAX(a,b) (a)>(b)?(a):(b)
#define MIN(a,b) (a)>(b)?(b):(a)

class HLLTC : public Sketch {
public:
    HLLTC(uint32_t);
    ~HLLTC();
    void insert(uint32_t, uint32_t, uint32_t);
    uint32_t estimate(uint32_t);

    void init() {
        memset(R, 0, sizeof(uint32_t) * m);
        B = 0;
    }
    
private:
    uint32_t m, K, B;
    double alpha;
    uint32_t* R;
    uint32_t hash_seed, num_leading_bit;
};

#endif //HLLTC_H
