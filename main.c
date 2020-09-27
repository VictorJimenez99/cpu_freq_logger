#include <stdio.h>
#include <stdlib.h>
#include <sys/sysinfo.h>
#include <unistd.h>
#include <time.h>

int main(int argc, char** argv)
{
    FILE* cur_file = NULL;
    long core_freq = 0;
    
    short sps = 100;//samples per second;
    long sampling_time = 30; //seconds

    sampling_time*=sps;
    long sleep_time = 1000000 / sps;

    clock_t t;
    double time_exec;
    unsigned int num_cpu = get_nprocs_conf();
    char path[100] = "";

    printf("\"cpu_id\", \"freq\", \"log_id\"\n");

    for (int i = 0; i !=sampling_time; i++)
    {
        t = clock();
        for (unsigned int cpu = 0; cpu != num_cpu; cpu++)
        {
            sprintf(path,
                    "/sys/devices/system/cpu/cpu%u/cpufreq/scaling_cur_freq",
                    cpu);
            cur_file = fopen(path, "r");
            if (!fscanf(cur_file, "%lu", &core_freq))
            {
                perror("reading error");
                exit(EXIT_FAILURE);
            }

            printf("\"cpu%u\", %f, %d\n", cpu,(double)core_freq / 1000000, i);
            fclose(cur_file);
        }
        t = clock() - t;
        time_exec = ((double)t)/CLOCKS_PER_SEC;
        usleep(sleep_time - time_exec - 1840);//1840 can be changed in order to adjust time taken,  
    }
    return 0;
}
