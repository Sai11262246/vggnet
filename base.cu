/*
 * Title: 2D Image Convolution on GPU by using Shared Memory and Constant Memory.
 *
 * Image Size: 2048 X 2048
 * Mask Size: 64 X 64
 * TILE_WIDTH 32
 *
 *
 * */
#include<stdio.h>
#include<cuda_runtime_api.h>
#include<cuda.h>
#include<stdlib.h>
#include<assert.h>
#include<base.h>
#include <time.h>
#define Mask_width  3
#define Mask_height 3
#define Mask_radius_x Mask_width/2
#define Mask_radius_y Mask_height/2
#define TILE_WIDTH 32 //16 X 16 TILE
#define B_x (TILE_WIDTH + Mask_width - 1)
#define B_y (TILE_WIDTH + Mask_height - 1)
#define clamp(x) (max(max((x), 0.0),x))
#define SIZE 224
#define max4(w,x,y,z) max(max(max(w,x),y),z)


typedef enum
{
  CONV_1 = 512,

}ch;
const int out = ch(CONV_1);

// Dense layer weights and bias
float *dense_1 = (float*)(malloc(dense[0][0]*dense[0][1] * sizeof(float)));
float *dense_2 = (float*)(malloc(dense[1][0]*dense[1][1] * sizeof(float)));
float *dense_3 = (float*)(malloc(dense[2][0]*dense[2][1] * sizeof(float)));
float *bias_1 = (float*)(malloc(dense[0][1] * sizeof(float)));
float *bias_2 = (float*)(malloc(dense[1][1] * sizeof(float)));
float *bias_3 = (float*)(malloc(dense[2][1] * sizeof(float)));
// Supporting functions go here

// Function to convert input image(.txt) to normalized BGR format

void softmax(float *prediction, int classes) {
	int i;
	float max_val, sum;
	max_val = prediction[0];
	for (i = 1; i < classes; i++) {
		if (prediction[i] > max_val)
			max_val = prediction[i];
	}
	sum = 0.0;
	for (i = 0; i < classes; i++) {
		prediction[i] = exp(prediction[i] - max_val);
		sum += prediction[i];
	}
	for (i = 0; i < classes; i++) {
		prediction[i] /= sum;
	}
}

// Fully connected layer definition
__global__ void fully_connected(float *I, const float* __restrict__ M, float *P,int channels, int width, int height,int numberofOutputChannels)
{
   __shared__ float F_ds[7][7];
   //__shared__ float W_ds[f_y][f_x];
   int k;

   //float acc[5] ={0};
   float acc[4096] ={0};

     for (k = 0; k < channels; k++)
     {

      F_ds[threadIdx.x][threadIdx.y] = I[(threadIdx.x + (blockIdx.x * TILE_WIDTH)) * (width * channels) + threadIdx.y * channels + k + blockIdx.y * (TILE_WIDTH) ];

        __syncthreads();


        if(threadIdx.y == 0 && threadIdx.x ==0 &&blockIdx.y == 0 && blockIdx.x == 0)
        {

          for(int z =0;z<numberofOutputChannels;z++)
          {
              for(int i =0; i< TILE_WIDTH; i++)
              {
                for(int j =0; j<TILE_WIDTH; j++)
                {
                     //printf("%.2f \t %.2f \t",F_ds[i][j],M[i*TILE_WIDTH + TILE_WIDTH*TILE_WIDTH*z+ numberofOutputChannels*k*TILE_WIDTH*TILE_WIDTH+ j]);

                    acc[z] += F_ds[i][j] * M[i*TILE_WIDTH + TILE_WIDTH*TILE_WIDTH*z+ numberofOutputChannels*k*TILE_WIDTH*TILE_WIDTH+ j];


                }

              //  printf("\n");
              }

          }


       }
       __syncthreads();
       //printf("done\n");

   }
   if(threadIdx.y == 0 && threadIdx.x ==0 &&blockIdx.y == 0 && blockIdx.x == 0)
   {
     for(int z =0;z<numberofOutputChannels;z++)
     {
        //printf("%.2f\t",acc[z]);
        P[z] = acc[z];
      }

   }


}

// Normalise the BGR weights
void normalizeBGR(float *hostInputImageData)
{
    float coef[3] = { 103.939, 116.779, 123.68 };
	//float *hostInputImageData = (float *) malloc(sizeof(float)*SIZE*SIZE*INPUT_CHANNELS);
	FILE *input = fopen("vol.txt", "r");
	float dval, val;
	int count =0;
    for(int i=0;i<SIZE*SIZE*INPUT_CHANNELS;i++)
    {
	    fscanf(input, "%f", &dval);
		//int n = (i+1);
	    if(count == 0)
		    val = dval - coef[count];
		if(count == 1)
		    val = dval - coef[count];
		if(count == 2)
		    val = dval -  coef[count];
		hostInputImageData[i]= val;
        count++;
        if(count == 3)
            count = 0;
    }
	FILE *results = fopen("results.txt", "w");
	for(int i=0;i<SIZE*SIZE*INPUT_CHANNELS;i++) {
				if(i % (SIZE*INPUT_CHANNELS) == 0 && i != 0)
					fprintf(results, "\n");
				fprintf(results, "%.5f\t",hostInputImageData[i]);
			}

	fclose(input);
	fclose(results);
}
//static unsigned int pos = 0;
FILE *weight = fopen("weights.txt", "r");

// Read the weights from weights.txt file and store
void readWeights(int level,float *wconv, float *bias){
	float dval;
	//int i, j, k, l, z;
	FILE *weight;
	FILE *conv;
    // Read the weights from text file
	weight = fopen("weights.txt", "r");
	conv = fopen("conv.txt", "w");
	if (weight == NULL) {
		printf("File weights absent\n");
		exit(1);
	}
//  int skip = level;
	// Memory allocation
	//float *wconv = (float *) malloc(sizeof(float)*layers[level][0]*layers[level][1]*layers[level][2]*layers[level][3]);
  if(level != 0)
  {
    for(int s =0; s<level; s++)
    {
      for(int j=1; j<=layers[s][0]*layers[s][1]; j++)
    	{
    		for(int k =0; k<CONV_SIZE * CONV_SIZE; k++)
    		{
    			fscanf(weight, "%f", &dval);
    			//*(wconv + j*CONV_SIZE * CONV_SIZE - 1 -k) = dval;
    		}
     	}

      for (int i = 0; i < layers[s][0]; i++) {
        fscanf(weight, "%f", &dval);
      }
    }
  }


	for(int j=1; j<=layers[level][0]*layers[level][1]; j++)
	{
		for(int k =0; k<CONV_SIZE * CONV_SIZE; k++)
		{
			fscanf(weight, "%f", &dval);
			*(wconv + j*CONV_SIZE * CONV_SIZE - 1 -k) = dval;
		}
	}

	for (int i = 0; i < layers[level][0]*layers[level][1]*layers[level][2]*layers[level][3]; i++) {
		fprintf(conv, "%.5f\t",wconv[i]);
	}

	FILE *bias1 = fopen("bias.txt", "w");

  int i =0;
  while(i<layers[level][0])
  {
  	fscanf(weight, "%f", &dval);
    bias[i] = dval;
    fprintf(bias1, "%.5f\t",bias[i]);
    i++;
  }

  if(level == 12)
  {
    int i,j;
  		printf("Read dense block %d weights\n", 0);
  		for (i = 0; i < dense[0][0]; i++) {
  			for (j = 0; j < dense[0][1]; j++) {
  				fscanf(weight, "%f", &dval);
  				*(dense_1 + i)= dval;
  			}
  		}
  		for (i = 0; i < dense[0][1]; i++) {
  			fscanf(weight, "%f", &dval);
  			*(bias_1+i) = dval;
  		}
      printf("Read dense block %d weights\n", 1);
      for (i = 0; i < dense[1][0]; i++) {
        for (j = 0; j < dense[1][1]; j++) {
          fscanf(weight, "%f", &dval);
          *(dense_2 + i)= dval;
        }
      }
      for (i = 0; i < dense[1][1]; i++) {
        fscanf(weight, "%f", &dval);
        *(bias_2+i) = dval;
      }
      printf("Read dense block %d weights\n", 2);
      for (i = 0; i < dense[2][0]; i++) {
        for (j = 0; j < dense[2][1]; j++) {
          fscanf(weight, "%f", &dval);
          *(dense_3 + i)= dval;
        }
      }
      for (i = 0; i < dense[2][1]; i++) {
        fscanf(weight, "%f", &dval);
        *(bias_3+i) = dval;
      }

  }
  //pos = ftell(weight);

    fclose(weight);
	fclose(bias1);
	fclose(conv);
}

