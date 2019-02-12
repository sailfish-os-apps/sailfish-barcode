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

#ifndef HISTORYIMAGEPROVIDER_H
#define HISTORYIMAGEPROVIDER_H

#include <QImage>
#include <QQuickImageProvider>

class HistoryImageProvider : public QQuickImageProvider {
public:
    HistoryImageProvider();
    ~HistoryImageProvider();

    static const QString IMAGE_EXT;

    static HistoryImageProvider* instance();

    QImage requestImage(const QString& aId, QSize* aSize,
        const QSize& aRequested) Q_DECL_OVERRIDE;

    bool cacheImage(QString aImageId, QImage aImage);
    void dropFromCache(QString aImageId);
    void clearCache();

private:
    class Private;
    Private* iPrivate;
};

#endif // HISTORYIMAGEPROVIDER_H
