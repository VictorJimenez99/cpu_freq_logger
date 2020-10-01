#include <stdio.h>
#include <stdlib.h>
#include <sys/sysinfo.h>
#include <time.h>
#include <unistd.h>

int main(int argc, char** argv)
{
    char path[100] = "";// this variable will be used two times
                        // once to hold the name of the folder and once to hold
                        // every cpu info file

    if(argc < 2)
    {
        sprintf(path, "./freq_log.csv" );
    }
    else
    {
        //argv[1] should hold the name of the Output Dir
        sprintf(path,"%s/%s", argv[1], "freq_log.csv");
    }

    FILE* cur_file = NULL;  // holds the current system file from where the
                            // frequency is being read.
    FILE* output = fopen(path, "w+");
    long core_freq = 0;     // s.e.

    short sps = 10;        // samples per second;
    long sampling_time = 120;// seconds

    long const sleep_for = 1000000 / sps;

    long sleep_time;        //internal logic

    clock_t t;
    double time_exec;
    /*Get the number of cpus int the system*/
    unsigned int num_cpu = get_nprocs_conf();
    long sample_id = 0;

    fprintf(output, "\"cpu_id\", \"freq\", \"sample_id\", \"time_passed\"\n");

    /*For each second...*/
    for (unsigned int second = 0; second != sampling_time; second++)
    {
        /*Take sps samples*/
        for (unsigned int sample = 0; sample != sps; sample++)
        {
            t = clock();
            /*For each cpu core...*/
            for (unsigned int cpu = 0; cpu != num_cpu; cpu++)
            {
                /*log the frequency of the current core*/
                sprintf(
                    path,
                    "/sys/devices/system/cpu/cpu%u/cpufreq/scaling_cur_freq",
                    cpu);
                cur_file = fopen(path, "r");
                if (!fscanf(cur_file, "%lu", &core_freq))
                {
                    perror("reading error");
                    exit(EXIT_FAILURE);
                }

                fprintf(output, "\"cpu%03u\", %f, %7ld, %5d\n", cpu,
                        (double)core_freq / 1000000, sample_id, second);
                fclose(cur_file);
            }
            sleep_time = sleep_for;
            t = clock() - t;
            time_exec = ((double)t) / CLOCKS_PER_SEC;
            sleep_time = (float)sleep_time - (time_exec * 1000000) - 250;
            if (sleep_time <= 0)
            {
                sleep_time = 0;
            }
            // fprintf(output, "exec_time = %fus\nsleep_time =%ldus\n",
            //        time_exec * 1000000, sleep_time);
            sample_id++;
            usleep(sleep_time);
        }
    }

    /* clean_up */
    fclose(output);
    return 0;
}
