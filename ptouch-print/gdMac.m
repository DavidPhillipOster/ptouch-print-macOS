//  gdMac.m
//  ptouch-print
//
//  Created by David Phillip Oster on 12/16/23.
//

#import <AppKit/AppKit.h>

#import <CoreGraphics/CoreGraphics.h>

#import "gd.h"

static NSData *sDashStyle = nil;

int gdFTUseFontConfig(int flag) {
 return GD_TRUE;
}

int gdImageBlue(gdImage *im, int index) {
 return index == 0 ? 0 : 255;
}

// Since we are working in grayscale for black and white, just use the average.
int gdImageColorAllocate(gdImage *im, int red, int green, int blue) {
  return (red + green + blue)/3;
}

/// Copy a rectangle of pixels from src to dest. scaling the moved pixels if the rects don't match.
///
/// @param dst - destination
/// @param src - source
/// @param dstX - destination X
/// @param dstY - destination Y
/// @param srcX - source X
/// @param srcY - source Y
/// @param dstW - destination Width
/// @param dstH - destination Height
/// @param srcW - source Width
/// @param srcH - source Height
void gdImageScaledCopy(gdImage * dst, gdImage * src, double dstX, double dstY, double srcX, double srcY, double dstW, double dstH, double srcW, double srcH) {
  CGImageRef srcImage = CGBitmapContextCreateImage(src);
  CGImageRef srcRectImage = CGImageCreateWithImageInRect(srcImage, CGRectMake(srcX, srcY, srcW, srcH));
  CGContextDrawImage(dst, CGRectMake(dstX, dstY, dstW, dstH), srcRectImage);
  CGImageRelease(srcRectImage);
  CGImageRelease(srcImage);
}


void gdImageCopy(gdImage * dst, gdImage * src, int dstX, int dstY, int srcX, int srcY, int w, int h) {
  gdImageScaledCopy(dst, src, dstX, dstY, srcX, srcY, w, h, w, h);
}

gdImage *gdImageCreateFromPng(FILE *inFile) {
  fseek(inFile, 0, SEEK_END);
  NSInteger length = ftell(inFile);
  rewind(inFile);
  NSMutableData *data = [[NSMutableData alloc] initWithLength:length];
  if (data && 1 == fread(data.mutableBytes, data.length, 1, inFile)) {
    NSImage *image = [[NSImage alloc] initWithData:data];
    if (image) {
      CGRect r = CGRectMake(0, 0, image.size.width, image.size.height);
      CGImageRef ref = [image CGImageForProposedRect:&r context:nil hints:nil];
      if (ref) {
        gdImage *result = gdImageCreatePalette(image.size.width, image.size.height);
        if (result) {
          CGContextDrawImage(result, r, ref);
          return result;
        }
      }
    }
  }
  return NULL;
}

gdImage *gdImageCreatePalette(int x, int y) {
  const int bitsPerPixel = 8;
  static CGColorSpaceRef gray = NULL;
  if(NULL == gray){
    gray = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
  }
  uint32_t info = kCGImageByteOrderDefault | kCGImageAlphaNone;
  CGContextRef result = CGBitmapContextCreate(NULL, x, y, bitsPerPixel, (x*bitsPerPixel + 7)/8, gray, info);
  if (result) {
    uint8_t *p = (uint8_t *)CGBitmapContextGetData(result);
    int rowBytes = (int)CGBitmapContextGetBytesPerRow(result);
    for(int j = 0;j < y; ++j) {
      memset(p, 255, rowBytes);
      p += rowBytes;
    }
  }
  return result;
}

gdImage *gdImageCreateScaled(gdImage *im, float scale) {
  gdImage *result = gdImageCreatePalette(ceil(gdImageSX(im)*scale), ceil(gdImageSY(im)*scale));
  if (result) {
    gdImageScaledCopy(result, im, 0, 0, 0, 0, gdImageSX(im)*scale, gdImageSY(im)*scale, gdImageSX(im), gdImageSY(im));
  }
  return result;
}

void gdImageDestroy(gdImage *im) {
  CGContextRelease(im);
}

int gdImageGetPixel(gdImage *im, int x, int y) {
  uint8_t *base = (uint8_t *)CGBitmapContextGetData(im);
  return base[x + y*CGBitmapContextGetBytesPerRow(im)];
}

int gdImageGreen(gdImage *im, int index) {
 return index == 0 ? 0 : 255;
}

