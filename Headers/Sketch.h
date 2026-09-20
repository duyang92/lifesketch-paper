#ifndef SKETCH_H
#define SKETCH_H
#include <cstdint>
#include <cstring>
#include "MurmurHash3.h"
class Sketch {
public:
    virtual void insert(uint32_t, uint32_t, uint32_t) = 0;
    virtual uint32_t estimate(uint32_t) = 0;
    virtual void init() = 0;
};

#endif //SKETCH_H