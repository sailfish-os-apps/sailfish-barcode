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

ImageSource::ImageSource(QImage aImage) :
    zxing::LuminanceSource(aImage.width(), aImage.height())
{
    if (aImage.depth() == 32) {
        iImage = aImage;
    } else {
        iImage = aImage.convertToFormat(QImage::Format_RGB32);
    }

    const int height =  getHeight();
    iGrayRows = new zxing::byte*[height];
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

zxing::ArrayRef<zxing::byte> ImageSource::getRow(int aY, zxing::ArrayRef<zxing::byte> aRow) const
{
    const int width = getWidth();
    if (aRow->size() != width) {
        aRow.reset(zxing::ArrayRef<zxing::byte>(width));
    }
    memcpy(&aRow[0], getGrayRow(aY), width);
    return aRow;
}

zxing::ArrayRef<zxing::byte> ImageSource::getMatrix() const
{
    const int width = getWidth();
    const int height =  getHeight();
    zxing::ArrayRef<zxing::byte> matrix(width*height);
    zxing::byte* m = &matrix[0];

    for (int y = 0; y < height; y++) {
        memcpy(m, getGrayRow(y), width);
        m += width;
    }

    return matrix;
}

const zxing::byte* ImageSource::getGrayRow(int aY) const
{
    if (!iGrayRows[aY]) {
        const int width = iImage.width();
        zxing::byte* row = new zxing::byte[width];
        const QRgb* pixels = (const QRgb*)iImage.scanLine(aY);
        for (int x = 0; x < width; x++) {
            const QRgb rgb = *pixels++;
            // This is significantly faster than gGray() but is
            // just as good for our purposes
            row[x] = (zxing::byte)((((rgb & 0x00ff0000) >> 16) +
                ((rgb && 0x0000ff00) >> 8) +
                (rgb & 0xff))/3);
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
        const zxing::byte* src = getGrayRow(y);
        for (int x = 0; x < w; x++) {
            int g = *src++;
            *ptr++ = qRgb(g, g, g);
        }
    }
    return QImage((uchar*)buf, w, h, QImage::Format_ARGB32, free, buf);
}
