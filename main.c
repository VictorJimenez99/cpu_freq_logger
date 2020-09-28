#include <stdio.h>
#include <stdlib.h>
#include <sys/sysinfo.h>
#include <time.h>
#include <unistd.h>

int main(int argc, char** argv)
{
    FILE* cur_file = NULL;  // holds the current system file from where the
                            // frequency is beeing read.
    FILE* output = fopen("freq_log.csv", "w+");
    long core_freq = 0;  // s.e.

    short sps = 100;         // samples per second;
    long sampling_time = 3;  // seconds

    sampling_time *= sps;
    long sleep_time = 1000000 / sps;
    long const sleep_for = sleep_time;

    clock_t t;
    double time_exec;
    /*Get the number of cpus int the system*/
    unsigned int num_cpu = get_nprocs_conf();
    char path[100] = "";

    fprintf(output, "\"cpu_id\", \"freq\", \"log_id\"\n");

    /*For each second...*/
    for (int i = 0; i != sampling_time; i++)
    {
        /*Begin clock so we can measure and adjust the time*/
        t = clock();
        /*For each cpu core...*/
        for (unsigned int cpu = 0; cpu != num_cpu; cpu++)
        {
            /*log the frequency of the current core*/
            sprintf(path,
                    "/sys/devices/system/cpu/cpu%u/cpufreq/scaling_cur_freq",
                    cpu);
            cur_file = fopen(path, "r");
            if (!fscanf(cur_file, "%lu", &core_freq))
            {
                perror("reading error");
                exit(EXIT_FAILURE);
            }

            fprintf(output, "\"cpu%u\", %f, %d\n", cpu,
                    (double)core_freq / 1000000, i);
            fclose(cur_file);
        }
        /* processing
         * stop the clock and measure the elapsed time in the loop
         * sleep for the specified time minus the elapsed time
         * */
        sleep_time = sleep_for;
        t = clock() - t;
        time_exec = ((double)t) / CLOCKS_PER_SEC;
        sleep_time = (float)sleep_time - (time_exec * 1000000) - 200;
        if (sleep_time <= 0)
        {
            sleep_time = 0;
        }
        // fprintf(output, "exec_time = %fus\nsleep_time =%ldus\n",
        //        time_exec * 1000000, sleep_time);
        usleep(sleep_time);
    }
    /* clean_up */
    fclose(output);
    return 0;
}
