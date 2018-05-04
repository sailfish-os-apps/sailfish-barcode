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

#include "AutoBarcodeScanner.h"
#include "CaptureImageProvider.h"
#include "DebugLog.h"

#include <QPainter>
#include <QBrush>
#include <QStandardPaths>
#include <QtQuick/QQuickWindow>

#include "qzxing/qzxing.h"

#include <fstream>

#ifdef DEBUG
static void saveDebugImage(QImage &image, const QString &fileName)
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/codereader/" + fileName;
    if (image.save(path)) {
        DLOG("image saved:" << qPrintable(path));
    }
}
#else
#  define saveDebugImage(image,fileName) ((void)0)
#endif

AutoBarcodeScanner::AutoBarcodeScanner(QObject* parent) :
    QObject(parent),
    m_grabbing(false),
    m_decoder(new QZXing(this)),
    m_viewFinderItem(NULL),
    m_flagScanRunning(false),
    m_flagScanAbort(false),
    m_timeoutTimer(new QTimer(this)),
    m_markerColor(QColor(0, 255, 0)) // default green
{
    DLOG("start init AutoBarcodeScanner");

    createConnections();
    m_timeoutTimer->setSingleShot(true);
    connect(m_timeoutTimer, SIGNAL(timeout()), this, SLOT(slotScanningTimeout()));
}

AutoBarcodeScanner::~AutoBarcodeScanner()
{
    DLOG("AutoBarcodeScanner::~AutoBarcodeScanner");

    // stopping a running scanning process
    stopScanning();
    m_scanFuture.waitForFinished();
}

void AutoBarcodeScanner::createConnections()
{
    // Handled on the main thread
    connect(this, SIGNAL(decodingDone(QImage,QVariantList,QString)),
            this, SLOT(slotDecodingDone(QImage,QVariantList,QString)),
            Qt::QueuedConnection);
    // Forward needImage emitted by the decoding thread
    connect(this, SIGNAL(needImage()), this, SLOT(slotGrabImage()), Qt::QueuedConnection);
}

void AutoBarcodeScanner::slotGrabImage()
{
    if (m_viewFinderItem && m_flagScanRunning) {
        QQuickWindow* window = m_viewFinderItem->window();
        if (window) {
            DLOG("grabbing image");
            m_grabbing = true;
            emit grabbingChanged();
            QImage image = window->grabWindow();
            m_grabbing = false;
            emit grabbingChanged();
            if (!image.isNull() && m_flagScanRunning) {
                DLOG(image);
                m_scanProcessMutex.lock();
                m_captureImage = image;
                m_scanProcessEvent.wakeAll();
                m_scanProcessMutex.unlock();
            }
        }
    }
}

void AutoBarcodeScanner::setViewFinderRect(QRect rect)
{
    if (m_viewFinderRect != rect) {
        DLOG(rect);
        // m_viewFinderRect is accessed by processDecode() thread
        m_scanProcessMutex.lock();
        m_viewFinderRect = rect;
        m_scanProcessMutex.unlock();
    }
}

void AutoBarcodeScanner::setViewFinderItem(QObject* value)
{
    QQuickItem* item = qobject_cast<QQuickItem*>(value);
    if (m_viewFinderItem != item) {
        m_viewFinderItem = item;
        emit viewFinderItemChanged();
    }
}

void AutoBarcodeScanner::startScanning(int timeout)
{
    if (!m_flagScanRunning) {
        m_flagScanRunning = true;
        m_flagScanAbort = false;
        m_timeoutTimer->start(timeout);
        m_captureImage = QImage();
        m_scanFuture = QtConcurrent::run(this, &AutoBarcodeScanner::processDecode);
    }
}

void AutoBarcodeScanner::stopScanning()
{
    // stopping a running scanning process
    m_scanProcessMutex.lock();
    if (m_flagScanRunning) {
        m_flagScanAbort = true;
        m_scanProcessEvent.wakeAll();
    }
    m_scanProcessMutex.unlock();
}

/**
 * Runs in a pooled thread.
 */
