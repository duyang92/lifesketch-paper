#include <math.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <ctime>
#include <string>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#ifdef _WIN32
#include <direct.h>  // For _mkdir on Windows
#else
#include <sys/stat.h>  // For mkdir on POSIX systems
#include <sys/types.h>
#endif
#include "./Headers/LifeSketch.h"
#include "./Headers/LifeSketchRE.h"
#include "./Headers/HLL.h"
#include "./Headers/HLLTC.h"
#include "./Headers/SHE_BM.h"
#define KEY_SIZE 16

using namespace std;

uint32_t outdated_time = 1.5e8;

bool create_directory(const std::string& dir) {
#ifdef _WIN32
    if (_mkdir(dir.c_str()) == 0 || errno == EEXIST) {
#else
    if (mkdir(dir.c_str(), 0777) == 0 || errno == EEXIST) {
#endif
        return true;
    } else {
        return false;
    }
}

ofstream outFile, outEstReal;
ofstream zg_log;

void process(uint32_t time_interval, Sketch* skt, string& name, bool record) {
    long long start_time = 0;
    uint32_t flowId;  // flow key
    uint32_t cur_time;
    uint32_t pre_time;
    uint32_t opt;
    string line, timestr, source, destination, sportstr, dportstr, optstr;

    string oneDataFilePath = "../data/2016.txt";
    cout << oneDataFilePath << endl;
    fstream fin(oneDataFilePath);
    unordered_map<int, unordered_set<uint32_t>> activeflowset;
    unordered_map<uint32_t, unordered_set<int>> flowintimes;
    int cursor = 0;

    using Clock = std::chrono::high_resolution_clock;
    using Duration = std::chrono::duration<double, std::micro>; 
    double total_insert_time_us = 0.0;                          
    int insert_count = 0;                                       

    double re = 0, qry_cnt = 0;
    uint32_t qry_interval = time_interval * 0.01;

    while (fin.is_open() && fin.peek() != EOF) {
        getline(fin, line);
        stringstream ss(line.c_str());
        ss >> timestr >> source >> destination >> sportstr >> dportstr >> optstr;
        flowId = stoul(source);
        if (cursor == 0) {
            start_time = stoull(timestr);
            cur_time = 0;
            pre_time = 0;
        } else {
            pre_time = cur_time;
            cur_time = (uint32_t)(stoull(timestr) - start_time);
        }
        opt = stoul(optstr.c_str());

        if (opt == 1) {
            activeflowset[cur_time].insert(flowId);
            flowintimes[flowId].insert(cur_time);
        } else {
            if (flowintimes.find(flowId) != flowintimes.end()) {
                unordered_set<int> tmp_times = flowintimes[flowId];
                for (auto iter1 = tmp_times.begin(); iter1 != tmp_times.end(); iter1++) {
                    activeflowset[*iter1].erase(flowId);
                }
            }
        }

        auto start_insert = Clock::now();
        skt->insert(flowId, cur_time, opt);
        auto end_insert = Clock::now();
        Duration insert_duration = end_insert - start_insert;
        total_insert_time_us += insert_duration.count();
        insert_count++;

        if (cursor % 10000000 == 0) {
            std::cout << "Processed " << cursor << " lines, current time: " << cur_time << " us\n";
        }

        for (int kk = 1; kk <= 6000; kk ++) {
            if (((uint64_t)cur_time >= (uint64_t)kk * time_interval) && ((uint64_t)pre_time < (uint64_t)kk * time_interval)) {
                skt->init();
                break;
            }
        }
        
        if (cur_time % qry_interval == 0 && pre_time != cur_time) {
            uint32_t real_card = 0;
            unordered_set<uint32_t> tmp_active_flows;
            // skt->show();
            uint32_t est_card = skt->estimate(cur_time);
            for (auto iter = activeflowset.begin(); iter != activeflowset.end(); iter++) {
                if (cur_time >= outdated_time) {
                    if (iter->first + outdated_time > cur_time) {
                        for (auto iiter = iter->second.begin(); iiter != iter->second.end(); iiter++)
                            tmp_active_flows.insert(*iiter);
                    }
                } else {
                    if (iter->first > 0) {
                        for (auto iiter = iter->second.begin(); iiter != iter->second.end(); iiter++)
                            tmp_active_flows.insert(*iiter);
                    }
                }
            }
            real_card = tmp_active_flows.size();

            if (real_card > 0) {
                qry_cnt++;
                re += abs((double)real_card - (double)est_card) / (double)real_card;
            }

            outFile << cur_time << " " << real_card << " " << est_card << endl;
        }
        cursor++;
    }
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        cerr << "Usage: " << argv[0] << " <algorithm_name> " << "<window_size>\n";
        return 1;
    }
    string target = argv[1];
    uint32_t cur_window = stoul(argv[2]);

    srand((int)time(0));

    vector<pair<string, function<Sketch*(double, double)>>> factory = {
        {"LifeSketchRE", [](double bits, double window) { double c = 8; double d = ceil(bits / (64 * c + 32)); return new LifeSketchRE(d, c, outdated_time); }},
        {"LifeSketch", [](double bits, double window) { double c = 8; double d = ceil(bits / (64 * c + 32)); return new LifeSketch(d, c, outdated_time); }},
        {"HLL",      [](double bits, double window) { return new HLL(ceil(bits / 5)); }},
        {"HLLTC",     [](double bits, double window) { return new HLLTC(ceil(bits / 4)); }},
        {"SHEBM",     [](double bits, double window) { return new SHE_BM(window, bits, 1, 64, 0, 0); }},
        {"LifeSketchHW",      [](double bits, double window) { double c = 2; double d = ceil(bits / (64 * c + 32)); return new LifeSketch(d, c, outdated_time); }},
    };

    auto it = find_if(factory.begin(), factory.end(), [&](auto& p) { return p.first == target.substr(0, target.find('_')); });
    if (it == factory.end()) {
        cerr << "Unknown algorithm: " << target << "\n";
        return 1;
    }
    // string name = it->first;
    string name = target;

    double windows[] = {1.5e8};
    windows[0] = cur_window;
    double mems[] = {8};

    string root_dir = "./results/";
    create_directory(root_dir);
    root_dir = "./results/" + to_string(cur_window) + "/";
    create_directory(root_dir);
    string dir = root_dir + name + "/";
    if (!create_directory(dir)) {
        cerr << "Failed to create directory: " << dir << "\n";
        return 1;
    }

    for (int ii = 0; ii <= 0; ii++) {
        int i = 0 + ii;
        for (double window : windows) {
            for (double memory : mems) {
                auto start = std::chrono::steady_clock::now();
                double bits = memory * 1024 * 8;
                Sketch* skt = it->second(bits, window);
                string output_name = dir + to_string(i) + ".txt";
                outFile.open(output_name);
                process(static_cast<uint32_t>(window), skt, name, 1);
                delete skt;
                outFile.close();
                auto end = std::chrono::steady_clock::now();
                std::chrono::duration<double> elapsed_seconds = end - start;
                std::cout << "Process time: " << elapsed_seconds.count() << "s\n";
            }
        }
    }
    return 0;
}