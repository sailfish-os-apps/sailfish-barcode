#include <sailfishapp.h>
#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>

#include "scanner/BarcodeDecoder.h"
#include "scanner/AutoBarcodeScanner.h"
#include "scanner/CaptureImageProvider.h"

#ifndef APP_VERSION
#  define ""
#endif

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    qmlRegisterType<AutoBarcodeScanner>("harbour.barcode.AutoBarcodeScanner", 1, 0, "AutoBarcodeScanner");

    view->engine()->addImageProvider("scanner", new CaptureImageProvider());
    view->rootContext()->setContextProperty("AppVersion", APP_VERSION);
    view->setSource(SailfishApp::pathTo("qml/harbour-barcode.qml"));
    view->setTitle("CodeReader");
    view->showFullScreen();

    return app->exec();
}
