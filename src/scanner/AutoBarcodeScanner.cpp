/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2019 Slava Monich

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

#include "AutoBarcodeScanner.h"
#include "ImageSource.h"
#include "Decoder.h"

#include "HarbourDebug.h"

#include <QtConcurrent>
#include <QQuickWindow>
#include <QQuickItem>
#include <QPainter>
#include <QBrush>

#ifdef HARBOUR_DEBUG
#include <QStandardPaths>
static void saveDebugImage(const QImage& aImage, const QString& aFileName)
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/codereader/" + aFileName;
    if (aImage.save(path)) {
        HDEBUG("image saved:" << qPrintable(path));
    }
}
#else
#  define saveDebugImage(image,fileName) ((void)0)
#endif

// ==========================================================================
// AutoBarcodeScanner::Private
// ==========================================================================

class AutoBarcodeScanner::Private : public QObject {
    Q_OBJECT
public:
    Private(AutoBarcodeScanner* aParent);
    ~Private();

    AutoBarcodeScanner* scanner();

    bool setViewFinderRect(const QRect& aRect);
    bool setViewFinderItem(QObject* aValue);
    bool setMarkerColor(QString aValue);
    void startScanning(int aTimeout);
    void stopScanning();
    void decodingThread();

Q_SIGNALS:
    void needImage();
    void decodingDone(QImage image, Decoder::Result result);

public Q_SLOTS:
    void onScanningTimeout();
    void onDecodingDone(QImage aImage, Decoder::Result aResult);
    void onGrabImage();

public:
    bool iGrabbing;
    bool iScanning;
    bool iAbortScan;

    QImage iCaptureImage;
    QQuickItem* iViewFinderItem;
    QTimer* iScanTimeout;

    QMutex iDecodingMutex;
    QWaitCondition iDecodingEvent;
    QFuture<void> iDecodingFuture;

    QRect iViewFinderRect;
    QColor iMarkerColor;
};

AutoBarcodeScanner::Private::Private(AutoBarcodeScanner* aParent) :
    QObject(aParent),
    iGrabbing(false),
    iScanning(false),
    iAbortScan(false),
    iViewFinderItem(NULL),
    iScanTimeout(new QTimer(this)),
    iMarkerColor(QColor(0, 255, 0)) // default green
{
    iScanTimeout->setSingleShot(true);
    connect(iScanTimeout, SIGNAL(timeout()),
        this, SLOT(onScanningTimeout()));

    // Handled on the main thread
    qRegisterMetaType<Decoder::Result>();
    connect(this, SIGNAL(decodingDone(QImage,Decoder::Result)),
        SLOT(onDecodingDone(QImage,Decoder::Result)),
        Qt::QueuedConnection);

    // Forward needImage emitted by the decoding thread
    connect(this, SIGNAL(needImage()), SLOT(onGrabImage()),
        Qt::QueuedConnection);
}

AutoBarcodeScanner::Private::~Private()
{
    stopScanning();
    iDecodingFuture.waitForFinished();
}

inline AutoBarcodeScanner* AutoBarcodeScanner::Private::scanner()
{
    return qobject_cast<AutoBarcodeScanner*>(parent());
}

bool AutoBarcodeScanner::Private::setViewFinderRect(const QRect& aRect)
{
    if (iViewFinderRect != aRect) {
        // iViewFinderRect is accessed by decodingThread() thread
        iDecodingMutex.lock();
        iViewFinderRect = aRect;
        iDecodingMutex.unlock();
        return true;
    }
    return false;
}

bool AutoBarcodeScanner::Private::setViewFinderItem(QObject* aItem)
{
    QQuickItem* item = qobject_cast<QQuickItem*>(aItem);
    if (iViewFinderItem != item) {
        iViewFinderItem = item;
        return true;
    }
    return false;
}

bool AutoBarcodeScanner::Private::setMarkerColor(QString aValue)
{
    if (QColor::isValidColor(aValue)) {
        QColor color(aValue);
        if (iMarkerColor != color) {
            iMarkerColor = color;
            return true;
        }
    }
    return false;
}

