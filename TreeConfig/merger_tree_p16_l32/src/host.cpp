#include "xcl2.hpp"
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <cmath>
#include <vector>

#define WRITEOUTPUT

int main(int argc, char** argv)
{
    if (argc != 4) {
        std::cout << "Usage: " << argv[0] << " <XCLBIN File> + filepath + #num_element in power of 2" << std::endl;
        return EXIT_FAILURE;
    }

    std::string binaryFile = argv[1];
    std::string inFile = argv[2];
    std::string pow_specified = argv[3];

    struct timeval startTime, stopTime;
    double exec_time;
    double exec_bandwidth;

    double krnl_exec_time;
    double krnl_exec_bandwidth;

    uint64_t pow_num = std::stoul(pow_specified);

    const uint64_t number_of_words = ((uint64_t)1 << pow_num);
    const uint64_t number_of_readin_char = 9 * number_of_words - 1;
    const uint64_t total_words = number_of_words;

    int check_status = 0;

    // initial pass starts from 2^4 elements
    // sorted chunk increase 2^6 per each pass 
    uint8_t num_pass = (uint8_t) ceil((pow_num - 4) / 6.0);
    std::cout << "Number of pass is " << static_cast<uint16_t>(num_pass) << std::endl;

    //Allocate Memory in Host Memory
    std::vector<unsigned int,aligned_allocator<unsigned int>> h_input(total_words);
    std::vector<unsigned int,aligned_allocator<unsigned int>> h_output(total_words);

    // specify input & output files
    std::string outFile = "hw_output_1^" + pow_specified + ".txt";

    FILE *readFile;
    readFile = fopen(inFile.c_str(), "r");
    FILE *hardFile = fopen(outFile.c_str(), "w");
     
    unsigned char *buffer;
    buffer = (unsigned char *)malloc(number_of_readin_char * sizeof(unsigned char));

    // prepare the input data: cast from text into 32-bit data
    uint64_t i, j;
    fread(buffer, 1, number_of_readin_char, readFile);
    for (i = 0; i < number_of_words; i++) {
        h_input[i] = 0;
        for (j = 0; j < 8; j++) {
            h_input[i] = (h_input[i] << 4) + (buffer[9*i+j] > '9' ? (buffer[9*i+j]-87) : (buffer[9*i+j]-'0'));
        }
    }

    free(buffer);
    
    fclose(readFile);
        

    // Fill our data sets with pattern
    for(i = 0; i < total_words; i++) {
        h_output[i] = 0; 
    }
    
//OPENCL HOST CODE AREA START

    cl_int err;
    std::vector<cl::Device> devices = xcl::get_xil_devices();
    cl::Device device = devices[1];

    OCL_CHECK(err, cl::Context context({device}, NULL, NULL, NULL, &err));
    OCL_CHECK(err, cl::CommandQueue q(context, {device}, CL_QUEUE_PROFILING_ENABLE, &err));
    OCL_CHECK(err, std::string device_name = device.getInfo<CL_DEVICE_NAME>(&err));

    cl::Event krnlEvent;

    //Create Program and Kernel
    auto fileBuf = xcl::read_binary_file(binaryFile);
    cl::Program::Binaries bins{{fileBuf.data(), fileBuf.size()}};
    devices.resize(1);
    OCL_CHECK(err, cl::Program program(context, {device}, bins, NULL, &err));
    OCL_CHECK(err, cl::Kernel krnl_sorter(program,"merger_tree_p16_l32_i64_mb", &err));

    // gettimeofday(&startTime, NULL);
    // Allocate Buffer in Global Memory
    size_t total_input_bytes = sizeof(unsigned int) * (total_words);
    std::cout << "Total input bytes " << total_input_bytes << '\n';
    OCL_CHECK(err, cl::Buffer buffer00   (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_WRITE,
            total_input_bytes, h_input.data(), &err));
    
    //size_t total_output_bytes = sizeof(unsigned int) * (total_words + actual_offset);
    size_t total_output_bytes = sizeof(unsigned int) * (total_words);
    std::cout << "Total output bytes " << total_output_bytes << '\n';
    OCL_CHECK(err, cl::Buffer buffer01   (context,CL_MEM_USE_HOST_PTR | CL_MEM_READ_WRITE,
           total_output_bytes, h_output.data(), &err));

    
    //Set the Kernel Arguments
    uint64_t size = sizeof(unsigned int) * total_words;

    int nargs=0;
    OCL_CHECK(err, err = krnl_sorter.setArg(nargs++,size));
    OCL_CHECK(err, err = krnl_sorter.setArg(nargs++,num_pass));
    OCL_CHECK(err, err = krnl_sorter.setArg(nargs++,buffer00));
    OCL_CHECK(err, err = krnl_sorter.setArg(nargs++,buffer01));

    uint64_t krnl_start, krnl_end;

    gettimeofday(&startTime, NULL);
    //Copy input data to device global memory
    OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer00},0/* 0 means from host*/));
    OCL_CHECK(err, err = q.finish());
    std::cout << "Copy data from host to FPGA is done!" << std::endl;
    
