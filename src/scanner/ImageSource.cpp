/*
The MIT License (MIT)

Copyright (c) 2018 Slava Monich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "ImageSource.h"

ImageSource::ImageSource(QImage aImage)
{
    if (aImage.depth() == 32) {
        iImage = aImage;
    } else {
        iImage = aImage.convertToFormat(QImage::Format_RGB32);
    }

    const int height =  iImage.height();
    iGrayRows = new uchar*[height];
    memset(iGrayRows, 0, sizeof(iGrayRows[0]) * height);
}

ImageSource::~ImageSource()
{
    const int height =  iImage.height();
    for (int i = 0; i < height; i++) {
        delete [] iGrayRows [i];
    }
    delete [] iGrayRows;
}

int ImageSource::getWidth() const
{
    return iImage.width();
}

int ImageSource::getHeight() const
{
    return iImage.height();
}

unsigned char* ImageSource::getRow(int aY, unsigned char* aRow)
{
    const int width = iImage.width();
    if (!aRow) aRow = new unsigned char[width];
    memcpy(aRow, getGrayRow(aY), width);
    return aRow;
}

unsigned char* ImageSource::getMatrix()
{
    const int width = iImage.width();
    const int height =  iImage.height();
    unsigned char* matrix = new uchar[width*height];
    unsigned char* m = matrix;

    for (int y = 0; y < height; y++) {
        getRow(y, m);
        m += width;
    }

    return matrix;
}

const uchar* ImageSource::getGrayRow(int aY) const
{
    if (!iGrayRows[aY]) {
        const int width = iImage.width();
        uchar* row = new uchar[width];
        const QRgb* pixels = (const QRgb*)iImage.scanLine(aY);
        for (int x = 0; x < width; x++) {
            const QRgb rgb = *pixels++;
            // This is significantly faster than gGray() but is
            // just as good for our purposes
            row[x] = (((rgb & 0x00ff0000) >> 16) +
                ((rgb && 0x0000ff00) >> 8) +
                (rgb & 0xff))/3;
        }
        iGrayRows[aY] = row;
    }
    return iGrayRows[aY];
}

QImage ImageSource::grayscaleImage() const
{
    const int w = iImage.width();
    const int h =  iImage.height();
    QRgb* buf = (QRgb*)malloc(w * h * sizeof(QRgb));
    QRgb* ptr = buf;
    for (int y = 0; y < h; y++) {
        const uchar* src = getGrayRow(y);
        for (int x = 0; x < w; x++) {
            int g = *src++;
            *ptr++ = qRgb(g, g, g);
        }
    }
    return QImage((uchar*)buf, w, h, QImage::Format_ARGB32, free, buf);
}
