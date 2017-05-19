#include <stdio.h>
#include <cuda.h>
//#include <cv.h>
//#include <highgui.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/photo.hpp>
#include <vector>
#include <string>

#define BLUE 0
#define GREEN 1
#define RED 2

using namespace cv;

std::string type2str(int type) {
  std::string r;

  uchar depth = type & CV_MAT_DEPTH_MASK;
  uchar chans = 1 + (type >> CV_CN_SHIFT);

  switch ( depth ) {
    case CV_8U:  r = "8U"; break;
    case CV_8S:  r = "8S"; break;
    case CV_16U: r = "16U"; break;
    case CV_16S: r = "16S"; break;
    case CV_32S: r = "32S"; break;
    case CV_32F: r = "32F"; break;
    case CV_64F: r = "64F"; break;
    default:     r = "User"; break;
  }

  r += "C";
  r += (chans+'0');

  return r;
}

/***********************************
I = 1/61*(Red*20 + Green*40 + Blue)
***********************************/
__device__ float compute_intensity(float Blue, float Green, float Red)
{
	return ((1.0/61.0) * (Blue + (Green * 40) + (Red * 20)));
}

/**********************
Red/I, Green/I, Blue/I
**********************/
__device__ float compute_chrominance(float Channel, float I)
{
	return Channel/I;
}

/***********
L = log2(I)
***********/
__device__ float compute_intensity_log(float I)
{
	return log2f(I);
}

/*********
B = bf(L)
*********/
__device__ float apply_billateral_filter(float L)
{
	//@TODO
}

/*******
D = L-B
*******/
__device__ float compute_detail_layer(float L, float B)
{
	return L-B;
}

/********************
nB = (B-offset)*scale
********************/
__device__ float apply_offset_scale_base(float B, int offset, int scale)
{
	return (B-offset)*scale;
}

/*************
O = exp(nB+D)
*************/
__device__ float reconstruct_log_intensity(float nB, float D)
{
	return expf(nB+D);
}

/****************************
nR,nG,nB = O*(R/I, G/I, B/I)
****************************/
__device__ float put_colors_back(float Channel, float I, float O)
{
	return O*(compute_chrominance(Channel, I));
}

/*********************

*********************/
__global__ void tonemap(float* imageIn, float* imageOut, int width, int height, int channels, int depth)
{
	//Each thread reads each pixel and puts it through the pipeline
}

// void showImage(Mat &image, const char *window) {
// 	namedWindow(window, CV_WINDOW_NORMAL);
// 	imshow(window, image);
// }

int main(int argc, char** argv)
{
	char* image_name = argv[1];
	Mat hdr;
	Size imageSize;
	int width, height;
//	std::vector<Mat>images;

	printf("%s\n", image_name);
	hdr = imread(image_name, -1);
	if(argc !=2 || !hdr.data){
	        printf("No image Data \n");
      	return -1;
	}

//	images.push_back(hdr);
//	Mat ldr;
//	Ptr<TonemapDurand> tonemap = createTonemapDurand(2.2f);
//	tonemap->process(images[0], ldr);
//	imwrite("ldr.png", ldr * 255);

	if(hdr.empty()) {
		printf("Couldn't find or open the image...\n");
		return -1;
	}
	imageSize = hdr.size();
	width = imageSize.width;
	height = imageSize.height;

	//printf("Width: %d\nHeight: %d\n", width, height);
	std::string ty =  type2str( hdr.type() );
	printf("Image: %s %dx%d \n", ty.c_str(), hdr.cols, hdr.rows );

	//printf("Channels: %d\nDepth: %d\n", hdr.channels(), hdr.depth());

	return 0;
}