void AutoBarcodeScanner::Private::startScanning(int aTimeout)
{
    if (!iScanning) {
        iScanning = true;
        iAbortScan = false;
        iScanTimeout->start(aTimeout);
        iCaptureImage = QImage();
        iDecodingFuture = QtConcurrent::run(this, &Private::decodingThread);
    }
}

void AutoBarcodeScanner::Private::stopScanning()
{
    // stopping a running scanning process
    iDecodingMutex.lock();
    if (iScanning) {
        iAbortScan = true;
        iDecodingEvent.wakeAll();
    }
    iDecodingMutex.unlock();
}

void AutoBarcodeScanner::Private::onGrabImage()
{
    if (iViewFinderItem && iScanning) {
        QQuickWindow* window = iViewFinderItem->window();
        if (window) {
            AutoBarcodeScanner* parent = scanner();
            HDEBUG("grabbing image");
            iGrabbing = true;
            Q_EMIT parent->grabbingChanged();
            QImage image = window->grabWindow();
            iGrabbing = false;
            Q_EMIT parent->grabbingChanged();
            if (!image.isNull() && iScanning) {
                HDEBUG(image);
                iDecodingMutex.lock();
                iCaptureImage = image;
                iDecodingEvent.wakeAll();
                iDecodingMutex.unlock();
            }
        }
    }
}

void AutoBarcodeScanner::Private::decodingThread()
{
    HDEBUG("decodingThread() is called from " << QThread::currentThread());

    Decoder decoder;
    Decoder::Result result;
    QImage image;
    qreal scale = 1;
    bool rotated = false;
    int scaledWidth = 0;

    const int maxWidth = 600;
    const int maxHeight = 800;

    iDecodingMutex.lock();
    while (!iAbortScan && !result.isValid()) {
        emit needImage();
        QRect viewFinderRect;
        while (iCaptureImage.isNull() && !iAbortScan) {
            iDecodingEvent.wait(&iDecodingMutex);
        }
        if (iAbortScan) {
            image = QImage();
        } else {
            image = iCaptureImage;
            iCaptureImage = QImage();
        }
        viewFinderRect = iViewFinderRect;
        iDecodingMutex.unlock();

        if (!image.isNull()) {
#if HARBOUR_DEBUG
            QTime time(QTime::currentTime());
#endif
            // crop the image - we need only the viewfinder
            saveDebugImage(image, "debug_screenshot.bmp");
            image = image.copy(viewFinderRect);
            HDEBUG("extracted" << image);
            saveDebugImage(image, "debug_cropped.bmp");

            QImage scaledImage;
            if (image.width() > maxWidth || image.height() > maxHeight) {
                Qt::TransformationMode mode = Qt::SmoothTransformation;
                if (maxWidth * image.height() > maxHeight * image.width()) {
                    scaledImage = image.scaledToHeight(maxHeight, mode);
                    scale = image.height()/(qreal)maxHeight;
                    HDEBUG("scaled to height" << scale << scaledImage);
                } else {
                    scaledImage = image.scaledToWidth(maxWidth, mode);
                    scale = image.width()/(qreal)maxWidth;
                    HDEBUG("scaled to width" << scale << scaledImage);
                }
                saveDebugImage(scaledImage, "debug_scaled.bmp");
            } else {
                scaledImage = image;
                scale = 1;
            }

            ImageSource* source = new ImageSource(scaledImage);
            saveDebugImage(source->grayscaleImage(), "debug_grayscale.bmp");

            // Ref takes ownership of ImageSource:
            zxing::Ref<zxing::LuminanceSource> sourceRef(source);

            HDEBUG("decoding screenshot ...");
            result = decoder.decode(sourceRef);

            if (!result.isValid()) {
                // try the other orientation for 1D bar code
                QTransform transform;
                transform.rotate(90);
                scaledImage = scaledImage.transformed(transform);
                saveDebugImage(scaledImage, "debug_rotated.bmp");
                HDEBUG("decoding rotated screenshot ...");
                result = decoder.decode(scaledImage);
                // We need scaled width for rotating the points back
                scaledWidth = scaledImage.width();
                rotated = true;
            } else {
                rotated = false;
            }
            HDEBUG("decoding took" << time.elapsed() << "ms");
        }
        iDecodingMutex.lock();
    }
    iDecodingMutex.unlock();

    if (result.isValid()) {
        HDEBUG("decoding succeeded:" << result.getText() << result.getPoints());
        if (scale > 1 || rotated) {
            // The image could be a) scaled and b) rotated. Convert
            // points to the original coordinate system
            QList<QPointF> points = result.getPoints();
            const int n = points.size();
            for (int i = 0; i < n; i++) {
                QPointF p(points.at(i));
                if (rotated) {
                    const qreal x = p.rx();
                    p.setX(p.ry());
                    p.setY(scaledWidth - x);
                }
                p *= scale;
                HDEBUG(points[i] << "=>" << p);
                points[i] = p;
            }
            result = Decoder::Result(result.getText(), points, result.getFormat());
        }
    } else {
        HDEBUG("nothing was decoded");
        image = QImage();
    }
    Q_EMIT decodingDone(image, result);
}