// Maxpool layer definition
__global__ void maxpool(float *image, float * output,int number_of_channels, int image_height, int image_width,int blockwidth )
{

	__shared__ float Ns[32][32];


	for( int curr_channel=0; curr_channel<number_of_channels; curr_channel++)
	{

    Ns[threadIdx.x][threadIdx.y] = image[(threadIdx.y*number_of_channels +curr_channel +blockIdx.y * (blockwidth*number_of_channels)) + (threadIdx.x + blockIdx.x*blockwidth)* (image_width *number_of_channels) ];

    __syncthreads();

    if((threadIdx.x % 2 == 0) && (threadIdx.y %2 == 0))
    {
      output[blockIdx.y*(blockwidth/2) *number_of_channels+ (threadIdx.y/2) *number_of_channels+ curr_channel + (blockIdx.x * blockwidth/2 +threadIdx.x/2) * (image_width/2)*number_of_channels] = max4(Ns[threadIdx.x][threadIdx.y],Ns[threadIdx.x][threadIdx.y+1],Ns[threadIdx.x+1][threadIdx.y],Ns[threadIdx.x+1][threadIdx.y+1]);
    }
  }
}
// Fully connected layer
__global__ void fully1(float *I, const float* __restrict__ M, float *P,int channels,int numberofOutputChannels,float *b)
{
   __shared__ float F_ds[7][7];

   float acc[4096] ={0};

     for (int current_channel = 0; current_channel < channels; current_channel++)
     {

         F_ds[threadIdx.x][threadIdx.y] = I[(threadIdx.x + (blockIdx.x * TILE_WIDTH)) * (7 * channels) + threadIdx.y * channels + current_channel + blockIdx.y * (TILE_WIDTH) ]; //
        __syncthreads();


        if(threadIdx.y == 0 && threadIdx.x ==0)
        {

          for(int z =0;z<numberofOutputChannels;z++)
          {
              for(int i =0; i< 7; i++)
              {
                for(int j =0; j<7; j++)
                {
                   acc[z] += F_ds[i][j] * M[z*7*7*512 + current_channel*7*7 +i*7+j];
                }
            }

          }
       }

   }
   if(threadIdx.y == 0 && threadIdx.x ==0)
   {
     for(int z =0;z<numberofOutputChannels;z++)
     {

        P[z] = acc[z] +b[z];
     }

   }
}

__global__ void fully2(float *I, const float* __restrict__ M, float *P,int channels,int numberofOutputChannels,float *b)
{
   __shared__ float F_ds[4][32][32];

   float acc[4096] ={0};

    for(int i=0;i<4;i++)
    {
      F_ds[i][threadIdx.x][threadIdx.y]=I[threadIdx.y + threadIdx.x*32 +i*32*32];
    }

     __syncthreads();

     if(threadIdx.y == 0 && threadIdx.x ==0)
     {
        int i,j,k;

          for (int current_op_channel = 0; current_op_channel < numberofOutputChannels; current_op_channel++)
          {

                 for(int current_channel =0; current_channel<channels;current_channel++)
                 {
                      i=current_channel/1024;
                      j=((current_channel)/32)%32;
                      k=current_channel%32;
                      acc[current_op_channel]+=F_ds[i][j][k]*M[current_channel +current_op_channel*channels];
                 }
           }

         for(int z =0;z<numberofOutputChannels;z++)
         {
              P[z] = clamp(acc[z] + b[z]);
         }

      }
}

__global__ void fully3(float *I, const float* __restrict__ M, float *P,int channels,int numberofOutputChannels,float *b)
{
   __shared__ float F_ds[4][32][32];

   float acc[1000] ={0};

    for(int i=0;i<4;i++)
    {
      F_ds[i][threadIdx.x][threadIdx.y]=I[threadIdx.y + threadIdx.x*32 +i*32*32];
    }

     __syncthreads();

     if(threadIdx.y == 0 && threadIdx.x ==0)
     {
        int i,j,k;
         for (int current_op_channel = 0; current_op_channel < numberofOutputChannels; current_op_channel++)
         {

                for(int current_channel =0; current_channel<channels;current_channel++)
                {
                  i=current_channel/1024;
                  j=((current_channel)/32)%32;
                  k=current_channel%32;

                  acc[current_op_channel]+=F_ds[i][j][k]*M[current_channel +current_op_channel*channels];

                }
          }

         for(int z =0;z<numberofOutputChannels;z++)
         {
                       P[z] = clamp(acc[z] + b[z]);
         }

      }
}

// In first go, all of the threads will load the image pixels TILE_WIDTH * TILE_WIDTH on the second go first (TILE_WIDTH-mask radius)^2 threads will load the image.
__global__ void convolution(float *I, const float* __restrict__ M, float *P, float *b,int channels, int width, int height,int numberofOutputChannels)
{
   __shared__ float N_ds[B_y][B_x];
   int dest_Y;int dest_X;int src_X; int src_Y;int src;int dest;

   float accum[out] = {0};

   // for all the image channels
   for (int current_channel = 0; current_channel < channels; current_channel++)
   {


       dest = threadIdx.y * TILE_WIDTH + threadIdx.x,
      // The new index of thread in matrix with the boundary
      dest_Y = dest / B_x,
      dest_X = dest % B_x,

      src_Y = blockIdx.y * TILE_WIDTH + dest_Y - Mask_radius_x,
      src_X = blockIdx.x * TILE_WIDTH + dest_X - Mask_radius_y,
      src = (src_Y * width + src_X) * channels + current_channel;
      if (src_Y >= 0 && src_Y < height && src_X >= 0 && src_X < width)
         N_ds[dest_Y][dest_X] = I[src];
      else
         N_ds[dest_Y][dest_X] = 0.0;

        for (int iter=1; iter <= (B_x * B_y) / (TILE_WIDTH*TILE_WIDTH); iter++)
        {
           // Second batch loading
           dest = threadIdx.y * TILE_WIDTH + threadIdx.x + iter*(TILE_WIDTH * TILE_WIDTH);
            dest_Y = dest / B_x, dest_X = dest % B_x;
            src_Y  = blockIdx.y * TILE_WIDTH + dest_Y - Mask_radius_x;
            src_X = blockIdx.x * TILE_WIDTH + dest_X - Mask_radius_y;
            src = (src_Y * width + src_X) * channels + current_channel;
            if (dest_Y < B_y && dest_X < B_x)
            {
                if (src_Y >= 0 && src_Y < height && src_X >= 0 && src_X < width)
                    N_ds[dest_Y][dest_X] = I[src];
                else
                    N_ds[dest_Y][dest_X] = 0.0;
            }
        }
      __syncthreads();

      int y, x,z;
      for(z =0;z<numberofOutputChannels;z++)
        for (y = 0; y < Mask_width; y++)
           for (x = 0; x < Mask_width; x++)
              //                                                                                        navigation with input channel mask  inside mask navigate
              accum[z] += N_ds[threadIdx.y + y][threadIdx.x + x] * M[ ( z*Mask_width*Mask_width*channels + current_channel*Mask_width*Mask_width) + y * Mask_width + x];

      __syncthreads();
   }

   int y, x,z;
   y = blockIdx.y * TILE_WIDTH + threadIdx.y;
   x = blockIdx.x * TILE_WIDTH + threadIdx.x;
   if (y < height && x < width)
   // add bias and relu
      for(z =0;z<numberofOutputChannels;z++)
          P[(y * width*numberofOutputChannels + numberofOutputChannels*x)+z] = clamp(accum[z]  + b[z]);
}

float convolution_2D_OnHost(float * N,float * M,int width, int height,int i,int j,int numberofImageChannels ,int numberofOutputChannels);

