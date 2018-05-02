#include "CameraImageWrapper.h"

CameraImageWrapper::CameraImageWrapper(QImage aImage)
{
    if (aImage.depth() == 32) {
        image = aImage;
    } else {
        image = aImage.convertToFormat(QImage::Format_RGB32);
    }

    const int height =  image.height();
    cache = new unsigned char*[height];
    memset(cache, 0, sizeof(cache[0]) * height);
}

CameraImageWrapper::~CameraImageWrapper()
{
    const int height =  image.height();
    for (int i = 0; i < height; i++) {
        delete [] cache [i];
    }
    delete [] cache;
}

int CameraImageWrapper::getWidth() const
{
    return image.width();
}

int CameraImageWrapper::getHeight() const
{
    return image.height();
}

unsigned char* CameraImageWrapper::getRow(int y, unsigned char* row)
{
    const int width = image.width();
    if (!row) row = new unsigned char[width];
    memcpy(row, getCachedRow(y), width);
    return row;
}

unsigned char* CameraImageWrapper::getMatrix()
{
    const int width = image.width();
    const int height =  image.height();
    unsigned char* matrix = new unsigned char[width*height];
    unsigned char* m = matrix;

    for (int y = 0; y < height; y++) {
        memcpy(m, getCachedRow(y), width);
        m += width;
    }

    return matrix;
}

const unsigned char* CameraImageWrapper::getCachedRow(int y)
{
    if (!cache[y]) {
        const int width = image.width();
        unsigned char* row = new unsigned char[width];
        const QRgb* pixels = (const QRgb*)image.scanLine(y);
        for (int x = 0; x < width; x++) {
            const QRgb rgb = *pixels++;
            // This is significantly faster than gGray() but is
            // just as good for our purposes
            row[x] = (((rgb & 0x00ff0000) >> 16) +
                ((rgb && 0x0000ff00) >> 8) +
                (rgb & 0xff))/3;
        }
        cache[y] = row;
    }
    return cache[y];
}