#ifdef CHECK_INPUT
    FILE *checkFile = fopen("checkFile.txt", "w");

    // clear the input buffers
    for(i = 0; i < total_words; i++) {
        h_input[i] = 0;
    }

    OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer00},CL_MIGRATE_MEM_OBJECT_HOST));
    OCL_CHECK(err, err = q.finish());

    // write the input buffers to files
    //for(i = 0; i < total_words + actual_offset; i++) {
    for(i = 0; i < total_words; i++) {
        fprintf(checkFile, "%08x\n", h_input[i]);
    }

    fclose(checkFile);
#endif

    //Launch the Kernel
    OCL_CHECK(err, err = q.enqueueTask(krnl_sorter, NULL, &krnlEvent));
    clWaitForEvents(1, (const cl_event*) &krnlEvent);
    std::cout << "Kernel execution is done!" << std::endl;

    //Copy Result from Device Global Memory to Host Local Memory
    if (num_pass % 2 == 1)
    {
        OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer01},CL_MIGRATE_MEM_OBJECT_HOST));
    }
    else
    {
        OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer00},CL_MIGRATE_MEM_OBJECT_HOST));
    }
    OCL_CHECK(err, err = q.finish());
    std::cout << "Copy data from FPGA to host is done!" << std::endl;

    gettimeofday(&stopTime, NULL);

    krnlEvent.getProfilingInfo(CL_PROFILING_COMMAND_START, &krnl_start);
    krnlEvent.getProfilingInfo(CL_PROFILING_COMMAND_END, &krnl_end);
//OPENCL HOST CODE AREA END

    std::cout << "Kernel execution stopped here" << std::endl;

#ifdef WRITEOUTPUT
    // store the hardware sorted input data into text file
    if (num_pass % 2 == 1)
    {
    	for(i = 0; i < (total_words); i++) {
            fprintf(hardFile, "%08x\n", h_output[i]);
    	}
    }
    else
    {
	for(i = 0; i < (total_words); i++) {
	    fprintf(hardFile, "%08x\n", h_input[i]);
        }
    }
#endif 
    fclose(hardFile);


    // Debug
#ifdef DEBUG
    FILE *outFile = fopen("readOutFile.txt", "w");

    // clear the input buffers
    for(i = 0; i < total_input_words; i++) {
        h_input[i] = 0;
    }

    OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer00},CL_MIGRATE_MEM_OBJECT_HOST));
    OCL_CHECK(err, err = q.finish());

    // write the input buffers to files
    for(i = 0; i < total_words; i++) {
    	fprintf(outFile, "%08x\n", h_input[i]);
    }

    fclose(outFile);

#endif

    // Check Results
    if (num_pass % 2 == 1)
    {
        for (i = 0; i < total_words - 1; i++) {
            if(h_output[i] > h_output[i+1]) {
                printf("%ld element %08x is larger than %ld element %08x\n", i+1, h_output[i], i+2, h_output[i+1]);
                check_status = 1;
                break;
            }
        }
    }
    else
    {
        for (i = 0; i < total_words - 1; i++) {
            if(h_input[i] > h_input[i+1]) {
                printf("%ld element %08x is larger than %ld element %08x\n", i+1, h_input[i], i+2, h_input[i+1]);
                check_status = 1;
                break;
            }
        }
    }

    std::cout << "TEST " << (check_status ? "FAILED" : "PASSED") << std::endl;

    krnl_exec_time = (krnl_end - krnl_start) / 1000000000.0;
    std::cout << "kernel execution time is " << krnl_exec_time << "s\n";
    krnl_exec_bandwidth = (total_words * sizeof(unsigned int) / 1000000000.0) / krnl_exec_time; 
    std::cout << "Kernel performance is " << krnl_exec_bandwidth << "GB/s" << std::endl;

    exec_time = (stopTime.tv_usec - startTime.tv_usec) / 1000000.0 + (stopTime.tv_sec - startTime.tv_sec);
    std::cout << "Execution time is " << exec_time << "s\n";
    exec_bandwidth = (total_words * sizeof(unsigned int) / 1000000000.0) / exec_time;
    std::cout << "End-to-end bandwidth is " << exec_bandwidth << "GB/s" << std::endl;


    return (check_status ? EXIT_FAILURE :  EXIT_SUCCESS);
}

