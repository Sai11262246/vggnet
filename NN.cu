// includes, system
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <NN.h>
// includes, project
#include <cutil.h>

//#define NUM 10
// includes, kernels
#include <NN_kernel.cu>

////////////////////////////////////////////////////////////////////////////////
// declaration, forward

extern "C"
void computeGold(float*, const float*, const float*, unsigned int, unsigned int, unsigned int);
void NeuralNetwork();

unsigned g_verbose;
unsigned NUM;
////////////////////////////////////////////////////////////////////////////////
// Program main
////////////////////////////////////////////////////////////////////////////////
int
main(int argc, char** argv)
{
	int i, commandline_error;
	commandline_error = 0;
	g_verbose = 0;
	if (argc >= 2) {
		NUM = atoi(argv[1]);
		for (i=2; i < argc;i++) {
			if (argv[i][0] == '-') {
				switch (argv[i][1]) {
				case 'v': g_verbose = 1;
					break;
				default: commandline_error=1;
				}
			}
			else commandline_error=1;
		}
	} else commandline_error=1;

	if (commandline_error || !NUM) {
		printf("Usage: ./NN <NUM> [-v]\n");
		printf("where NUM is the number of images to process in parallel (up to 10000 for the t10k-images-idx3-ubyte database file) and -v is used to display approximately what each image looks like.\n");
		return 1;
	}

	NeuralNetwork();
    //CUT_EXIT(argc, argv);
}



InitGPUMemConvPart1(float *ConvLayer_1_1_Neurons_GPU, float *ConvLayer_1_1_Weights_GPU,float *ConvLayer_1_2_Neurons_GPU,float *ConvLayer_1_2_Weights_GPU)
{


	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_1_1_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART1*IMAGE_INPUT_PART1*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_1_1_Weights_GPU, sizeof(float)*CONVLAYER_1_1_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_1_2_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART1*IMAGE_INPUT_PART1*PART1_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_1_2_Weights_GPU, sizeof(float)*CONVLAYER_1_2_WEIGHTS));
}

InitGPUMemConvPart2(float *ConvLayer_2_1_Neurons_GPU, float *ConvLayer_2_1_Weights_GPU,float *ConvLayer_2_2_Neurons_GPU,float *ConvLayer_2_2_Weights_GPU);
{
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_2_1_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART2*IMAGE_INPUT_PART2*PART2_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_2_1_Weights_GPU, sizeof(float)*CONVLAYER_2_1_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_2_2_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART2*IMAGE_INPUT_PART2*PART2_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_2_2_Weights_GPU, sizeof(float)*CONVLAYER_2_2_WEIGHTS));
}

InitGPUMemConvPart3(float *ConvLayer_3_1_Neurons_GPU, float *ConvLayer_3_1_Weights_GPU,float *ConvLayer_3_2_Neurons_GPU,float *ConvLayer_3_2_Weights_GPU,float *ConvLayer_3_3_Neurons_GPU,float *ConvLayer_3_3_Weights_GPU);
{
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_3_1_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART3*IMAGE_INPUT_PART3*PART3_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_3_1_Weights_GPU, sizeof(float)*CONVLAYER_3_1_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_3_2_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART3*IMAGE_INPUT_PART3*PART3_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_3_2_Weights_GPU, sizeof(float)*CONVLAYER_3_2_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_3_3_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART3*IMAGE_INPUT_PART3*PART3_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_3_3_Weights_GPU, sizeof(float)*CONVLAYER_3_3_WEIGHTS));
}

