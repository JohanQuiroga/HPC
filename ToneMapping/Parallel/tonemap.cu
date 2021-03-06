#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <string>
#include <time.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include "lib/helpers.h"
#include "lib/tonemap.cuh"

#define BLOCK_SIZE 32
#define BLUE 0
#define GREEN 1
#define RED 2

using namespace cv;

float task(std::string image_name, std::string images_path, std::string dst_path, std::string tmo, int blockSize,
           float f_stop, float gamma, float q, float k, float b, float ld_max)
{
	float *h_ImageData, *h_ImageOut;
	std::string image_out_name;
	Mat hdr, ldr;
	int width, height, channels, sizeImage;

	std::string path = images_path + "/" + image_name;

	hdr = imread(path.c_str(), -1);

	if(!hdr.data) {
		printf("No image Data \n");
		return EXIT_FAILURE;
//        return -1;
	}

	if(hdr.empty()) {
		printf("Couldn't find or open the image...\n");
		return EXIT_FAILURE;
//        return -1;
	}

	width = hdr.cols;
	height = hdr.rows;
	channels = hdr.channels();
	sizeImage = sizeof(float)*width*height*channels;

	h_ImageData = (float *)hdr.data;
	h_ImageOut = (float *) malloc (sizeImage);
	float elapsed_time = 0.0;

	if(tmo == "log") {
		elapsed_time = log_tonemap(h_ImageData, h_ImageOut, width, height, channels, k, q, blockSize, sizeImage);
	} else if(tmo == "gamma") {
		elapsed_time = gamma_tonemap(h_ImageData, h_ImageOut, width, height, channels, f_stop, gamma, blockSize,
		                             sizeImage);
	} else {
		elapsed_time = adaptive_log_tonemap(h_ImageData, h_ImageOut, width, height, channels, b, ld_max, blockSize, sizeImage);
	}

	ldr.create(height, width, CV_32FC3);
	ldr.data = (unsigned char *)h_ImageOut;
	ldr.convertTo(ldr, CV_8UC3, 255);
	image_out_name = dst_path + "/" + change_image_extension(image_name);
	imwrite(image_out_name.c_str(), ldr);

	free(h_ImageOut);

	return elapsed_time;
}

void Usage()
{
	printf("Usage: ./tonemap <images_src> <results_dst> <output_separator> <TMO>(log/gamma/adap_log)\n");
	printf("If TMO = log, add: <k> <q>\n");
	printf("If TMO = gamma, add: <gamma> <f_stop>\n");
	printf("If TMO = adap_log, add: <b> <ld_max>\n");
}

int main(int argc, char** argv)
{
	float f_stop=0.0, gamma=0.0, q=0.0, k=0.0, b=1.0, ld_max=0.0;

	if(argc == 1 || argc < 5) {
		Usage();
		return EXIT_FAILURE;
	}
	std::string images_path(argv[1]);
	std::string dst_path(argv[2]);
	std::string separator(argv[3]);
	std::string tmo(argv[4]);

	if(tmo == "log") {
		if(argc != 7) {
			Usage();
			return EXIT_FAILURE;
		}
		k = atof(argv[5]);
		q = atof(argv[6]);
	} else if(tmo == "gamma") {
		if(argc != 7) {
			Usage();
			return EXIT_FAILURE;
		}
		gamma = atof(argv[5]);
		f_stop = atof(argv[6]);
	} else if(tmo == "adap_log") {
		if(argc != 7) {
			Usage();
			return EXIT_FAILURE;
		}
		b = atof(argv[5]);
		ld_max = atof(argv[6]);
	} else {
		Usage();
		return EXIT_FAILURE;
	}

	clock_t start, end;
	double batch_time;
	std::vector<std::string> files;
	read_files(files, images_path);
	int blockSize = BLOCK_SIZE;

	start = clock();
	while(!files.empty()) {
		float elapsed_time = 0.0;
		std::string file_name = files.back();
		elapsed_time = task(file_name, images_path, dst_path, tmo, blockSize, f_stop, gamma, q, k, b, ld_max);
		printTime(file_name, elapsed_time, separator);
		files.pop_back();
	}
	end = clock();
	batch_time = ((double)(end - start))/CLOCKS_PER_SEC;
	printTime("batch time", batch_time, separator);

	return EXIT_SUCCESS;
}
