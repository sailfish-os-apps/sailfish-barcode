/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
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

#include "CaptureImageProvider.h"
#include "Database.h"
#include "HarbourDebug.h"

#include <QHash>

// ==========================================================================
// CaptureImageProvider::Private
// ==========================================================================

class CaptureImageProvider::Private {
public:
    Private() {}
    ~Private() {}

    static const QString MARKED;
    static const QString SAVED;

    static CaptureImageProvider* gInstance;

public:
    QHash<QString,QImage> iCache;
};

const QString CaptureImageProvider::Private::MARKED("marked");
const QString CaptureImageProvider::Private::SAVED("saved/");

CaptureImageProvider* CaptureImageProvider::Private::gInstance = NULL;

// ==========================================================================
// CaptureImageProvider
// ==========================================================================

const QString CaptureImageProvider::IMAGE_EXT(".jpg");

CaptureImageProvider::CaptureImageProvider() :
    QQuickImageProvider(Image),
    iPrivate(new Private)
{
    if (!Private::gInstance) {
        Private::gInstance = this;
    }
}

CaptureImageProvider::~CaptureImageProvider()
{
    delete iPrivate;
    if (Private::gInstance == this) {
        Private::gInstance = Q_NULLPTR;
    }
}

CaptureImageProvider* CaptureImageProvider::instance()
{
    return Private::gInstance;
}

QImage CaptureImageProvider::requestImage(const QString& aId, QSize* aSize, const QSize&)
{
    QImage img;
    if (aId == Private::MARKED) {
        img = iMarkedImage;
    } else if (aId.startsWith(Private::SAVED)) {
        // Extract database id
        const QString recId(aId.mid(Private::SAVED.length()));
        QImage cached(iPrivate->iCache.value(recId));
        if (cached.isNull()) {
            const QString path(Database::imageDir().path() + QDir::separator() +
                recId + IMAGE_EXT);
            if (QFile::exists(path)) {
                if (img.load(path)) {
                    HDEBUG(qPrintable(path));
                    HDEBUG(img);
                } else {
                    HWARN("Failed to load " << qPrintable(path));
                }
            } else {
                HDEBUG(qPrintable(path) << "not found");
            }
        } else {
            HDEBUG(recId << "cached");
        }
    }

    if (!img.isNull() && aSize) {
        *aSize = img.size();
    }

    return img;
}

bool CaptureImageProvider::cacheMarkedImage(QString aImageId)
{
    if (!aImageId.isEmpty() && !iMarkedImage.isNull()) {
        iPrivate->iCache.insert(aImageId, iMarkedImage);
        HDEBUG(aImageId);
        return true;
    } else {
        return false;
    }
}

void CaptureImageProvider::dropFromCache(QString aImageId)
{
    if (iPrivate->iCache.remove(aImageId)) {
        HDEBUG(aImageId);
    }
}

void CaptureImageProvider::clearCache()
{
    iPrivate->iCache.clear();
}
