#ifndef VHLL_H
#define VHLL_H
#include "Sketch.h"
#include "time.h"
#include "math.h"

#define MAX(a,b) (a)>(b)?(a):(b)

class HLL : public Sketch {
public:
    HLL(uint32_t);
    ~HLL();
    void insert(uint32_t, uint32_t, uint32_t);
    uint32_t estimate(uint32_t);
    void init() {
        memset(R, 0, sizeof(uint32_t) * m);
    }
    
private:
    uint32_t m;
    double alpha;
    uint32_t* R;
    uint32_t hash_seed, num_leading_bit;

};

#endif //VHLL_H
