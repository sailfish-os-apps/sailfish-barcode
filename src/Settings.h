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

#ifndef BARCODE_SETTINGS_H
#define BARCODE_SETTINGS_H

#include <QObject>
#include <QString>

#define KEY_SOUND                   "sound"
#define KEY_DIGITAL_ZOOM            "digital_zoom"
#define KEY_SCAN_DURATION           "scan_duration"
#define KEY_RESULT_VIEW_DURATION    "result_view_duration"
#define KEY_MARKER_COLOR            "marker_color"
#define KEY_HISTORY_SIZE            "history_size"
#define KEY_SCAN_ON_START           "scan_on_start"

class Settings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool sound READ sound WRITE setSound NOTIFY soundChanged)
    Q_PROPERTY(int digitalZoom READ digitalZoom WRITE setDigitalZoom NOTIFY digitalZoomChanged)
    Q_PROPERTY(int scanDuration READ scanDuration WRITE setScanDuration NOTIFY scanDurationChanged)
    Q_PROPERTY(int resultViewDuration READ resultViewDuration WRITE setResultViewDuration NOTIFY resultViewDurationChanged)
    Q_PROPERTY(QString markerColor READ markerColor WRITE setMarkerColor NOTIFY markerColorChanged)
    Q_PROPERTY(int historySize READ historySize WRITE setHistorySize NOTIFY historySizeChanged)
    Q_PROPERTY(bool scanOnStart READ scanOnStart WRITE setScanOnStart NOTIFY scanOnStartChanged)

public:
    explicit Settings(QObject* aParent = Q_NULLPTR);
    ~Settings();

    bool sound() const;
    void setSound(bool value);

    int digitalZoom() const;
    void setDigitalZoom(int value);

    int scanDuration() const;
    void setScanDuration(int value);

    int resultViewDuration() const;
    void setResultViewDuration(int value);

    QString markerColor() const;
    void setMarkerColor(QString value);

    int historySize() const;
    void setHistorySize(int value);

    bool scanOnStart() const;
    void setScanOnStart(bool value);

Q_SIGNALS:
    void soundChanged();
    void digitalZoomChanged();
    void scanDurationChanged();
    void resultViewDurationChanged();
    void markerColorChanged();
    void historySizeChanged();
    void scanOnStartChanged();

private:
    class Private;
    Private* iPrivate;
};

#endif // BARCODE_SETTINGS_H
