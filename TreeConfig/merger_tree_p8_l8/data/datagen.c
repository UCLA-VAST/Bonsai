#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>


int main(int argc, char ** argv) {
    if (argc < 2) {
        printf("usage: ./datagen + #num_element in power of 2 + #seed\n");
        exit(1);
    }
    
    int pow = atoi(argv[1]);
    int seed = (argc>=3) ? atoi(argv[2]) : 1; // random gen seed

    const uint64_t n = ((uint64_t)1 << pow);
    printf("%" PRIx64 "\n", n);
    uint64_t i;

    uint32_t *buf;
    buf = (uint32_t *)malloc(n * sizeof(uint32_t));
    if (buf == NULL)
    {
      printf("unable to malloc the buffer\n");
      exit(1);
    }

    srand(seed);
    
    /******* generate data.txt *****/
    {
      char data_filename[80];
      strcpy(data_filename, "data_1^");
      strcat(data_filename, argv[1]);
      strcat(data_filename, ".txt");

      FILE *dat = fopen(data_filename, "w+");
        
      for (i=0; i<n; i++){
        /******* generate keys *****/
        buf[i] = rand();
	      fprintf(dat, "%08x\n", buf[i]);
	    }
  
      fclose(dat);
    }

    free(buf);
    
    return 0;
}