void AutoBarcodeScanner::processDecode()
{
    DLOG("processDecode() is called from " << QThread::currentThread());

    QString code;
    QVariantHash result;
    QImage image;
    qreal scale = 1;
    bool rotated = false;

    const int maxWidth = 600;
    const int maxHeight = 800;

    m_scanProcessMutex.lock();
    while (!m_flagScanAbort && code.isEmpty()) {
        emit needImage();
        QRect viewFinderRect;
        while (m_captureImage.isNull() && !m_flagScanAbort) {
            m_scanProcessEvent.wait(&m_scanProcessMutex);
        }
        if (m_flagScanAbort) {
            image = QImage();
        } else {
            image = m_captureImage;
            m_captureImage = QImage();
        }
        viewFinderRect = m_viewFinderRect;
        m_scanProcessMutex.unlock();

        if (!image.isNull()) {
#ifdef DEBUG
            QTime time(QTime::currentTime());
#endif
            // crop the image - we need only the viewfinder
            image = image.copy(viewFinderRect);
            DLOG("extracted" << image);
            saveDebugImage(image, "debug_screenshot.jpg");

            QImage scaledImage;
            if (image.width() > maxWidth || image.height() > maxHeight) {
                if (maxWidth * image.height() > maxHeight * image.width()) {
                    scaledImage = image.scaledToHeight(maxHeight);
                    scale = image.height()/(qreal)maxHeight;
                    DLOG("scaled to height" << scale << scaledImage);
                } else {
                    scaledImage = image.scaledToWidth(maxWidth);
                    scale = image.width()/(qreal)maxWidth;
                    DLOG("scaled to width" << scale << scaledImage);
                }
                saveDebugImage(scaledImage, "debug_scaled.jpg");
            } else {
                scaledImage = image;
                scale = 1;
            }

            DLOG("decoding screenshot ...");
            result = m_decoder->decodeImageEx(scaledImage);
            code = result["content"].toString();

            if (code.isEmpty()) {
                // try the other orientation for 1D bar code
                QTransform transform;
                transform.rotate(90);
                scaledImage = scaledImage.transformed(transform);
                saveDebugImage(scaledImage, "debug_rotated.jpg");
                DLOG("decoding rotated screenshot ...");
                result = m_decoder->decodeImageEx(scaledImage);
                code = result["content"].toString();
                rotated = true;
            } else {
                rotated = false;
            }
            DLOG("decoding took" << time.elapsed() << "ms");
        }
        m_scanProcessMutex.lock();
    }
    m_scanProcessMutex.unlock();

    if (code.isEmpty()) {
        DLOG("decoding failed");
        emit decodingDone(QImage(), QVariantList(), QString());
    } else {
        QVariantList points = result["points"].toList();
        DLOG("decoding succeeded:" << code << points);
        const int n = points.size();
        if (scale > 1 || rotated) {
            // The image could be a) scaled and b) rotated. Convert
            // points to the original coordinate system
            for (int i = 0; i < n; i++) {
                QPointF p = points[i].toPointF();
                if (rotated) {
                    const qreal x = p.rx();
                    p.setX(p.ry());
                    p.setY(image.height() - x);
                }
                p *= scale;
                points[i] = QVariant::fromValue(p);
            }
        }
        emit decodingDone(image, points, code);
    }
}

void AutoBarcodeScanner::slotDecodingDone(QImage image, QVariantList points, const QString code)
{
    DLOG("decoding has been finished:" << code);
    if (!image.isNull()) {
        DLOG("image:" << image);
        DLOG("points:" << points);
        markLastCaptureImage(image, points);
    }
    m_captureImage = QImage();
    m_timeoutTimer->stop();
    m_flagScanRunning = false;
    emit decodingFinished(code);
}

void AutoBarcodeScanner::markLastCaptureImage(QImage image, QVariantList points)
{
    if (!points.isEmpty()) {
        QPainter painter(&image);
        painter.setPen(m_markerColor);
        QBrush markerBrush(m_markerColor);
        for (int i = 0; i < points.size(); i++) {
            QPoint p = points[i].toPoint();
            painter.fillRect(QRect(p.x()-3, p.y()-15, 6, 30), markerBrush);
            painter.fillRect(QRect(p.x()-15, p.y()-3, 30, 6), markerBrush);
        }
        painter.end();
        saveDebugImage(image, "debug_marks.jpg");
    }
    CaptureImageProvider::setMarkedImage(image);
}

void AutoBarcodeScanner::slotScanningTimeout()
{
    m_scanProcessMutex.lock();
    m_flagScanAbort = true;
    DLOG("decoding aborted by timeout");
    m_scanProcessEvent.wakeAll();
    m_scanProcessMutex.unlock();
}
