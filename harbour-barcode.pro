# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
NAME = barcode
PREFIX = harbour
TARGET = $${PREFIX}-$${NAME}

CONFIG += sailfishapp

QT += multimedia \
    concurrent

isEmpty(VERSION) {
    VERSION = 1.0.2
    message("VERSION is unset, assuming $$VERSION")
}

DEFINES += APP_VERSION=\\\"$$VERSION\\\"

INCLUDEPATH += src

CONFIG(debug, debug|release) {
    DEFINES += DEBUG LOG_DEBUG
}

SOURCES += \
    src/harbour-barcode.cpp \
    src/scanner/ImagePostProcessing.cpp \
    src/scanner/AutoBarcodeScanner.cpp \
    src/scanner/CaptureImageProvider.cpp

OTHER_FILES += \
    qml/cover/CoverPage.qml \
    rpm/harbour-barcode.spec \
    translations/*.ts \
    icons/*.svg \
    README.md \
    harbour-barcode.desktop \
    qml/harbour-barcode.qml \
    qml/pages/AboutPage.qml \
    qml/components/LabelText.qml \
    qml/cover/cover-image.svg \
    qml/pages/img/upc_240.png \
    qml/pages/img/qr-code_240.png \
    qml/pages/img/interleaved_240.png \
    qml/pages/img/ean-13_240.png \
    qml/pages/img/datamatrix_240.png \
    qml/pages/img/code-128_240.png \
    qml/pages/img/aztec_240.png \
    qml/pages/AutoScanPage.qml \
    qml/pages/SettingsPage.qml \
    qml/js/Settings.js \
    qml/js/LocalStore.js \
    qml/pages/TextPage.qml \
    qml/js/History.js \
    qml/pages/HistoryPage.qml \
    qml/js/Utils.js

# include library qzxing
include(src/scanner/qzxing/QZXing.pri)

HEADERS += \
    src/DebugLog.h \
    src/scanner/ImagePostProcessing.h \
    src/scanner/AutoBarcodeScanner.h \
    src/scanner/CaptureImageProvider.h

# Icons
ICON_SIZES = 86 108 128 256
for(s, ICON_SIZES) {
    icon_target = icon$${s}
    icon_dir = icons/$${s}x$${s}
    $${icon_target}.files = $${icon_dir}/$${TARGET}.png
    $${icon_target}.path = /usr/share/icons/hicolor/$${s}x$${s}/apps
    INSTALLS += $${icon_target}
}

# Translations
TRANSLATIONS_PATH = /usr/share/$${TARGET}/translations
TRANSLATION_SOURCES = \
  $${_PRO_FILE_PWD_}/qml

defineTest(addTrFile) {
    in = $${_PRO_FILE_PWD_}/translations/harbour-$$1
    out = $${OUT_PWD}/translations/$${PREFIX}-$$1

    s = $$replace(1,-,_)
    lupdate_target = lupdate_$$s
    lrelease_target = lrelease_$$s

    $${lupdate_target}.commands = lupdate -noobsolete $${TRANSLATION_SOURCES} -ts \"$${in}.ts\" && \
        mkdir -p \"$${OUT_PWD}/translations\" &&  [ \"$${in}.ts\" != \"$${out}.ts\" ] && \
        cp -af \"$${in}.ts\" \"$${out}.ts\" || :

    $${lrelease_target}.target = $${out}.qm
    $${lrelease_target}.depends = $${lupdate_target}
    $${lrelease_target}.commands = lrelease -idbased \"$${out}.ts\"

    QMAKE_EXTRA_TARGETS += $${lrelease_target} $${lupdate_target}
    PRE_TARGETDEPS += $${out}.qm
    qm.files += $${out}.qm

    export($${lupdate_target}.commands)
    export($${lrelease_target}.target)
    export($${lrelease_target}.depends)
    export($${lrelease_target}.commands)
    export(QMAKE_EXTRA_TARGETS)
    export(PRE_TARGETDEPS)
    export(qm.files)
}

LANGUAGES = cs da de es fr hu it ru sv zh_CN zh_TW

addTrFile($${NAME})
for(l, LANGUAGES) {
    addTrFile($${NAME}-$$l)
}

qm.path = $$TRANSLATIONS_PATH
qm.CONFIG += no_check_exist
INSTALLS += qm