void gdImageLine(gdImage *im, int x1, int y1, int x2, int y2, int color) {
  CGFloat colors[3];
  CGContextBeginPath(im);
  if (color == gdStyled) {
    if (sDashStyle) {
      colors[0] = 0;    // black
      colors[1] = 1.0;  // opaque
      // phase=1, so we start with length of transparent.
      CGContextSetLineDash(im, 1, sDashStyle.bytes, sDashStyle.length/sizeof(CGFloat));
    }
  } else {
    CGContextSetLineDash(im, 0, NULL, 0);
    colors[0] = color / 255.0;
    colors[1] = 1.0;
  }
  CGContextSetStrokeColor(im, colors);
  // since pen is one pixel wide, offset in X to fill pixel with color
  CGFloat offset = (x1 == x2) ? -0.5 : 0;
  CGContextMoveToPoint(im, x1 + offset, y1);
  CGContextAddLineToPoint(im, x2 + offset, y2);
  CGContextStrokePath(im);
}

int gdImagePng(gdImage *im, FILE *outFile) {
  CGSize cgImageSize;
  cgImageSize.width = CGBitmapContextGetWidth(im);
  cgImageSize.height = CGBitmapContextGetHeight(im);
  CGImageRef cgImage = CGBitmapContextCreateImage(im);
  if (cgImage) {
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:cgImageSize];
    CGImageRelease(cgImage);
    if (image) {
      NSData *imageData = [image TIFFRepresentation];
      if (imageData) {
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
        NSDictionary *imageProps = @{NSImageCompressionFactor: @(1.0)};
        imageData = [imageRep representationUsingType:NSBitmapImageFileTypePNG properties:imageProps];
        if (imageData) {
          return 1 != fwrite(imageData.bytes, imageData.length, 1, outFile);
        }
      }
    }
  }
  return 0;
}

int gdImageRed(gdImage *im, int index) {
 return index == 0 ? 0 : 255;
}

void gdImageSetStyle(gdImage *im, int *style, int styleLength){
  if (styleLength == 6) {
    int i = 0;
    Boolean isDash = YES;
    for (; i < 3 && isDash;++i) {
      isDash |= style[i] == gdTransparent;
    }
    for (; i < 6 && isDash;++i) {
      isDash |= style[i] == 0;
    }
    if (isDash) {
      // input is specified in pixels, one entry per pixel. transparent first. CGContext wants line segments lengths, drawing first.
      CGFloat dash[] = { 3, 3 };
      sDashStyle = [NSData dataWithBytes:dash length:sizeof(CGFloat)];
    }
  }
}

char *gdImageStringFT(gdImage *im, int *brect, int fg, char *fontname, double ptsize, double angle, int x, int y, char *string) {
  @autoreleasepool {
    NSFont *font = [NSFont fontWithName:[NSString stringWithUTF8String:fontname] size:ptsize];
    if (nil == font) {
      return "Can’t get font";
    }
    NSString *nsString = [NSString stringWithUTF8String:string];
    if (nil == nsString) {
      return "Can’t convert to UTF8";
    }
    NSDictionary *dict = @{NSFontAttributeName: font, NSForegroundColorAttributeName : [NSColor colorWithWhite:fg/255.0 alpha:1]};
    if (im) {
      NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithCGContext:im flipped:NO];
      NSGraphicsContext *preserve = [NSGraphicsContext currentContext];
      [NSGraphicsContext setCurrentContext:context];
      [nsString drawAtPoint:CGPointMake(x, gdImageSY(im) - y) withAttributes:dict];
      [NSGraphicsContext setCurrentContext:preserve];
    }
    if (brect) {
      CGRect r = [nsString boundingRectWithSize:CGSizeMake(100000, 100000) options:0 attributes:dict];
      brect[0] = r.origin.x + x; // lower left
      brect[1] = r.origin.y + y + r.size.height;
      brect[2] = r.origin.x + x + r.size.width; // lower right
      brect[3] = r.origin.y + y + r.size.height;

      brect[4] = r.origin.x + x;  // upper left
      brect[5] = r.origin.y + y;
      brect[6] = r.origin.x + x + r.size.width; // upper right
      brect[7] = r.origin.y + y;
    }
    return NULL;
  }
}

int gdImageSX(gdImage *im) {
 return (int) CGBitmapContextGetWidth(im);
}

int gdImageSY(gdImage *im) {
 return (int) CGBitmapContextGetHeight(im);
}

