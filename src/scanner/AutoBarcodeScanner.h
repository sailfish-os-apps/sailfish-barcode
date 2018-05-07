/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018 Slava Monich

Some ideas are borrowed from qdeclarativecamera.cpp and qdeclarativecamera.h
(https://git.gitorious.org/qt/qtmultimedia.git)

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

#ifndef AUTOBARCODESCANNER_H
#define AUTOBARCODESCANNER_H

#include <QColor>
#include <QtConcurrent>
#include <QtQuick/QQuickItem>
#include <QImage>

#include "Decoder.h"

class AutoBarcodeScanner : public QObject
{
    Q_OBJECT

public:
    AutoBarcodeScanner(QObject *parent = 0);
    virtual ~AutoBarcodeScanner();

    Q_PROPERTY(QObject* viewFinderItem READ viewFinderItem WRITE setViewFinderItem NOTIFY viewFinderItemChanged)
    Q_PROPERTY(bool grabbing READ grabbing NOTIFY grabbingChanged)

    Q_INVOKABLE void startScanning(int timeout);
    Q_INVOKABLE void stopScanning();

    Q_INVOKABLE void setMarkerColor(int red, int green, int blue) {
        m_markerColor = QColor(red, green, blue);
    }

    Q_INVOKABLE void setViewFinderRect(QRect rect);

    // must be public, to start in new thread
    void processDecode();

    QObject* viewFinderItem() const { return m_viewFinderItem; }
    bool grabbing() const { return m_grabbing; }

    void setViewFinderItem(QObject* item);

signals:
    void decodingDone(QImage image, Decoder::Result result);
    void decodingFinished(QVariantMap result);
    void viewFinderItemChanged();
    void grabbingChanged();
    void needImage();

public slots:
    void onScanningTimeout();
    void onDecodingDone(QImage aImage, Decoder::Result aResult);
    void onGrabImage();

private:
    void createConnections();
    void markLastCaptureImage(QImage aImage, QList<QPointF> aPoints);

private:
    bool m_grabbing;
    Decoder* m_decoder;
    QImage m_captureImage;
    QQuickItem* m_viewFinderItem;
    bool m_flagScanRunning;
    bool m_flagScanAbort;
    QTimer* m_timeoutTimer;

    QMutex m_scanProcessMutex;
    QWaitCondition m_scanProcessEvent;
    QFuture<void> m_scanFuture;

    // options
    QRect m_viewFinderRect;
    QColor m_markerColor;
};

#endif // AUTOBARCODESCANNER_H