int main()
{
     // Error code to check return values for CUDA calls
    cudaError_t err = cudaSuccess;


    err = cudaDeviceReset();
    if(err != cudaSuccess)
    {
      printf("failed to reset device \n");
    }

    float time_taken = 0.0f;
     cudaEvent_t start,stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    int mask_Rows=Mask_height; // Set it as per requirement of 64 X 32
    int mask_cols=Mask_width;

    int numberofImageChannels=3;
    int numberofOutputChannels = 64;
    int width_image=SIZE;
    int height_image=SIZE;

    float * host_Image_output;
    float * host_maxpool_output;
    float * device_image_input;
    float * deviceOutputImageData_1_1;
    float * device_maxpool_output;
  //  float * device_image_input;
    float * device_mask_weights;
    //float * outputImageOnHost;
    float * device_maxpool_input;
	float * bias;
	float * device_bias;
  float *biasDense = (float *) malloc(sizeof(float)*dense[0][1]);

    bias = (float *) malloc(sizeof(float)*layers[12][0]);
    /*************************** conv1-1 ******************************/
    int level = 0;
    // layer parameters
    numberofOutputChannels = layers[level][0];
    numberofImageChannels = layers[level][1];


    float * hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
    readWeights(level,hostMaskData, bias);


    //To store Memory

    host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
    //outputImageOnHost = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);

    float * hostInputImageData = (float*) malloc (sizeof (float) * SIZE * SIZE * INPUT_CHANNELS);
    normalizeBGR (hostInputImageData);

    //wbCheck(cudaMalloc((void **) &device_image_input, width_image * height_image * numberofImageChannels * sizeof(float)));
	err = cudaMalloc((void**)&device_image_input, width_image * height_image * numberofImageChannels * sizeof(float));
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device_image_input (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    err = cudaMalloc((void **) &deviceOutputImageData_1_1, width_image * height_image *numberofOutputChannels* sizeof(float));
	if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
	if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
	err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
	printf("Copy input data from the host memory to the CUDA device level 1_1\n");
    err = cudaMemcpy(device_image_input, hostInputImageData,
               width_image * height_image * numberofImageChannels * sizeof(float),
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMemcpy(device_mask_weights,
               hostMaskData,
               numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

	err = cudaMemcpy(device_bias, bias,
                sizeof(float)*layers[12][0],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    dim3 dimGrid(((width_image-1)/TILE_WIDTH)+1, ((height_image-1)/TILE_WIDTH)+1,1);
    dim3 dimBlock(TILE_WIDTH, TILE_WIDTH, 1);

    cudaEventRecord(start);

    convolution<<<dimGrid,dimBlock>>>(device_image_input, device_mask_weights, deviceOutputImageData_1_1, device_bias,
                                       numberofImageChannels, width_image, height_image,numberofOutputChannels);


    cudaMemcpy(host_Image_output,
              deviceOutputImageData_1_1,
              width_image * height_image * numberofOutputChannels * sizeof(float),
              cudaMemcpyDeviceToHost);

    cudaDeviceSynchronize();

    FILE *level0;
    if ((level0 = fopen("level0.txt","w")) == NULL){
        printf("Error! opening device file");
    exit(1);
    }
    for(int i=0;i<numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE;i++)
    {
        if(i>0 && (i%width_image==0))
        {
             fprintf(level0,"\n");

        }
      fprintf(level0, "%0.2f \t", *(hostMaskData+i));


    }
    fclose(level0);

   // Free conv_1_1 Memory
   free(hostMaskData);
   cudaFree(device_mask_weights);
   cudaFree(device_bias);
   free(host_Image_output);
   cudaFree(device_image_input);
   free(hostInputImageData);
     /*************************** conv1-1 end******************************/
     /*************************** conv1-2 start ******************************/
     level = 1;
     // layer parameters

     numberofOutputChannels = layers[level][0];
     numberofImageChannels = layers[level][1];

     float * deviceOutputImageData_1_2;

     hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
     host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);

     err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
      if (err != cudaSuccess)
      {
          fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
          exit(EXIT_FAILURE);
      }

     err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
     if (err != cudaSuccess)
     {
         fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
         exit(EXIT_FAILURE);
     }

    err = cudaMalloc((void **) &deviceOutputImageData_1_2, width_image * height_image *numberofOutputChannels* sizeof(float));
    if (err != cudaSuccess)
     {
         fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
         exit(EXIT_FAILURE);
     }
     readWeights(level,hostMaskData, bias);

     printf("Copy input data from the host memory to the CUDA device level 1_2\n");
     // Copy device bias
     err = cudaMemcpy(device_bias, bias,
                   sizeof(float)*layers[12][0],
                  cudaMemcpyHostToDevice);
       if (err != cudaSuccess)
       {
           fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
           exit(EXIT_FAILURE);
       }
      // Copy device mask
       err = cudaMemcpy(device_mask_weights,
                  hostMaskData,
                  numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
                  cudaMemcpyHostToDevice);

       if (err != cudaSuccess)
       {
           fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
           exit(EXIT_FAILURE);
       }

     convolution<<<dimGrid,dimBlock>>>(deviceOutputImageData_1_1, device_mask_weights, deviceOutputImageData_1_2, device_bias,
                                        numberofImageChannels, width_image, height_image,numberofOutputChannels);
     cudaMemcpy(host_Image_output,
              deviceOutputImageData_1_2,
              width_image * height_image * numberofOutputChannels * sizeof(float),
              cudaMemcpyDeviceToHost);
     cudaDeviceSynchronize();
      // Program exits if the file pointer returns NULL.
      FILE *out;
      if ((out = fopen("device_conv.txt","w")) == NULL){
          printf("Error! opening device file");
      exit(1);
      }
      for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
      {
      	  if(i>0 && (i%width_image==0))
      	  {
      	       fprintf(out,"\n");

      	  }
	      fprintf(out, "%0.2f \t", *(host_Image_output+i));


      }
      fclose(out);

      FILE *level1;
      if ((level1 = fopen("level1.txt","w")) == NULL){
          printf("Error! opening device file");
      exit(1);
      }
      for(int i=0;i<numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE;i++)
      {
          if(i>0 && (i%width_image==0))
          {
               fprintf(level1,"\n");

          }
        fprintf(level1, "%0.2f \t", *(hostMaskData+i));


      }
      fclose(level1);

      // Free conv_1_1 Memory
      free(hostMaskData);
      cudaFree(device_mask_weights);
      cudaFree(device_bias);
      free(host_Image_output);
      cudaFree(deviceOutputImageData_1_1);

     /*************************** conv1-2 end ******************************/
     /*************************** conv1-maxpool start ******************************/
     // Layer parameters

     host_maxpool_output = (float *) malloc(sizeof(float)*width_image/2*height_image/2*numberofOutputChannels);
     err = cudaMalloc((void**) &device_maxpool_output, width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float));
     if (err != cudaSuccess)
     {
         fprintf(stderr, "Failed to allocate device_image_input (error code %s)!\n", cudaGetErrorString(err));
         exit(EXIT_FAILURE);
     }
    err = cudaMalloc((void**) &device_maxpool_input, width_image * height_image * numberofOutputChannels * sizeof(float));
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to allocate device_image_input (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    err = cudaMemcpy(device_maxpool_input, host_Image_output,
               width_image * height_image * numberofOutputChannels * sizeof(float),
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    // image 224
    int blockwidth = 32;
    int number_blocks = width_image/blockwidth;
    dim3 dimGrid_m1(number_blocks,number_blocks,1);
    dim3 dimBlock_m1(blockwidth,blockwidth,1);
  maxpool<<<dimGrid_m1,dimBlock_m1>>>(deviceOutputImageData_1_2,device_maxpool_output ,numberofOutputChannels, height_image, width_image,blockwidth);


  cudaDeviceSynchronize();

  cudaMemcpy(host_maxpool_output,
             device_maxpool_output,
             width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float),
             cudaMemcpyDeviceToHost);

     FILE *mp;

     if ((mp = fopen("maxpooled.txt","w")) == NULL){
         printf("Error! opening host file");

         // Program exits if the file pointer returns NULL.
         exit(1);
     }

      for(int i=0;i<width_image/2*height_image/2*numberofOutputChannels;i++)
         {
              if(i>0 && (i%(width_image/2 * numberofOutputChannels)==0))
                 fprintf(mp,"\n");

           fprintf(mp, "%0.2f \t", *(host_maxpool_output+i));
         }

  //  cudaFree(device_maxpool_output);
    cudaFree(deviceOutputImageData_1_2);
    cudaFree(device_maxpool_input);

    free(host_maxpool_output);
/********************************conv_1 max end**********************************************/

/*******************************conv_2_1 start**********************************************/
// Layer parameters
  width_image /= 2;
  height_image /= 2;

  // Layer 4 (Convolution 64 -> 128)
  level = 2;
  numberofOutputChannels = layers[level][0];
  numberofImageChannels = layers[level][1];


  float * deviceOutputImageData_2_1;

  hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
  host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
  err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageData_2_1, width_image * height_image *numberofOutputChannels* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  readWeights(level,hostMaskData, bias);

  printf("Copy input data from the host memory to the CUDA device level 2_1\n");
  // Copy device bias
  err = cudaMemcpy(device_bias, bias,
                sizeof(float)*layers[12][0],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask
    err = cudaMemcpy(device_mask_weights,
               hostMaskData,
               numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    dim3 dimGrid_2(((width_image-1)/TILE_WIDTH)+1, ((height_image-1)/TILE_WIDTH)+1,1);
    dim3 dimBlock_2(TILE_WIDTH, TILE_WIDTH, 1);
  convolution<<<dimGrid_2,dimBlock_2>>>(device_maxpool_output, device_mask_weights, deviceOutputImageData_2_1, device_bias,
                                     numberofImageChannels, width_image, height_image,numberofOutputChannels);
  cudaMemcpy(host_Image_output,
           deviceOutputImageData_2_1,
           width_image * height_image * numberofOutputChannels * sizeof(float),
           cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *out2_1;
   if ((out2_1 = fopen("out2_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(out2_1,"\n");

       }
     fprintf(out2_1, "%0.2f \t", *(host_Image_output+i));


   }
   fclose(out2_1);

   FILE *level2_1;
   if ((level2_1 = fopen("level2_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(level2_1,"\n");

       }
     fprintf(level2_1, "%0.5f \t", *(hostMaskData+i));


   }
   fclose(level2_1);

   // Free conv_2_1 Memory
  free(hostMaskData);
   cudaFree(device_mask_weights);
   free(host_Image_output);
   cudaFree(device_bias);
   //cudaFree(device_maxpool_output);


/*******************************conv_2_1 end**********************************************/

/******************************conv_2_2 start********************************************/

  // Layer 4 (Convolution 128-> 128)
  level = 3;
  numberofOutputChannels = layers[level][0];
  numberofImageChannels = layers[level][1];


  float * deviceOutputImageData_2_2;

  hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
  host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
  err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageData_2_2, width_image * height_image *numberofOutputChannels* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  readWeights(level,hostMaskData, bias);

  printf("Copy input data from the host memory to the CUDA device level 2_1\n");
  // Copy device bias
  err = cudaMemcpy(device_bias, bias,
                sizeof(float)*layers[12][0],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask
    err = cudaMemcpy(device_mask_weights,
               hostMaskData,
               numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

  convolution<<<dimGrid_2,dimBlock_2>>>(deviceOutputImageData_2_1, device_mask_weights, deviceOutputImageData_2_2, device_bias,
                                     numberofImageChannels, width_image, height_image,numberofOutputChannels);
  cudaMemcpy(host_Image_output,
           deviceOutputImageData_2_2,
           width_image * height_image * numberofOutputChannels * sizeof(float),
           cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *out2_2;
   if ((out2_2 = fopen("out2_2.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(out2_2,"\n");

       }
     fprintf(out2_2, "%0.2f \t", *(host_Image_output+i));


   }
   fclose(out2_2);

   FILE *level2_2;
   if ((level2_2 = fopen("level2_2.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(level2_2,"\n");

       }
     fprintf(level2_2, "%0.5f \t", *(hostMaskData+i));


   }
   fclose(level2_2);

   // Free conv_2_1 Memory
  free(hostMaskData);
   cudaFree(device_mask_weights);
   cudaFree(device_bias);
   free(host_Image_output);
   cudaFree(deviceOutputImageData_2_1);

/******************************conv_2_2 end*********************************************/

/******************************max2 start**********************************************/
    float * deviceOutputMaxPooledData2;
     host_maxpool_output = (float *) malloc(sizeof(float)*width_image/2*height_image/2*numberofOutputChannels);
     err = cudaMalloc((void**) &deviceOutputMaxPooledData2, width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float));
     if (err != cudaSuccess)
     {
         fprintf(stderr, "Failed to allocate device_image_input (error code %s)!\n", cudaGetErrorString(err));
         exit(EXIT_FAILURE);
     }
     // image 112
     blockwidth = 16;
     number_blocks = width_image/blockwidth;
     dim3 dimGrid_m2(number_blocks,number_blocks,1);
     dim3 dimBlock_m2(blockwidth,blockwidth,1);

  maxpool<<<dimGrid_m2,dimBlock_m2>>>(deviceOutputImageData_2_2,deviceOutputMaxPooledData2 ,numberofOutputChannels, height_image, width_image,blockwidth);


  cudaDeviceSynchronize();

  cudaMemcpy(host_maxpool_output,
             deviceOutputMaxPooledData2,
             width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float),
             cudaMemcpyDeviceToHost);

     FILE *mp_2;

     if ((mp_2 = fopen("maxpooled2.txt","w")) == NULL){
         printf("Error! opening host file");

         // Program exits if the file pointer returns NULL.
         exit(1);
     }

      for(int i=0;i<width_image/2*height_image/2*numberofOutputChannels;i++)
         {
              if(i>0 && (i%(width_image/2 * numberofOutputChannels)==0))
                 fprintf(mp_2,"\n");

           fprintf(mp_2, "%0.2f \t", *(host_maxpool_output+i));
         }

  //  cudaFree(device_maxpool_output);
    cudaFree(deviceOutputImageData_2_2);

    //cudaFree(device_maxpool_input);
    free(host_maxpool_output);
/*****************************max2 end*************************************************/

/*****************************conv_3_1 start************************************************/
// Layer parameters
  width_image /= 2;
  height_image /= 2;

  // Layer 4 (Convolution 128 -> 256)
  level = 4;
  numberofOutputChannels = layers[level][0];
  numberofImageChannels = layers[level][1];


  float * deviceOutputImageData_3_1;

  hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
  float *hostOutputImageData1 = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);

  err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageData_3_1, width_image * height_image *numberofOutputChannels* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  readWeights(level,hostMaskData, bias);

  printf("Copy input data from the host memory to the CUDA device level 3_1\n");

  // Copy device bias
  err = cudaMemcpy(device_bias, bias,
                sizeof(float)*layers[12][0],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask
    err = cudaMemcpy(device_mask_weights,
               hostMaskData,
               numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    dim3 dimGrid_3(((width_image-1)/TILE_WIDTH)+1, ((height_image-1)/TILE_WIDTH)+1,1);
    dim3 dimBlock_3(TILE_WIDTH, TILE_WIDTH, 1);
    convolution<<<dimGrid_3,dimBlock_3>>>(deviceOutputMaxPooledData2, device_mask_weights, deviceOutputImageData_3_1, device_bias,
                                     numberofImageChannels, width_image, height_image,numberofOutputChannels);
   err =   cudaMemcpy(hostOutputImageData1,
           deviceOutputImageData_3_1,
           width_image * height_image * numberofOutputChannels * sizeof(float),
           cudaMemcpyDeviceToHost);

   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to copy 3.1 (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }
  cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *out3_1;
   if ((out3_1 = fopen("out3_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(out3_1,"\n");

       }
     fprintf(out3_1, "%0.2f \t", *(hostOutputImageData1+i));


   }
   fclose(out3_1);

   FILE *level3_1;
   if ((level3_1 = fopen("level3_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(level3_1,"\n");

       }
     fprintf(level3_1, "%0.5f \t", *(hostMaskData+i));


   }
   fclose(level3_1);

   // Free conv_2_1 Memory
  //free(hostMaskData);
   cudaFree(device_mask_weights);
   free(hostOutputImageData1);
   cudaFree(deviceOutputMaxPooledData2);
   cudaFree(device_bias);
// /*****************************conv_3_1 end************************************************/
//
// /****************************conv_3_2 start**********************************************/
// Layer 4 (Convolution 128-> 128)
level = 5;
numberofOutputChannels = layers[level][0];
numberofImageChannels = layers[level][1];

host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
float * deviceOutputImageData_3_2;

hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
//host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
 if (err != cudaSuccess)
 {
     fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
     exit(EXIT_FAILURE);
 }


err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}

err = cudaMalloc((void **) &deviceOutputImageData_3_2, width_image * height_image *numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}
readWeights(level,hostMaskData, bias);

printf("Copy input data from the host memory to the CUDA device level 3_2\n");
// Copy device bias
err = cudaMemcpy(device_bias, bias,
              sizeof(float)*layers[12][0],
             cudaMemcpyHostToDevice);
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
 // Copy device mask
  err = cudaMemcpy(device_mask_weights,
             hostMaskData,
             numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
             cudaMemcpyHostToDevice);

  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

convolution<<<dimGrid_3,dimBlock_3>>>(deviceOutputImageData_3_1, device_mask_weights, deviceOutputImageData_3_2, device_bias,
                                   numberofImageChannels, width_image, height_image,numberofOutputChannels);
cudaMemcpy(host_Image_output,
         deviceOutputImageData_3_2,
         width_image * height_image * numberofOutputChannels * sizeof(float),
         cudaMemcpyDeviceToHost);
cudaDeviceSynchronize();
 // Program exits if the file pointer returns NULL.
 FILE *out3_2;
 if ((out3_2 = fopen("out3_2.txt","w")) == NULL){
     printf("Error! opening device file");
 exit(1);
 }
 for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
 {
     if(i>0 && (i%width_image==0))
     {
          fprintf(out3_2,"\n");

     }
   fprintf(out3_2, "%0.2f \t", *(host_Image_output+i));


 }
 fclose(out3_2);

 // Free conv_2_1 Memory
free(hostMaskData);
 cudaFree(device_mask_weights);
 cudaFree(device_bias);
// free(host_Image_output);
 cudaFree(deviceOutputImageData_3_1);
/***************************conv_3_2 end************************************************/
/***************************conv_3_3 start************************************************/
// Layer 4 (Convolution 128-> 128)
level = 6;
numberofOutputChannels = layers[level][0];
numberofImageChannels = layers[level][1];


float * deviceOutputImageData_3_3;

hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);

err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
 if (err != cudaSuccess)
 {
     fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
     exit(EXIT_FAILURE);
 }


err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}

err = cudaMalloc((void **) &deviceOutputImageData_3_3, width_image * height_image *numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}
readWeights(level,hostMaskData, bias);

printf("Copy input data from the host memory to the CUDA device level 3_3\n");
// Copy device bias
err = cudaMemcpy(device_bias, bias,
              sizeof(float)*layers[12][0],
             cudaMemcpyHostToDevice);
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
 // Copy device mask
  err = cudaMemcpy(device_mask_weights,
             hostMaskData,
             numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
             cudaMemcpyHostToDevice);

  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

convolution<<<dimGrid_3,dimBlock_3>>>(deviceOutputImageData_3_2, device_mask_weights, deviceOutputImageData_3_3, device_bias,
                                   numberofImageChannels, width_image, height_image,numberofOutputChannels);
cudaMemcpy(host_Image_output,
         deviceOutputImageData_3_3,
         width_image * height_image * numberofOutputChannels * sizeof(float),
         cudaMemcpyDeviceToHost);
cudaDeviceSynchronize();
 // Program exits if the file pointer returns NULL.
 FILE *out3_3;
 if ((out3_3 = fopen("out3_2.txt","w")) == NULL){
     printf("Error! opening device file");
 exit(1);
 }
 for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
 {
     if(i>0 && (i%width_image==0))
     {
          fprintf(out3_3,"\n");

     }
   fprintf(out3_3, "%0.2f \t", *(host_Image_output+i));


 }
 fclose(out3_3);

 // Free conv_2_1 Memory
free(hostMaskData);
 cudaFree(device_mask_weights);
 cudaFree(device_bias);
free(host_Image_output);
 cudaFree(deviceOutputImageData_3_2);

/***************************conv_3_3 end************************************************/

/******************************max3 start**********************************************/
    float * deviceOutputMaxPooledData3;
     host_maxpool_output = (float *) malloc(sizeof(float)*width_image/2*height_image/2*numberofOutputChannels);
     err = cudaMalloc((void**) &deviceOutputMaxPooledData3, width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float));
     if (err != cudaSuccess)
     {
         fprintf(stderr, "Failed to allocate device_image_input (error code %s)!\n", cudaGetErrorString(err));
         exit(EXIT_FAILURE);
     }
     // image 56
     blockwidth = 8;
     number_blocks = width_image/blockwidth;
     dim3 dimGrid_m3(number_blocks,number_blocks,1);
     dim3 dimBlock_m3(blockwidth,blockwidth,1);

  maxpool<<<dimGrid_m3,dimBlock_m3>>>(deviceOutputImageData_3_3,deviceOutputMaxPooledData3 ,numberofOutputChannels, height_image, width_image, blockwidth);


  cudaDeviceSynchronize();

  cudaMemcpy(host_maxpool_output,
             deviceOutputMaxPooledData3,
             width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float),
             cudaMemcpyDeviceToHost);

     FILE *mp_3;

     if ((mp_3 = fopen("maxpooled2.txt","w")) == NULL){
         printf("Error! opening host file");

         // Program exits if the file pointer returns NULL.
         exit(1);
     }

      for(int i=0;i<width_image/2*height_image/2*numberofOutputChannels;i++)
         {
              if(i>0 && (i%(width_image/2 * numberofOutputChannels)==0))
                 fprintf(mp_3,"\n");

           fprintf(mp_3, "%0.2f \t", *(host_maxpool_output+i));
         }

  //  cudaFree(device_maxpool_output);
    cudaFree(deviceOutputImageData_3_3);

  //  cudaFree(device_maxpool_input);
    free(host_maxpool_output);
/*****************************max3 end*************************************************/

/*****************************conv_4_1 start************************************************/
// Layer parameters
 width_image /= 2;
  height_image /= 2;

  // Layer 4 (Convolution 128 -> 256)
  level = 7;
  numberofOutputChannels = layers[level][0];
  numberofImageChannels = layers[level][1];


  float * deviceOutputImageData_4_1;

  hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
  host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
  err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageData_4_1, width_image * height_image *numberofOutputChannels* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  readWeights(level,hostMaskData, bias);

  printf("Copy input data from the host memory to the CUDA device level 4_1\n");
  // Copy device bias
  err = cudaMemcpy(device_bias, bias,
                sizeof(float)*layers[12][0],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask
    err = cudaMemcpy(device_mask_weights,
               hostMaskData,
               numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    dim3 dimGrid_4(((width_image-1)/TILE_WIDTH)+1, ((height_image-1)/TILE_WIDTH)+1,1);
    dim3 dimBlock_4(TILE_WIDTH, TILE_WIDTH, 1);
    convolution<<<dimGrid_4,dimBlock_4>>>(deviceOutputMaxPooledData3, device_mask_weights, deviceOutputImageData_4_1, device_bias,
                                     numberofImageChannels, width_image, height_image,numberofOutputChannels);
   err =   cudaMemcpy(host_Image_output,
           deviceOutputImageData_4_1,
           width_image * height_image * numberofOutputChannels * sizeof(float),
           cudaMemcpyDeviceToHost);

  if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to copy 4.1 (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }
  cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *out4_1;
   if ((out4_1 = fopen("out4_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(out4_1,"\n");

       }
     fprintf(out4_1, "%0.2f \t", *(hostOutputImageData1+i));


   }
   fclose(out4_1);

   FILE *level4_1;
   if ((level4_1 = fopen("level4_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
 }

   for(int i=0;i<numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(level4_1,"\n");

       }
     fprintf(level4_1, "%0.5f \t", *(hostMaskData+i));


   }
   fclose(level4_1);

   // Free conv_2_1 Memory
  free(hostMaskData);
   cudaFree(device_mask_weights);
   cudaFree(device_bias);
   free(host_Image_output);
   cudaFree(deviceOutputMaxPooledData3);
/*****************************conv_4_1 end************************************************/

/****************************conv_4_2 start**********************************************/
// Layer 4 (Convolution 128-> 128)
level = 8;
numberofOutputChannels = layers[level][0];
numberofImageChannels = layers[level][1];


float * deviceOutputImageData_4_2;
  host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
//host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels

err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
 if (err != cudaSuccess)
 {
     fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
     exit(EXIT_FAILURE);
 }


err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}

err = cudaMalloc((void **) &deviceOutputImageData_4_2, width_image * height_image *numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}
readWeights(level,hostMaskData, bias);

printf("Copy input data from the host memory to the CUDA device level 4_2\n");
// Copy device bias
err = cudaMemcpy(device_bias, bias,
              sizeof(float)*layers[12][0],
             cudaMemcpyHostToDevice);
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
 // Copy device mask
  err = cudaMemcpy(device_mask_weights,
             hostMaskData,
             numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
             cudaMemcpyHostToDevice);

  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

convolution<<<dimGrid_4,dimBlock_4>>>(deviceOutputImageData_4_1, device_mask_weights, deviceOutputImageData_4_2, device_bias,
                                   numberofImageChannels, width_image, height_image,numberofOutputChannels);
cudaMemcpy(host_Image_output,
         deviceOutputImageData_4_2,
         width_image * height_image * numberofOutputChannels * sizeof(float),
         cudaMemcpyDeviceToHost);
cudaDeviceSynchronize();
 // Program exits if the file pointer returns NULL.
 FILE *out4_2;
 if ((out4_2 = fopen("out4_2.txt","w")) == NULL){
     printf("Error! opening device file");
 exit(1);
 }
 for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
 {
     if(i>0 && (i%width_image==0))
     {
          fprintf(out4_2,"\n");

     }
   fprintf(out4_2, "%0.2f \t", *(host_Image_output+i));


 }
 fclose(out4_2);

 // Free conv_2_1 Memory
free(hostMaskData);
 cudaFree(device_mask_weights);
 cudaFree(device_bias);
free(host_Image_output);
 cudaFree(deviceOutputImageData_4_1);
/***************************conv_4_2 end************************************************/

/***************************conv_4_3 start************************************************/
// Layer 4 (Convolution 128-> 128)
level = 9;
numberofOutputChannels = layers[level][0];
numberofImageChannels = layers[level][1];


float * deviceOutputImageData_4_3;

hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);



err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
 if (err != cudaSuccess)
 {
     fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
     exit(EXIT_FAILURE);
 }

err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}

err = cudaMalloc((void **) &deviceOutputImageData_4_3, width_image * height_image *numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}
readWeights(level,hostMaskData, bias);

printf("Copy input data from the host memory to the CUDA device level 4_3\n");
// Copy device bias
err = cudaMemcpy(device_bias, bias,
              sizeof(float)*layers[12][0],
             cudaMemcpyHostToDevice);
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
 // Copy device mask
  err = cudaMemcpy(device_mask_weights,
             hostMaskData,
             numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
             cudaMemcpyHostToDevice);

  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

convolution<<<dimGrid_4,dimBlock_4>>>(deviceOutputImageData_4_2, device_mask_weights, deviceOutputImageData_4_3, device_bias,
                                   numberofImageChannels, width_image, height_image,numberofOutputChannels);
cudaMemcpy(host_Image_output,
         deviceOutputImageData_4_3,
         width_image * height_image * numberofOutputChannels * sizeof(float),
         cudaMemcpyDeviceToHost);
cudaDeviceSynchronize();
 // Program exits if the file pointer returns NULL.
 FILE *out4_3;
 if ((out4_3 = fopen("out4_2.txt","w")) == NULL){
     printf("Error! opening device file");
 exit(1);
 }
 for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
 {
     if(i>0 && (i%width_image==0))
     {
          fprintf(out4_3,"\n");

     }
   fprintf(out4_3, "%0.2f \t", *(host_Image_output+i));


 }
 fclose(out4_3);

 // Free conv_2_1 Memory
free(hostMaskData);
 cudaFree(device_mask_weights);
 cudaFree(device_bias);
free(host_Image_output);
 cudaFree(deviceOutputImageData_4_2);
 //cudaFree(deviceOutputImageData_4_3);

/***************************conv_4_3 end************************************************/

/******************************max4 start**********************************************/
    float * deviceOutputMaxPooledData4;
     host_maxpool_output = (float *) malloc(sizeof(float)*width_image/2*height_image/2*numberofOutputChannels);
     //err = cudaMalloc((void**) &deviceOutputMaxPooledData4, width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float));
     err = cudaMalloc((void**) &deviceOutputMaxPooledData4, width_image/2 * height_image/2 * numberofOutputChannels  * sizeof(float));
     if (err != cudaSuccess)
     {
         fprintf(stderr, "Failed to allocate deviceOutputMaxPooledData4 (error code %s)!\n", cudaGetErrorString(err));
         exit(EXIT_FAILURE);
     }
     // image 28
     blockwidth = 4;
     number_blocks = width_image/blockwidth;
     dim3 dimGrid_m4(number_blocks,number_blocks,1);
     dim3 dimBlock_m4(blockwidth,blockwidth,1);
    maxpool<<<dimGrid_m4,dimBlock_m4>>>(deviceOutputImageData_4_3,deviceOutputMaxPooledData4 ,numberofOutputChannels, height_image, width_image, blockwidth);


  cudaDeviceSynchronize();

  cudaMemcpy(host_maxpool_output,
             deviceOutputMaxPooledData4,
             width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float),
             cudaMemcpyDeviceToHost);

     FILE *mp_4;

     if ((mp_4 = fopen("maxpooled4.txt","w")) == NULL){
         printf("Error! opening host file");

         // Program exits if the file pointer returns NULL.
         exit(1);
     }

      for(int i=0;i<width_image/2*height_image/2*numberofOutputChannels;i++)
         {
              if(i>0 && (i%(width_image/2 * numberofOutputChannels)==0))
                 fprintf(mp_4,"\n");

           fprintf(mp_4, "%0.2f \t", *(host_maxpool_output+i));
         }
  fclose(mp_4);
  //  cudaFree(device_maxpool_output);
    cudaFree(deviceOutputImageData_4_3);

  //  cudaFree(device_maxpool_input);
    free(host_maxpool_output);
/*****************************max4 end*************************************************/
/*****************************conv_5_1 start************************************************/
// Layer parameters
 width_image /= 2;
  height_image /= 2;

  // Layer 4 (Convolution 128 -> 256)
  level = 10;
  numberofOutputChannels = layers[level][0];
  numberofImageChannels = layers[level][1];


  float * deviceOutputImageData_5_1;

  hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
  host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
  err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageData_5_1, width_image * height_image *numberofOutputChannels* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  readWeights(level,hostMaskData, bias);

  printf("Copy input data from the host memory to the CUDA device level 5_1\n");
  // Copy device bias
  err = cudaMemcpy(device_bias, bias,
                sizeof(float)*layers[12][0],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask
    err = cudaMemcpy(device_mask_weights,
               hostMaskData,
               numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    dim3 dimGrid_5(((width_image-1)/TILE_WIDTH)+1, ((height_image-1)/TILE_WIDTH)+1,1);
    dim3 dimBlock_5(TILE_WIDTH, TILE_WIDTH, 1);
    convolution<<<dimGrid_5,dimBlock_5>>>(deviceOutputMaxPooledData4, device_mask_weights, deviceOutputImageData_5_1, device_bias,
                                     numberofImageChannels, width_image, height_image,numberofOutputChannels);
   err =   cudaMemcpy(host_Image_output,
           deviceOutputImageData_5_1,
           width_image * height_image * numberofOutputChannels * sizeof(float),
           cudaMemcpyDeviceToHost);

  if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to copy 5.1 (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }
  cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *out5_1;
   if ((out5_1 = fopen("out5_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(out5_1,"\n");

       }
     fprintf(out5_1, "%0.2f \t", *(host_Image_output+i));


   }

   fclose(out5_1);

   FILE *level5_1;
   if ((level5_1 = fopen("level5_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
 }

   for(int i=0;i<numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE;i++)
   {
       if(i>0 && (i%width_image==0))
       {
            fprintf(level5_1,"\n");

       }
     fprintf(level5_1, "%0.5f \t", *(hostMaskData+i));


   }
   fclose(level5_1);

   // Free conv_2_1 Memory
  free(hostMaskData);
   cudaFree(device_mask_weights);
   cudaFree(device_bias);
   free(host_Image_output);
   cudaFree(deviceOutputMaxPooledData4);
/*****************************conv_5_1 end************************************************/
/****************************conv_5_2 start**********************************************/
// Layer 4 (Convolution 128-> 128)
level = 11;
numberofOutputChannels = layers[level][0];
numberofImageChannels = layers[level][1];


float * deviceOutputImageData_5_2;
  host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);
hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
//host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels

err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
 if (err != cudaSuccess)
 {
     fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
     exit(EXIT_FAILURE);
 }


err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}

err = cudaMalloc((void **) &deviceOutputImageData_5_2, width_image * height_image *numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}
readWeights(level,hostMaskData, bias);

printf("Copy input data from the host memory to the CUDA device level 5_2\n");
// Copy device bias
err = cudaMemcpy(device_bias, bias,
              sizeof(float)*layers[12][0],
             cudaMemcpyHostToDevice);
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
 // Copy device mask
  err = cudaMemcpy(device_mask_weights,
             hostMaskData,
             numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
             cudaMemcpyHostToDevice);

  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

convolution<<<dimGrid_5,dimBlock_5>>>(deviceOutputImageData_5_1, device_mask_weights, deviceOutputImageData_5_2, device_bias,
                                   numberofImageChannels, width_image, height_image,numberofOutputChannels);
cudaMemcpy(host_Image_output,
         deviceOutputImageData_5_2,
         width_image * height_image * numberofOutputChannels * sizeof(float),
         cudaMemcpyDeviceToHost);
cudaDeviceSynchronize();
 // Program exits if the file pointer returns NULL.
 FILE *out5_2;
 if ((out5_2 = fopen("out5_2.txt","w")) == NULL){
     printf("Error! opening device file");
 exit(1);
 }
 for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
 {
     if(i>0 && (i%width_image==0))
     {
          fprintf(out5_2,"\n");

     }
   fprintf(out5_2, "%0.2f \t", *(host_Image_output+i));


 }
 fclose(out5_2);

 // Free conv_2_1 Memory
free(hostMaskData);
 cudaFree(device_mask_weights);
 cudaFree(device_bias);
free(host_Image_output);
 cudaFree(deviceOutputImageData_5_1);
/***************************conv_4_2 end************************************************/

/***************************conv_4_3 start************************************************/
// Layer 5 (Convolution 128-> 128)
level = 12;
numberofOutputChannels = layers[level][0];
numberofImageChannels = layers[level][1];


float * deviceOutputImageData_5_3;

hostMaskData = (float *) malloc(sizeof(float)*numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE);
host_Image_output = (float *) malloc(sizeof(float)*width_image*height_image*numberofOutputChannels);



err = cudaMalloc((void**)&device_bias, width_image * height_image * numberofImageChannels * sizeof(float));
 if (err != cudaSuccess)
 {
     fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
     exit(EXIT_FAILURE);
 }

err = cudaMalloc((void **) &device_mask_weights, mask_Rows * mask_cols * numberofImageChannels*numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}

err = cudaMalloc((void **) &deviceOutputImageData_5_3, width_image * height_image *numberofOutputChannels* sizeof(float));
if (err != cudaSuccess)
{
    fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}
readWeights(level,hostMaskData, bias);

printf("Copy input data from the host memory to the CUDA device level 5_3\n");
// Copy device bias
err = cudaMemcpy(device_bias, bias,
              sizeof(float)*layers[12][0],
             cudaMemcpyHostToDevice);
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
 // Copy device mask
  err = cudaMemcpy(device_mask_weights,
             hostMaskData,
             numberofOutputChannels*numberofImageChannels*CONV_SIZE*CONV_SIZE*sizeof(float),
             cudaMemcpyHostToDevice);

  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

convolution<<<dimGrid_5,dimBlock_5>>>(deviceOutputImageData_5_2, device_mask_weights, deviceOutputImageData_5_3, device_bias,
                                   numberofImageChannels, width_image, height_image,numberofOutputChannels);
cudaMemcpy(host_Image_output,
         deviceOutputImageData_5_3,
         width_image * height_image * numberofOutputChannels * sizeof(float),
         cudaMemcpyDeviceToHost);
cudaDeviceSynchronize();
 // Program exits if the file pointer returns NULL.
 FILE *out5_3;
 if ((out5_3 = fopen("out5_3.txt","w")) == NULL){
     printf("Error! opening device file");
 exit(1);
 }
 for(int i=0;i<width_image*height_image*numberofOutputChannels;i++)
 {
     if(i>0 && (i%width_image==0))
     {
          fprintf(out5_3,"\n");

     }
   fprintf(out5_3, "%0.2f \t", *(host_Image_output+i));


 }
 fclose(out5_3);

 // Free conv_2_1 Memory
free(hostMaskData);
 cudaFree(device_mask_weights);
 cudaFree(device_bias);
free(host_Image_output);
 cudaFree(deviceOutputImageData_5_2);


/***************************conv_5_3 end************************************************/
/******************************max5 start**********************************************/
    float * deviceOutputMaxPooledData5;
     host_maxpool_output = (float *) malloc(sizeof(float)*width_image/2*height_image/2*numberofOutputChannels);
     //err = cudaMalloc((void**) &deviceOutputMaxPooledData4, width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float));
     err = cudaMalloc((void**) &deviceOutputMaxPooledData5, width_image/2 * height_image/2 * numberofOutputChannels  * sizeof(float));
     if (err != cudaSuccess)
     {
         fprintf(stderr, "Failed to allocate deviceOutputMaxPooledData5 (error code %s)!\n", cudaGetErrorString(err));
         exit(EXIT_FAILURE);
     }
     // image 28
     blockwidth = 2;
     number_blocks = width_image/blockwidth;
     dim3 dimGrid_m5(number_blocks,number_blocks,1);
     dim3 dimBlock_m5(blockwidth,blockwidth,1);
    maxpool<<<dimGrid_m5,dimBlock_m5>>>(deviceOutputImageData_5_3,deviceOutputMaxPooledData5 ,numberofOutputChannels, height_image, width_image, blockwidth);


  cudaDeviceSynchronize();

  cudaMemcpy(host_maxpool_output,
             deviceOutputMaxPooledData4,
             width_image/2 * height_image/2 * numberofOutputChannels * sizeof(float),
             cudaMemcpyDeviceToHost);

     FILE *mp_5;

     if ((mp_5 = fopen("maxpooled5.txt","w")) == NULL){
         printf("Error! opening host file");

         // Program exits if the file pointer returns NULL.
         exit(1);
     }

      for(int i=0;i<width_image/2*height_image/2*numberofOutputChannels;i++)
         {
              if(i>0 && (i%(width_image/2 * numberofOutputChannels)==0))
                 fprintf(mp_5,"\n");

           fprintf(mp_5, "%0.2f \t", *(host_maxpool_output+i));
         }
  fclose(mp_5);
  //  cudaFree(device_maxpool_output);
    cudaFree(deviceOutputImageData_5_3);

  //  cudaFree(device_maxpool_input);
    free(host_maxpool_output);
/*****************************max5 end*************************************************/
/*****************************dense_1_1 start************************************************/
// Layer parameters
 width_image /= 2;
  height_image /= 2;

  // Layer 4 (Convolution 128 -> 256)
  level = 0;
  int input = dense[level][0];
  int output = dense[level][1];


  float * deviceOutputImageDataDense_1_1;

  //hostMaskData = (float *) malloc(sizeof(float)*output*input);
  host_Image_output = (float *) malloc(sizeof(float)*output);
  err = cudaMalloc((void**)&device_bias, output * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, output*input*sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageDataDense_1_1,output* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  //dense_weights(level,hostMaskData, biasDense);

  printf("Copy input data from the host memory to the CUDA device level FC 1_1\n");
  // Copy device bias
  err = cudaMemcpy(device_bias, bias_1,
                sizeof(float)*dense[0][1],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask

    err = cudaMemcpy(device_mask_weights,
               dense_1,
               output*input*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    dim3 dimGrid_fc1_1(1,1,1);
    dim3 dimBlock_fc1_1(width_image, width_image, 1);
  //  fully1(float *I, const float* __restrict__ M, float *P,int channels,int numberofOutputChannels)
//  __global__ void fully1(float *I, const float* __restrict__ M, float *P,int channels,int numberofOutputChannels)
//int channels, int width, int height,int numberofOutputChannels)

  fully1<<<dimGrid_fc1_1,dimBlock_fc1_1>>>(deviceOutputMaxPooledData5, device_mask_weights, deviceOutputImageDataDense_1_1,
                                   512,output,device_bias);
   err =   cudaMemcpy(host_Image_output,
           deviceOutputImageDataDense_1_1,
           output* sizeof(float),
           cudaMemcpyDeviceToHost);

  if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to copy f1_1 (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }
  cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *outf1_1;
   if ((outf1_1 = fopen("outf1_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<output;i++)
   {

     fprintf(outf1_1, "%0.2f \t", *(host_Image_output+i));


   }

   fclose(outf1_1);

   FILE *levelf1_1;
   if ((levelf1_1 = fopen("levelf1_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
 }

   for(int i=0;i<output;i++)
   {


     fprintf(levelf1_1, "%0.5f \t", *(hostMaskData+i));


   }
   fclose(levelf1_1);

   // Free conv_2_1 Memory
//  free(hostMaskData);
   cudaFree(device_mask_weights);
   cudaFree(device_bias);
   free(host_Image_output);
   cudaFree(deviceOutputMaxPooledData5);
/*****************************conv_5_1 end************************************************/
/*****************************dense_1_2 start************************************************/


  // Layer 4 (Convolution 128 -> 256)
  level = 1;
   input = dense[level][0];
   output = dense[level][1];


  float * deviceOutputImageDataDense_1_2;

//  hostMaskData = (float *) malloc(sizeof(float)*output*input);
  host_Image_output = (float *) malloc(sizeof(float)*output);
  err = cudaMalloc((void**)&device_bias, output * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, output*input*sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageDataDense_1_2,output* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  //dense_weights(level,hostMaskData, biasDense);

  printf("Copy input data from the host memory to the CUDA device level FC 1_2\n");
  // Copy device bias
  err = cudaMemcpy(device_bias, bias_2,
                sizeof(float)*dense[1][1],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask
    err = cudaMemcpy(device_mask_weights,
               dense_2,
               output*input*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    dim3 dimGrid_fc1_2(1,1,1);
    dim3 dimBlock_fc1_2(32, 32, 1);
  //  fully1(float *I, const float* __restrict__ M, float *P,int channels,int numberofOutputChannels)
    fully2<<<dimGrid_fc1_2,dimBlock_fc1_2>>>(deviceOutputImageDataDense_1_1, device_mask_weights, deviceOutputImageDataDense_1_2,
                                   4096,output, device_bias);
   err =   cudaMemcpy(host_Image_output,
           deviceOutputImageDataDense_1_2,
           output* sizeof(float),
           cudaMemcpyDeviceToHost);

  if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to copy FC 1.2 (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }
  cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *outf1_2;
   if ((outf1_2 = fopen("outf1_2.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<output;i++)
   {

     fprintf(outf1_2, "%0.2f \t", *(host_Image_output+i));


   }

   fclose(outf1_2);

   FILE *levelf1_2;
   if ((levelf1_2 = fopen("levelf1_1.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
 }

   for(int i=0;i<output;i++)
   {


     fprintf(levelf1_2, "%0.5f \t", *(hostMaskData+i));


   }
   fclose(levelf1_2);
    cudaEventRecord(stop);
   cudaEventSynchronize(stop);
   cudaEventElapsedTime(&time_taken,start,stop);
   int seconds = (time_taken/1000);
   int milli_seconds = ((int)time_taken%1000);
   printf("total elapsed time taken seconds is: %d milli-seconds: %d \n",seconds, milli_seconds );

   // Free conv_2_1 Memory
//  free(hostMaskData);
   cudaFree(device_mask_weights);
   cudaFree(device_bias);
   free(host_Image_output);
   cudaFree(deviceOutputImageDataDense_1_1);
/*****************************conv_5_1 end************************************************/

/*****************************dense_1_3 start************************************************/


  // Layer 4 (Convolution 128 -> 256)
  level = 2;
   input = dense[level][0];
   output = dense[level][1];


  float * deviceOutputImageDataDense_1_3;

  hostMaskData = (float *) malloc(sizeof(float)*output*input);
  host_Image_output = (float *) malloc(sizeof(float)*output);
  err = cudaMalloc((void**)&device_bias, output * sizeof(float));
   if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to allocate device_bias (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }


  err = cudaMalloc((void **) &device_mask_weights, output*input*sizeof(float));
  if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate device_mask_weights(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }

 err = cudaMalloc((void **) &deviceOutputImageDataDense_1_3,output* sizeof(float));
 if (err != cudaSuccess)
  {
      fprintf(stderr, "Failed to allocate deviceOutputImageData(error code %s)!\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
  }
  //dense_weights(level,hostMaskData, biasDense);

  printf("Copy input data from the host memory to the CUDA device level FC 1_3\n");
  // Copy device bias
  err = cudaMemcpy(device_bias, bias_3,
                sizeof(float)*dense[2][1],
               cudaMemcpyHostToDevice);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy input matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
   // Copy device mask

    err = cudaMemcpy(device_mask_weights,
               dense_3,
               output*input*sizeof(float),
               cudaMemcpyHostToDevice);

    if (err != cudaSuccess)
    {
        fprintf(stderr, "Failed to copy mask matrix from host to device (error code %s)!\n", cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

    dim3 dimGrid_fc1_3(1,1,1);
    dim3 dimBlock_fc1_3(32, 32, 1);
  //  fully1(float *I, const float* __restrict__ M, float *P,int channels,int numberofOutputChannels)
    fully3<<<dimGrid_fc1_3,dimBlock_fc1_3>>>(deviceOutputImageDataDense_1_2, device_mask_weights, deviceOutputImageDataDense_1_3,
                                   4096,output,device_bias);


   err =   cudaMemcpy(host_Image_output,
           deviceOutputImageDataDense_1_3,
           output* sizeof(float),
           cudaMemcpyDeviceToHost);

  if (err != cudaSuccess)
   {
       fprintf(stderr, "Failed to copy FC 1_3 (error code %s)!\n", cudaGetErrorString(err));
       exit(EXIT_FAILURE);
   }
   cudaDeviceSynchronize();
   // Program exits if the file pointer returns NULL.
   FILE *outf1_3;
   if ((outf1_3 = fopen("outf1_3.txt","w")) == NULL){
       printf("Error! opening device file");
   exit(1);
   }
   for(int i=0;i<output;i++)
   {

     fprintf(outf1_3, "%0.2f \t", *(host_Image_output+i));


   }

   fclose(outf1_3);


  softmax(host_Image_output, 1000);

  FILE *soft;
  if ((soft = fopen("softmax.txt","w")) == NULL){
      printf("Error! opening device file");
  exit(1);
}
 float max =0;
 int j=0;
  for(int i=0;i<1000;i++)
  {

    if(*(host_Image_output+i) > max)
    {
      max = *(host_Image_output+i);
      j =i;
    }
//    fprintf(soft, "%0.5f \t", *(host_Image_output+i));
  }
  fprintf(soft, "accuracy:%f class:%d \n", max,j);
  fclose(soft);


  // Free conv_2_1 Memory
 free(hostMaskData);
  cudaFree(device_mask_weights);
  cudaFree(device_bias);
  free(host_Image_output);
  cudaFree(deviceOutputImageDataDense_1_2);
  cudaFree(deviceOutputImageDataDense_1_3);
  free(dense_1);
  free(dense_2);
  free(dense_3);
  free(bias_1);
  free(bias_2);
  free(bias_3);

/*****************************dense1_3 end************************************************/



  printf("\n Number of Threads Per Block created in code: %d",TILE_WIDTH*TILE_WIDTH);
  printf("\n Number of Blocks Created :%d",(((width_image-1)/TILE_WIDTH)+1)*(((width_image-1)/TILE_WIDTH)+1));
  printf("No Error");
  return 0;
}