InitGPUMemConvPart4(float *ConvLayer_4_1_Neurons_GPU, float *ConvLayer_4_1_Weights_GPU,float *ConvLayer_4_2_Neurons_GPU,float *ConvLayer_4_2_Weights_GPU,float *ConvLayer_4_3_Neurons_GPU,float *ConvLayer_4_3_Weights_GPU);
{
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_4_1_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART4*IMAGE_INPUT_PART4*PART4_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_4_1_Weights_GPU, sizeof(float)*CONVLAYER_4_1_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_4_2_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART4*IMAGE_INPUT_PART4*PART4_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_4_2_Weights_GPU, sizeof(float)*CONVLAYER_4_2_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_4_3_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART4*IMAGE_INPUT_PART4*PART4_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_4_3_Weights_GPU, sizeof(float)*CONVLAYER_4_3_WEIGHTS));
}


InitGPUMemConvPart5(float *ConvLayer_5_1_Neurons_GPU, float *ConvLayer_5_1_Weights_GPU,float *ConvLayer_5_2_Neurons_GPU,float *ConvLayer_5_2_Weights_GPU,float *ConvLayer_5_3_Neurons_GPU,float *ConvLayer_5_3_Weights_GPU);
{
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_5_1_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART5*IMAGE_INPUT_PART5*PART5_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_5_1_Weights_GPU, sizeof(float)*CONVLAYER_5_1_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_5_2_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART5*IMAGE_INPUT_PART5*PART5_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_5_2_Weights_GPU, sizeof(float)*CONVLAYER_5_2_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_5_3_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART5*IMAGE_INPUT_PART5*PART5_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &ConvLayer_5_3_Weights_GPU, sizeof(float)*CONVLAYER_5_3_WEIGHTS));
}
InitGPUMemFC(float *FCLayer_1_Neurons_GPU, float *FCLayer_1_Weights_GPU,float *FCLayer_2_Neurons_GPU, float *FCLayer_2_Weights_GPU,float *FCLayer_3_Neurons_GPU, float *FCLayer_3_Weights_GPU);
{
	CUDA_SAFE_CALL(cudaMalloc((void**) &FCLayer_1_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART5*IMAGE_INPUT_PART5*FC_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &FCLayer_1_Weights_GPU, sizeof(float)*FCLAYER_1_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &FCLayer_2_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART5*IMAGE_INPUT_PART5*FC_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &FCLayer_2_Weights_GPU, sizeof(float)*FCLAYER_2_WEIGHTS));

	CUDA_SAFE_CALL(cudaMalloc((void**) &FCLayer_3_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART5*IMAGE_INPUT_PART5*FC_CHANNELS*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &FCLayer_3_Weights_GPU, sizeof(float)*FCLAYER_3_WEIGHTS));
}
InitGPUMemSFM(float *SFMLayer_1_Neurons_GPU,float *SFMLayer_1_Weights_GPU);
{
	CUDA_SAFE_CALL(cudaMalloc((void**) &SFMLayer_1_Neurons_GPU, sizeof(float)*IMAGE_INPUT_PART5*IMAGE_INPUT_PART5*PART5_CHANNELS*NUM));
//	CUDA_SAFE_CALL(cudaMalloc((void**) &SFMLayer_1_Weights_GPU, sizeof(float)*CONVLAYER_4_1_WEIGHTS));
}
void InitGPUMem(float *Layer1_Neurons_GPU,float *Layer1_Weights_GPU,float *Layer2_Neurons_GPU,float *Layer2_Weights_GPU,float *Layer3_Neurons_GPU,float *Layer3_Weights_GPU,float *Layer4_Neurons_GPU,float *Layer4_Weights_GPU,float *Layer5_Neurons_GPU)
{

	InitGPUMemConvPart1();
	InitGPUMemConvPart2();
	InitGPUMemConvPart3();
	InitGPUMemConvPart4();
	InitGPUMemConvPart5();
	InitGPUMemFC();
	InitGPUMemSFM();
}
void InitHostMem(float *Layer1_Weights_CPU,float *Layer2_Weights_CPU,float *Layer3_Weights_CPU,float *Layer4_Weights_CPU)
{
	// initial layer 1 weight
	FILE * pFile1 = fopen ("data/lw1.wei","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<156;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	// initial layer 2 weight
	FILE * pFile2 = fopen ("data/lw2.wei","rb");
	if (pFile2 != NULL)
	{
		fread(Layer2_Weights_CPU,sizeof(float),7800,pFile2);
		fclose (pFile2);
	}
	// initial layer 3 weight
	FILE * pFile3 = fopen ("data/lw3.wei","rb");
	if (pFile3 != NULL)
	{
		fread(Layer3_Weights_CPU,sizeof(float),125100,pFile3);
		fclose (pFile3);
	}
	// initial layer 4 weight
	FILE * pFile4 = fopen ("data/lw4.wei","rb");
	if (pFile4 != NULL)
	{
		fread(Layer4_Weights_CPU,sizeof(float),1010,pFile4);
		fclose (pFile4);
	}
	if (!(pFile1 && pFile2 && pFile3 && pFile4))
	{
		printf("FAIL! INPUT WEIGHTS NOT FOUND!\n");
		exit(1);
	}
}

void InitHostMemPart1(float *ConvLayer_1_1_Weights_CPU,float *ConvLayer_1_2_Weights_CPU)
{
	// init layer 1_1 weight
	FILE * pFile1 = fopen ("data/conv1_1_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*INPUT_CHANNELS*PART1_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	// init layer 1_2 weight
	FILE * pFile1 = fopen ("data/conv1_2_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART1_CHANNELS*PART1_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

}

void InitHostMemPart2(float *ConvLayer_2_1_Weights_CPU,float *ConvLayer_2_2_Weights_CPU)
{
	// init layer 1_1 weight
	FILE * pFile1 = fopen ("data/conv2_1_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART1_CHANNELS*PART2_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	// init layer 1_2 weight
	FILE * pFile1 = fopen ("data/conv2_2_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART2_CHANNELS*PART2_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

}

void InitHostMemPart3(float *ConvLayer_3_1_Weights_CPU,float *ConvLayer_3_2_Weights_CPU,float *ConvLayer_3_3_Weights_CPU)
{

	FILE * pFile1 = fopen ("data/conv3_1_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART2_CHANNELS*PART3_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	// init layer 1_2 weight
	FILE * pFile1 = fopen ("data/conv3_2_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART3_CHANNELS*PART3_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	FILE * pFile1 = fopen ("data/conv3_3_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART3_CHANNELS*PART3_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

}

void InitHostMemPart4(float *ConvLayer_4_1_Weights_CPU,float *ConvLayer_4_2_Weights_CPU,float *ConvLayer_4_3_Weights_CPU)
{
	FILE * pFile1 = fopen ("data/conv4_1_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART3_CHANNELS*PART4_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	// init layer 1_2 weight
	FILE * pFile1 = fopen ("data/conv3_2_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART4_CHANNELS*PART4_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	FILE * pFile1 = fopen ("data/conv3_3_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART4_CHANNELS*PART4_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

}

void InitHostMemPart5(float *ConvLayer_5_1_Weights_CPU,float *ConvLayer_5_2_Weights_CPU,float *ConvLayer_5_3_Weights_CPU)
{

	FILE * pFile1 = fopen ("data/conv5_1_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART4_CHANNELS*PART5_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	// init layer 1_2 weight
	FILE * pFile1 = fopen ("data/conv5_2_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART5_CHANNELS*PART5_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}

	FILE * pFile1 = fopen ("data/conv5_3_v.txt","rb");
	if (pFile1 != NULL)
	{
		for(int i=0;i<KERNEL_SIZE*PART5_CHANNELS*PART5_CHANNELS;++i){
			fread(&(Layer1_Weights_CPU[i]),sizeof(float),1,pFile1);
			//printf("Layer1_Weights_CPU[%d]=%f\n", i, Layer1_Weights_CPU[i]);
		}
		fclose (pFile1);
	}
}

void InitHostMemPartFC(float *FCLayer_1_Weights_CPU,float *FCLayer_2_Weights_CPU)
{


}

void InitHostMemPartSF(float * SFMLayer_1_Weights_CPU)
{


}

int swapEndianInt( int bEnum )
{

    int lEnum;
    char *lE = (char*) &lEnum;
    char *bE = (char*) &bEnum;
    lE[0] = bE[3];
    lE[1] = bE[2];
    lE[2] = bE[1];
    lE[3] = bE[0];
    return lEnum;

}
void readIn(float *layer1)
{
	FILE *fp;
	unsigned int *foo;
	unsigned int i,j;
	foo = (unsigned int *) calloc(sizeof(unsigned int),1);
	//unsigned char image[29*29*NUM];
	unsigned char* image = (unsigned char*) malloc(29*29*NUM * sizeof(char));
	for (i=0;i<(29*29*NUM);i++) image[i]=0;
	fp=fopen("data/t10k-images-idx3-ubyte","rt");
	//fp=fopen("in.neu","rb");
	if(fp)
	{
		fread(foo,sizeof(int),1,fp);
		printf("magic number = %d\n", swapEndianInt(foo[0]));
		fread(foo,sizeof(int),1,fp);
		printf("number of items = %d\n", swapEndianInt(foo[0]));
		fread(foo,sizeof(int),1,fp);
		printf("number of rows = %d\n", swapEndianInt(foo[0]));
		fread(foo,sizeof(int),1,fp);
        printf("number of rows = %d\n", swapEndianInt(foo[0]));
		for (j=0;j<NUM;j++) {
			for (i=0;i<28;i++)
				fread((image+i*29+j*29*29),sizeof(char),28,fp);
		}
		//fread(layer1,sizeof(float),29*29,fp);
		fclose(fp);
		for (i=0;i<(29*29*NUM);i++)
			layer1[i] = (1.0 - (float) image[i]/256);
	}
	else
	{
		printf("FAIL! data/t10k-images-idx3-ubyte NOT FOUND!\n");
		exit(1);
	}
}

void output(double *final)
{
	int i;
	FILE *fp=0;
	fp=fopen("out.res","wb");
	if(fp)
	{
		//for(i=0;i<10;i++) {
		//	printf("output[%d] = %e\n", i, final[i]);
		//}
		fwrite(final,sizeof(double),10,fp);
		fclose(fp);
	}
}

void NeuralNetwork()
{
	int x,y;
	// initialise card and timer
	int deviceCount;
	CUDA_SAFE_CALL_NO_SYNC(cudaGetDeviceCount(&deviceCount));
	if (deviceCount == 0) {
		fprintf(stderr, "There is no device.\n");
		exit(EXIT_FAILURE);
	}
	int dev;
	for (dev = 0; dev < deviceCount; ++dev) {
		cudaDeviceProp deviceProp;
		CUDA_SAFE_CALL_NO_SYNC(cudaGetDeviceProperties(&deviceProp, dev));
		if (deviceProp.major >= 1)
			break;
	}
	if (dev == deviceCount) {
		fprintf(stderr, "There is no device supporting CUDA.\n");
		exit(EXIT_FAILURE);
	}
	else
		CUDA_SAFE_CALL(cudaSetDevice(dev));
	//float Layer1_Neurons_CPU[29*29*NUM];
	float *Layer1_Neurons_CPU = (float*) malloc (29*29*NUM * sizeof(float));
	 /*={
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,0,0,0,1,1,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};*/

	readIn(Layer1_Neurons_CPU);
	if (g_verbose) {
		for(y=0;y< 29*NUM;y++) {
			if(!(y%29)) printf("\n");
			for (x=0;x<29;x++) {
				if (Layer1_Neurons_CPU[y*29+x]<0.5) {
					printf("0");
				}
				else printf(" ");
				//printf("%d", (Layer1_Neurons_CPU[y*29+x]>0.5));
			}
			printf("\n");

		}
	}
	float *Layer1_Neurons_GPU;
	float Layer1_Weights_CPU[156];
	float *Layer1_Weights_GPU;

	float Layer2_Weights_CPU[7800];
	float *Layer2_Weights_GPU;
	float *Layer2_Neurons_GPU;

	float Layer3_Weights_CPU[125100];
	float *Layer3_Weights_GPU;
	float *Layer3_Neurons_GPU;

	float Layer4_Weights_CPU[1010];
	float *Layer4_Weights_GPU;
	float *Layer4_Neurons_GPU;

	//float Layer5_Neurons_CPU[10*NUM];//={0,0,0,0,0,0,0,0,0,0};
	float *Layer5_Neurons_CPU = (float*) malloc(10*NUM * sizeof(float));
	for (x=0;x<10*NUM;x++) Layer5_Neurons_CPU[x]=0;
	float *Layer5_Neurons_GPU;

	double *outputLayer;
	//unsigned int timer = 0;
	//float totaltime = 0.0f;
	//init input here
	InitHostMem(Layer1_Weights_CPU,Layer2_Weights_CPU,Layer3_Weights_CPU,Layer4_Weights_CPU);


	//allocate momory on Device
	//InitGPUMem(Layer1_Neurons_GPU,Layer1_Weights_GPU,Layer2_Neurons_GPU,Layer2_Weights_GPU,Layer3_Neurons_GPU,Layer3_Weights_GPU,Layer4_Neurons_GPU,Layer4_Weights_GPU,Layer5_Neurons_GPU);
	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer1_Neurons_GPU, sizeof(float)*29*29*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer1_Weights_GPU, sizeof(float)*156));

	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer2_Neurons_GPU, sizeof(float)*13*13*6*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer2_Weights_GPU, sizeof(float)*7800));

	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer3_Neurons_GPU, sizeof(float)*1250*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer3_Weights_GPU, sizeof(float)*125100));

	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer4_Neurons_GPU, sizeof(float)*100*NUM));
	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer4_Weights_GPU, sizeof(float)*1010));

	CUDA_SAFE_CALL(cudaMalloc((void**) &Layer5_Neurons_GPU, sizeof(float)*10*NUM));
	outputLayer = (double*)malloc(sizeof(double)*10*NUM);
	//init 29x29 handwritting array
	// already done in "initial"

	//copy from CPU to GPU
	CUDA_SAFE_CALL(cudaMemcpy(Layer1_Neurons_GPU,Layer1_Neurons_CPU, sizeof(float)*29*29*NUM, cudaMemcpyHostToDevice));
	CUDA_SAFE_CALL(cudaMemcpy(Layer1_Weights_GPU,Layer1_Weights_CPU, sizeof(float)*156, cudaMemcpyHostToDevice));
	CUDA_SAFE_CALL(cudaMemcpy(Layer2_Weights_GPU,Layer2_Weights_CPU, sizeof(float)*7800, cudaMemcpyHostToDevice));
	CUDA_SAFE_CALL(cudaMemcpy(Layer3_Weights_GPU,Layer3_Weights_CPU, sizeof(float)*125100, cudaMemcpyHostToDevice));
	CUDA_SAFE_CALL(cudaMemcpy(Layer4_Weights_GPU,Layer4_Weights_CPU, sizeof(float)*1010, cudaMemcpyHostToDevice));
	CUDA_SAFE_CALL(cudaMemcpy(Layer5_Neurons_GPU,Layer5_Neurons_CPU, sizeof(float)*10*NUM, cudaMemcpyHostToDevice));

	// CUT_SAFE_CALL(cutCreateTimer(&timer));
	// CUT_SAFE_CALL(cutStartTimer(timer));
	printf("NUM=%d\n", NUM);
	dim3 Layer1_Block(6,NUM,1);
	dim3 Layer1_Thread(13,13);
	executeFirstLayer<<<Layer1_Block,Layer1_Thread>>>(Layer1_Neurons_GPU,Layer1_Weights_GPU,Layer2_Neurons_GPU);

	dim3 Layer2_Block(50,NUM,1);
	dim3 Layer2_Thread(5,5);
	executeSecondLayer<<<Layer2_Block,Layer2_Thread>>>(Layer2_Neurons_GPU, Layer2_Weights_GPU,Layer3_Neurons_GPU);

	dim3 Layer3_Block(100,NUM,1);
	dim3 Layer3_Thread(1,1);
	executeThirdLayer<<<Layer3_Block,Layer3_Thread>>>(Layer3_Neurons_GPU, Layer3_Weights_GPU,Layer4_Neurons_GPU);

	dim3 Layer4_Block(10,NUM,1);
	dim3 Layer4_Thread(1,1);
	executeFourthLayer<<<Layer4_Block,Layer4_Thread>>>(Layer4_Neurons_GPU,Layer4_Weights_GPU,Layer5_Neurons_GPU);

	CUT_CHECK_ERROR("Kernel execution failed");

  //  CUT_SAFE_CALL(cutStopTimer(timer));

//	totaltime = cutGetTimerValue(timer);

	//copy from GPU to CPU
    CUDA_SAFE_CALL(cudaMemcpy(Layer5_Neurons_CPU,Layer5_Neurons_GPU, sizeof(float)*10*NUM, cudaMemcpyDeviceToHost));

    // stop and destroy timer

    //printf("Processing time: %f (ms) \n", totaltime);
	//  CUT_SAFE_CALL(cutDeleteTimer(timer));

	for(int a=0;a<10*NUM;a++)
	{
		//printf("output[%d]=%f\n", a, Layer5_Neurons_CPU[a]);
		outputLayer[a] = (double)Layer5_Neurons_CPU[a];
		if (!(a%10)) {
			if (a) printf("%d ", y);
			x=outputLayer[a];
			y=0;
		}
		if (outputLayer[a]>x) {
			x=outputLayer[a];
			y=a%10;
		}
	}
	printf("%d\n", y);
	output(outputLayer);

	/*
	//float Layer4_Neurons_CPU[100*NUM];
	float *Layer4_Neurons_CPU = (float*) malloc(100*NUM*sizeof(float));
	CUDA_SAFE_CALL(cudaMemcpy(Layer4_Neurons_CPU,Layer4_Neurons_GPU,sizeof(float)*100,cudaMemcpyDeviceToHost));
	FILE *fp=fopen("layer_4.neu","wb");
	fwrite(Layer4_Neurons_CPU,sizeof(float),100*NUM,fp);
	fclose(fp);

	//float Layer3_Neurons_CPU[50*5*5*NUM];
	float *Layer3_Neurons_CPU = (float*) malloc(50*5*5*NUM*sizeof(float));
	CUDA_SAFE_CALL(cudaMemcpy(Layer3_Neurons_CPU,Layer3_Neurons_GPU,sizeof(float)*50*5*5,cudaMemcpyDeviceToHost));
	fp=fopen("layer_3.neu","wb");
	fwrite(Layer3_Neurons_CPU,sizeof(float),50*5*5*NUM,fp);
	fclose(fp);

	//float Layer2_Neurons_CPU[13*13*6*NUM];
	float *Layer2_Neurons_CPU = (float*) malloc(13*13*6*NUM*sizeof(float));
	CUDA_SAFE_CALL(cudaMemcpy(Layer2_Neurons_CPU,Layer2_Neurons_GPU,sizeof(float)*13*13*6,cudaMemcpyDeviceToHost));
	fp=fopen("layer_2.neu","wb");
	fwrite(Layer2_Neurons_CPU,sizeof(float),13*13*6*NUM,fp);
	fclose(fp);

	fp=fopen("layer_1.neu","wb");
	fwrite(Layer1_Neurons_CPU,sizeof(float),29*29*NUM,fp);
	fclose(fp);    */

	exit(0);
}
