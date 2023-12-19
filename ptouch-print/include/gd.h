//  gd.h
//  ptouch-print
//
//  Created by David Phillip Oster on 12/16/23.
//

#ifndef gd_h
#define gd_h

enum {
  GD_FALSE,
  GD_TRUE
};

static const char *VERSION = "0.02";

static const int gdTransparent = 256;
static const int gdStyled = 257;

typedef struct CGContext CGImage;
typedef CGImage gdImage;

int gdFTUseFontConfig(int flag);
int gdImageBlue(gdImage *im, int index);
int gdImageColorAllocate(gdImage *im, int red, int green, int blue);

/// Copy a rectangle of pixels from src to dest.
///
/// @param dst - destination
/// @param src - source
/// @param dstX - destination X
/// @param dstY - destination Y
/// @param srcX - source X
/// @param srcY - source Y
/// @param w - Width
/// @param h - Height
void gdImageCopy(gdImage * dst, gdImage * src, int dstX, int dstY, int srcX, int srcY, int w, int h);
gdImage *gdImageCreateFromPng(FILE *inFile);
gdImage *gdImageCreatePalette(int x, int y);
void gdImageDestroy(gdImage *im);
int gdImageGetPixel(gdImage *im, int x, int y);
int gdImageGreen(gdImage *im, int index);
void gdImageLine(gdImage *im, int x1, int y1, int x2, int y2, int color);
int gdImagePng(gdImage *im,FILE *outFile);
int gdImageRed(gdImage *im, int index);

/// @param im - source image.
/// @param scale - positive scale factor. new image is ceil(x*scale), ceil(y*scale)
/// @return a newly created gdImage that is original image rescaled
gdImage *gdImageCreateScaled(gdImage *im, float scale);

/// @param im	The image to draw onto.
/// @param style array of pixel colors
/// @param styleLength number of items in style array
void gdImageSetStyle(gdImage *im, int *style, int styleLength);

/// @param im	The image to draw onto.
/// @param brect	The bounding rectangle as array of 8 integers where each pair represents the x- and y-coordinate of a point.  The points specify the lower left, lower right, upper right and upper left corner.
/// @param fg	The font color.
/// @param fontname	The font
/// @param ptsize	The height of the font in typographical points (pt).
/// @param angle	The angle in radian to rotate the font counter-clockwise.
/// @param x	The x-coordinate of the basepoint (roughly the lower left corner) of the first letter.
/// @param y	The y-coordinate of the basepoint (roughly the lower left corner) of the first letter.
/// @param string	The string to render.
/// @return nil on success,  errorString on failure
char *gdImageStringFT(gdImage *im, int *brect, int fg, char *fontname, double ptsize, double angle, int x, int y, char *string);

/// @return width in pixels of image
int gdImageSX(gdImage *im);

/// @return height in pixels of image
int gdImageSY(gdImage *im);

#endif /* gd_h */
