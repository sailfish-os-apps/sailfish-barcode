#include "CameraImageWrapper.h"
#include <QColor>

CameraImageWrapper::CameraImageWrapper(QImage aImage)
{
    if (aImage.depth() == 32) {
        image = aImage;
    } else {
        image = aImage.convertToFormat(QImage::Format_RGB32);
    }
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
    const QRgb* pixels = (const QRgb*)image.scanLine(y);
    for (int x = 0; x < width; x++) {
        row[x] = qGray(pixels[x]);
    }
    return row;
}

unsigned char* CameraImageWrapper::getMatrix()
{
    const int width = image.width();
    const int height =  image.height();
    unsigned char* matrix = new unsigned char[width*height];
    unsigned char* m = matrix;

    for (int y=0; y < height; y++) {
        getRow(y, m);
        m += width;
    }

    return matrix;
}
