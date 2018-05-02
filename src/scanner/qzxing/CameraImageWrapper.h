#ifndef CAMERAIMAGE_H
#define CAMERAIMAGE_H

#include <QImage>
#include <zxing/LuminanceSource.h>

using namespace zxing;

class CameraImageWrapper : public LuminanceSource
{
private:
    CameraImageWrapper(CameraImageWrapper& otherInstance);

public:
    CameraImageWrapper(QImage image);
    ~CameraImageWrapper();
    
    int getWidth() const;
    int getHeight() const;
    
    // Callers take ownership of the returned memory and must call delete [] on it themselves.
    unsigned char* getRow(int y, unsigned char* row);
    unsigned char* getMatrix();

private:
    const unsigned char* getCachedRow(int y);

private:
    QImage image;
    unsigned char** cache;
};

#endif //CAMERAIMAGE_H
