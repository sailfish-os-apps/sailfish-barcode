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

#include <sailfishapp.h>
#include <QTranslator>
#include <QCameraExposure>
#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>

#include <MGConfItem>

#include "scanner/AutoBarcodeScanner.h"
#include "scanner/CaptureImageProvider.h"

#include "HarbourDebug.h"
#include "HarbourDisplayBlanking.h"
#include "HarbourTemporaryFile.h"

#include "ContactsPlugin.h"
#include "Database.h"
#include "HistoryModel.h"
#include "Settings.h"

#ifndef APP_VERSION
#  define ""
#endif

static void register_types(QQmlEngine* engine, const char* uri, int v1, int v2)
{
    ContactsPlugin::registerTypes(engine, uri, v1, v2);
    qmlRegisterType<HarbourDisplayBlanking>(uri, v1, v2, "DisplayBlanking");
    qmlRegisterType<HarbourTemporaryFile>(uri, v1, v2, "TemporaryFile");
    qmlRegisterType<AutoBarcodeScanner>(uri, v1, v2, "AutoBarcodeScanner");
    qmlRegisterType<HistoryModel>(uri, v1, v2, "HistoryModel");
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    bool torchSupported = false;

    // Parse Qt version to find out what's supported and what's not
    const char* qver = qVersion();
    HDEBUG("Qt version" << qver);
    if (qver) {
        const QStringList s(QString(qver).split('.'));
        if (s.size() >= 3) {
            int v = QT_VERSION_CHECK(s[0].toInt(), s[1].toInt(), s[2].toInt());
            if (v >= QT_VERSION_CHECK(5,6,0)) {
                // If flash is not supported at all, this key contains [2]
                // at least on the most recent versions of Sailfish OS
                QString flashValuesKey("/apps/jolla-camera/primary/image/flashValues");
                MGConfItem flashValuesConf(flashValuesKey);
                QVariantList flashValues(flashValuesConf.value().toList());
                if (flashValues.size() == 1 &&
                    flashValues.at(0).toInt() == QCameraExposure::FlashOff) {
                    HDEBUG("Flash disabled by" << qPrintable(flashValuesKey));
                } else {
                    torchSupported = true;
                    HDEBUG("Torch supported");
                }
            }
        }
    }

    QLocale locale;
    QTranslator* translator = new QTranslator(app.data());
    QString transDir = SailfishApp::pathTo("translations").toLocalFile();
    QString transFile("harbour-barcode");
    if (translator->load(locale, transFile, "-", transDir) ||
        translator->load(transFile, transDir)) {
        app->installTranslator(translator);
    } else {
        HWARN("Failed to load translator for" << locale);
        delete translator;
    }

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    QQmlEngine* engine = view->engine();
    register_types(engine, "harbour.barcode", 1, 0);
    engine->addImageProvider("scanner", new CaptureImageProvider());

    Settings* settings = new Settings(app.data());
    Database::initialize(engine, settings);

    QQmlContext* root = view->rootContext();
    root->setContextProperty("AppVersion", APP_VERSION);
    root->setContextProperty("AppSettings", settings);
    root->setContextProperty("TorchSupported", torchSupported);

    view->setSource(SailfishApp::pathTo("qml/harbour-barcode.qml"));
    view->setTitle("CodeReader");
    view->showFullScreen();
    return app->exec();
}
