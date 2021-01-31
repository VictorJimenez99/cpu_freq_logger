#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/sysinfo.h>
#include <time.h>
#include <unistd.h>

#define SAMPLES_PER_SECOND 100

void signal_handler(int id);

bool interrupt_flag = false;
void watch_cpu(int argc, char **argv);

// this function can be set to run in one thread so in the future someone can add 
// or spawn new threads in order to watch ram and temperatures for example.
int main(int argc, char **argv) { watch_cpu(argc, argv); }

void signal_handler(int id) { interrupt_flag = true; }

void watch_cpu(int argc, char **argv)
{
    /*Variable declaration
     * -----------------------------------------------------*/
    int *cpu_files;  // it will hold every file descriptor
    FILE *output;    // it will hold the result of the computation
    unsigned int num_cpu;
    long const sleeping_time = 1000000 / (SAMPLES_PER_SECOND);

    char cpu_file_path[100];  // cpu_file descriptor
    char string[20];          // it will hold the cpu_freq as read from the file
    int read_bytes;           // number of bytes read

    clock_t time_zero;
    int time_elapsed;  // time since the beginning of the first sample

    clock_t stopwatch;      // These two variables will measure the time
    long computation_time;  // taken to process the loop

    unsigned long sample_id;

    /*
     * Beginning of the program
     * -------------------------------------*/

    printf("Freq_logger...\nGetting Data about Output Directory\n");
    if (argc < 2)
    {
        sprintf(cpu_file_path, "./freq_log.csv");
        printf("Solution created in current directory (freq_log.csv)\n");
    }
    else
    {
        sprintf(cpu_file_path, "%s/%s", argv[1], "freq_log.csv");
    }

    output = fopen(cpu_file_path, "w+");

    // bind interrupt signal
    signal(SIGINT, signal_handler);

    // get the number of cpu's available
    num_cpu = get_nprocs_conf();
    cpu_files = malloc(sizeof(int) * num_cpu);

    for (unsigned int i = 0; i != num_cpu; i++)
    {
        sprintf(cpu_file_path,
                "/sys/devices/system/cpu/cpu%u/cpufreq/scaling_cur_freq", i);
        printf("opening file: %s...         ", cpu_file_path);
        cpu_files[i] = open(cpu_file_path, O_RDONLY);
        printf("Success...\n");
    }

    time_zero = time(NULL);
    sample_id = 0;

    fprintf(output, "\"cpu_id\", \"freq\", \"sample_id\", \"time_passed\"\n");

    // synchronize time_zero
    while (time(NULL) - time_zero == 0)
    {
    }

    time_zero = time(NULL);

    /* Gather at most SAMPLES_PER_SECOND*/
    while (interrupt_flag == false)
    {
        stopwatch = clock();
        // For each CPU Core...
        for (int cpu = num_cpu - 1; cpu >= 0; cpu--)
        {
            read_bytes = pread(cpu_files[cpu], string, sizeof(char) * 20, 0);

            // validation
            if (read_bytes == -1)
            {
                printf("Something went wrong while gathering data ABORT\n");
                interrupt_flag = true;
                break;
            }

            // string[read_bytes] = '\n';
            string[read_bytes - 1] = '\0';

            time_elapsed = time(NULL) - time_zero;
            fprintf(output, "\"cpu%03d\", %s, %5lu , %4d\n", cpu, string,
                    sample_id, time_elapsed);
        }
        sample_id++;

        stopwatch = clock() - stopwatch;
        computation_time = 1000000 * ((double)stopwatch) / CLOCKS_PER_SEC;
        if (computation_time <= 0)
        {
            computation_time = sleeping_time;
        }
        usleep(sleeping_time - computation_time);
    }

    /*Clean up*/
    printf("\nCleaning up\n");
    for (int i = 0; i != num_cpu; i++)
    {
        close(cpu_files[i]);
    }

    printf("All files were closed successfully");
    free(cpu_files);
}

