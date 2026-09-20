#!/bin/bash

TARGET_NAME="main"
MAIN_FILE="main.cpp"

mkdir -p build
cd build

cmake .. -DTARGET_NAME=${TARGET_NAME} -DMAIN_FILE=${MAIN_FILE}
make -j$(nproc)

algs=("LifeSketchRE" "LifeSketch" "LifeSketchHW" "HLLTC" "HLL" "SHEBM")
windows=("120000000")
runs=1

echo "running ${TARGET_NAME} ${runs}"

for alg in "${algs[@]}"; do
    for window in "${windows[@]}"; do
        for i in $(seq 1 $runs); do
            alg_name="${alg}_${i}"
            log_file="${TARGET_NAME}_${alg}_${window}_${i}.log"
            echo ">>> Start：${TARGET_NAME} ${alg_name} ${window}"
            sleep 1
            ./${TARGET_NAME} "$alg_name" "$window" > "$log_file" 2>&1 &
        done
    done
done

wait

echo "All algorithms finished."