void AutoBarcodeScanner::Private::onDecodingDone(QImage aImage, Decoder::Result aResult)
{
    HDEBUG(aResult.getText());
    if (!aImage.isNull()) {
        const QList<QPointF> points(aResult.getPoints());
        HDEBUG("image:" << aImage);
        HDEBUG("points:" << points);
        HDEBUG("format:" << aResult.getFormat() << aResult.getFormatName());
        if (!points.isEmpty()) {
            QPainter painter(&aImage);
            painter.setPen(iMarkerColor);
            QBrush markerBrush(iMarkerColor);
            for (int i = 0; i < points.size(); i++) {
                const QPoint p(points.at(i).toPoint());
                painter.fillRect(QRect(p.x()-3, p.y()-15, 6, 30), markerBrush);
                painter.fillRect(QRect(p.x()-15, p.y()-3, 30, 6), markerBrush);
            }
            painter.end();
            saveDebugImage(aImage, "debug_marks.bmp");
        }
    }

    iCaptureImage = QImage();
    iScanTimeout->stop();
    iScanning = false;

    QVariantMap result;
    result.insert("ok", QVariant::fromValue(aResult.isValid()));
    result.insert("text", QVariant::fromValue(aResult.getText()));
    result.insert("format", QVariant::fromValue(aResult.getFormatName()));
    Q_EMIT scanner()->decodingFinished(aImage, result);
}

void AutoBarcodeScanner::Private::onScanningTimeout()
{
    iDecodingMutex.lock();
    iAbortScan = true;
    HDEBUG("decoding aborted by timeout");
    iDecodingEvent.wakeAll();
    iDecodingMutex.unlock();
}

// ==========================================================================
// AutoBarcodeScanner::Private
// ==========================================================================

AutoBarcodeScanner::AutoBarcodeScanner(QObject* parent) :
    QObject(parent),
    iPrivate(new Private(this))
{
    HDEBUG("created");
}

AutoBarcodeScanner::~AutoBarcodeScanner()
{
    HDEBUG("destroyed");
}

const QRect& AutoBarcodeScanner::viewFinderRect() const
{
    return iPrivate->iViewFinderRect;
}

void AutoBarcodeScanner::setViewFinderRect(const QRect& aRect)
{
    if (iPrivate->setViewFinderRect(aRect)) {
        HDEBUG(aRect);
    }
}

QObject* AutoBarcodeScanner::viewFinderItem() const
{
    return iPrivate->iViewFinderItem;
}

void AutoBarcodeScanner::setViewFinderItem(QObject* aItem)
{
    if (iPrivate->setViewFinderItem(aItem)) {
        Q_EMIT viewFinderItemChanged();
    }
}

QString AutoBarcodeScanner::markerColor() const
{
    return iPrivate->iMarkerColor.name();
}

void AutoBarcodeScanner::setMarkerColor(QString aValue)
{
    if (iPrivate->setMarkerColor(aValue)) {
        HDEBUG(aValue);
        Q_EMIT markerColorChanged();
    }
}

void AutoBarcodeScanner::startScanning(int aTimeout)
{
    iPrivate->startScanning(aTimeout);
}

void AutoBarcodeScanner::stopScanning()
{
    iPrivate->stopScanning();
}

bool AutoBarcodeScanner::grabbing() const
{
    return iPrivate->iGrabbing;
}

#include "AutoBarcodeScanner.moc"
