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

CONFIG += sailfishapp link_pkgconfig
PKGCONFIG += sailfishapp mlite5

QT += multimedia \
    concurrent

isEmpty(VERSION) {
    VERSION = 1.0.4
    message("VERSION is unset, assuming $$VERSION")
}

DEFINES += APP_VERSION=\\\"$$VERSION\\\"

INCLUDEPATH += src src/zxing

CONFIG(debug, debug|release) {
    DEFINES += DEBUG LOG_DEBUG
}

SOURCES += \
    src/harbour-barcode.cpp \
    src/scanner/AutoBarcodeScanner.cpp \
    src/scanner/CaptureImageProvider.cpp \
    src/scanner/Decoder.cpp \
    src/scanner/ImageSource.cpp

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

HEADERS += \
    src/DebugLog.h \
    src/scanner/AutoBarcodeScanner.h \
    src/scanner/CaptureImageProvider.h \
    src/scanner/Decoder.h \
    src/scanner/ImageSource.h

# zxing

SOURCES += \
    src/zxing/bigint/BigIntegerAlgorithms.cc \
    src/zxing/bigint/BigInteger.cc \
    src/zxing/bigint/BigIntegerUtils.cc \
    src/zxing/bigint/BigUnsigned.cc \
    src/zxing/bigint/BigUnsignedInABase.cc

HEADERS += \
    src/zxing/bigint/BigIntegerAlgorithms.hh \
    src/zxing/bigint/BigInteger.hh \
    src/zxing/bigint/BigIntegerLibrary.hh \
    src/zxing/bigint/BigIntegerUtils.hh \
    src/zxing/bigint/BigUnsigned.hh \
    src/zxing/bigint/BigUnsignedInABase.hh \
    src/zxing/bigint/NumberlikeArray.hh

SOURCES += \
    src/zxing/zxing/common/BitArray.cpp \
    src/zxing/zxing/common/BitArrayIO.cpp \
    src/zxing/zxing/common/BitMatrix.cpp \
    src/zxing/zxing/common/BitSource.cpp \
    src/zxing/zxing/common/CharacterSetECI.cpp \
    src/zxing/zxing/common/DecoderResult.cpp \
    src/zxing/zxing/common/DetectorResult.cpp \
    src/zxing/zxing/common/GlobalHistogramBinarizer.cpp \
    src/zxing/zxing/common/GreyscaleLuminanceSource.cpp \
    src/zxing/zxing/common/GreyscaleRotatedLuminanceSource.cpp \
    src/zxing/zxing/common/GridSampler.cpp \
    src/zxing/zxing/common/HybridBinarizer.cpp \
    src/zxing/zxing/common/IllegalArgumentException.cpp \
    src/zxing/zxing/common/PerspectiveTransform.cpp \
    src/zxing/zxing/common/Str.cpp \
    src/zxing/zxing/common/StringUtils.cpp

HEADERS += \
    src/zxing/zxing/common/Array.h \
    src/zxing/zxing/common/BitArray.h \
    src/zxing/zxing/common/BitMatrix.h \
    src/zxing/zxing/common/BitSource.h \
    src/zxing/zxing/common/CharacterSetECI.h \
    src/zxing/zxing/common/Counted.h \
    src/zxing/zxing/common/DecoderResult.h \
    src/zxing/zxing/common/DetectorResult.h \
    src/zxing/zxing/common/GlobalHistogramBinarizer.h \
    src/zxing/zxing/common/GreyscaleLuminanceSource.h \
    src/zxing/zxing/common/GreyscaleRotatedLuminanceSource.h \
    src/zxing/zxing/common/GridSampler.h \
    src/zxing/zxing/common/HybridBinarizer.h \
    src/zxing/zxing/common/IllegalArgumentException.h \
    src/zxing/zxing/common/PerspectiveTransform.h \
    src/zxing/zxing/common/Point.h \
    src/zxing/zxing/common/Str.h \
    src/zxing/zxing/common/StringUtils.h \
    src/zxing/zxing/common/Types.h

SOURCES += \
    src/zxing/zxing/common/detector/MonochromeRectangleDetector.cpp \
    src/zxing/zxing/common/detector/WhiteRectangleDetector.cpp

HEADERS += \
    src/zxing/zxing/common/detector/JavaMath.h \
    src/zxing/zxing/common/detector/MathUtils.h \
    src/zxing/zxing/common/detector/MonochromeRectangleDetector.h \
    src/zxing/zxing/common/detector/WhiteRectangleDetector.h

SOURCES += \
    src/zxing/zxing/common/reedsolomon/GenericGF.cpp \
    src/zxing/zxing/common/reedsolomon/GenericGFPoly.cpp \
    src/zxing/zxing/common/reedsolomon/ReedSolomonDecoder.cpp \
    src/zxing/zxing/common/reedsolomon/ReedSolomonEncoder.cpp \
    src/zxing/zxing/common/reedsolomon/ReedSolomonException.cpp

HEADERS += \
    src/zxing/zxing/common/reedsolomon/GenericGF.h \
    src/zxing/zxing/common/reedsolomon/GenericGFPoly.h \
    src/zxing/zxing/common/reedsolomon/ReedSolomonDecoder.h \
    src/zxing/zxing/common/reedsolomon/ReedSolomonEncoder.h \
    src/zxing/zxing/common/reedsolomon/ReedSolomonException.h

SOURCES += \
    src/zxing/zxing/BarcodeFormat.cpp \
    src/zxing/zxing/Binarizer.cpp \
    src/zxing/zxing/BinaryBitmap.cpp \
    src/zxing/zxing/ChecksumException.cpp \
    src/zxing/zxing/DecodeHints.cpp \
    src/zxing/zxing/EncodeHint.cpp \
    src/zxing/zxing/Exception.cpp \
    src/zxing/zxing/FormatException.cpp \
    src/zxing/zxing/InvertedLuminanceSource.cpp \
    src/zxing/zxing/LuminanceSource.cpp \
    src/zxing/zxing/MultiFormatReader.cpp \
    src/zxing/zxing/Reader.cpp \
    src/zxing/zxing/Result.cpp \
    src/zxing/zxing/ResultIO.cpp \
    src/zxing/zxing/ResultPointCallback.cpp \
    src/zxing/zxing/ResultPoint.cpp

HEADERS += \
    src/zxing/zxing/BarcodeFormat.h \
    src/zxing/zxing/Binarizer.h \
    src/zxing/zxing/BinaryBitmap.h \
    src/zxing/zxing/ChecksumException.h \
    src/zxing/zxing/DecodeHints.h \
    src/zxing/zxing/EncodeHint.h \
    src/zxing/zxing/Exception.h \
    src/zxing/zxing/FormatException.h \
    src/zxing/zxing/IllegalStateException.h \
    src/zxing/zxing/InvertedLuminanceSource.h \
    src/zxing/zxing/LuminanceSource.h \
    src/zxing/zxing/MultiFormatReader.h \
    src/zxing/zxing/NotFoundException.h \
    src/zxing/zxing/ReaderException.h \
    src/zxing/zxing/Reader.h \
    src/zxing/zxing/Result.h \
    src/zxing/zxing/ResultPointCallback.h \
    src/zxing/zxing/ResultPoint.h \
    src/zxing/zxing/UnsupportedEncodingException.h \
    src/zxing/zxing/WriterException.h \
    src/zxing/zxing/ZXing.h

SOURCES += \
    src/zxing/zxing/aztec/AztecDetectorResult.cpp \
    src/zxing/zxing/aztec/AztecReader.cpp \
    src/zxing/zxing/aztec/decoder/AztecDecoder.cpp \
    src/zxing/zxing/aztec/detector/AztecDetector.cpp

HEADERS += \
    src/zxing/zxing/aztec/AztecDetectorResult.h \
    src/zxing/zxing/aztec/AztecReader.h \
    src/zxing/zxing/aztec/decoder/Decoder.h \
    src/zxing/zxing/aztec/detector/Detector.h

SOURCES += \
    src/zxing/zxing/multi/GenericMultipleBarcodeReader.cpp \
    src/zxing/zxing/multi/MultipleBarcodeReader.cpp \
    src/zxing/zxing/multi/ByQuadrantReader.cpp \
    src/zxing/zxing/multi/qrcode/QRCodeMultiReader.cpp \
    src/zxing/zxing/multi/qrcode/detector/MultiDetector.cpp \
    src/zxing/zxing/multi/qrcode/detector/MultiFinderPatternFinder.cpp

HEADERS += \
    src/zxing/zxing/multi/ByQuadrantReader.h \
    src/zxing/zxing/multi/GenericMultipleBarcodeReader.h \
    src/zxing/zxing/multi/MultipleBarcodeReader.h \
    src/zxing/zxing/multi/qrcode/QRCodeMultiReader.h \
    src/zxing/zxing/multi/qrcode/detector/MultiDetector.h \
    src/zxing/zxing/multi/qrcode/detector/MultiFinderPatternFinder.h

SOURCES += \
    src/zxing/zxing/oned/CodaBarReader.cpp \
    src/zxing/zxing/oned/Code128Reader.cpp \
    src/zxing/zxing/oned/Code39Reader.cpp \
    src/zxing/zxing/oned/Code93Reader.cpp \
    src/zxing/zxing/oned/EAN13Reader.cpp \
    src/zxing/zxing/oned/EAN8Reader.cpp \
    src/zxing/zxing/oned/ITFReader.cpp \
    src/zxing/zxing/oned/MultiFormatOneDReader.cpp \
    src/zxing/zxing/oned/MultiFormatUPCEANReader.cpp \
    src/zxing/zxing/oned/OneDReader.cpp \
    src/zxing/zxing/oned/OneDResultPoint.cpp \
    src/zxing/zxing/oned/UPCAReader.cpp \
    src/zxing/zxing/oned/UPCEANReader.cpp \
    src/zxing/zxing/oned/UPCEReader.cpp

HEADERS += \
    src/zxing/zxing/oned/CodaBarReader.h \
    src/zxing/zxing/oned/Code128Reader.h \
    src/zxing/zxing/oned/Code39Reader.h \
    src/zxing/zxing/oned/Code93Reader.h \
    src/zxing/zxing/oned/EAN13Reader.h \
    src/zxing/zxing/oned/EAN8Reader.h \
    src/zxing/zxing/oned/ITFReader.h \
    src/zxing/zxing/oned/MultiFormatOneDReader.h \
    src/zxing/zxing/oned/MultiFormatUPCEANReader.h \
    src/zxing/zxing/oned/OneDReader.h \
    src/zxing/zxing/oned/OneDResultPoint.h \
    src/zxing/zxing/oned/UPCAReader.h \
    src/zxing/zxing/oned/UPCEANReader.h \
    src/zxing/zxing/oned/UPCEReader.h

SOURCES += \
    src/zxing/zxing/pdf417/PDF417Reader.cpp \
    src/zxing/zxing/pdf417/decoder/ec/ErrorCorrection.cpp \
    src/zxing/zxing/pdf417/decoder/ec/ModulusGF.cpp \
    src/zxing/zxing/pdf417/decoder/ec/ModulusPoly.cpp \
    src/zxing/zxing/pdf417/decoder/PDF417BitMatrixParser.cpp \
    src/zxing/zxing/pdf417/decoder/PDF417DecodedBitStreamParser.cpp \
    src/zxing/zxing/pdf417/decoder/PDF417Decoder.cpp \
    src/zxing/zxing/pdf417/detector/LinesSampler.cpp \
    src/zxing/zxing/pdf417/detector/PDF417Detector.cpp

HEADERS += \
    src/zxing/zxing/pdf417/PDF417Reader.h \
    src/zxing/zxing/pdf417/decoder/BitMatrixParser.h \
    src/zxing/zxing/pdf417/decoder/DecodedBitStreamParser.h \
    src/zxing/zxing/pdf417/decoder/Decoder.h \
    src/zxing/zxing/pdf417/decoder/ec/ErrorCorrection.h \
    src/zxing/zxing/pdf417/decoder/ec/ModulusGF.h \
    src/zxing/zxing/pdf417/decoder/ec/ModulusPoly.h \
    src/zxing/zxing/pdf417/detector/Detector.h \
    src/zxing/zxing/pdf417/detector/LinesSampler.h

SOURCES += \
    src/zxing/zxing/qrcode/QRCodeReader.cpp \
    src/zxing/zxing/qrcode/QRErrorCorrectionLevel.cpp \
    src/zxing/zxing/qrcode/QRFormatInformation.cpp \
    src/zxing/zxing/qrcode/QRVersion.cpp \
    src/zxing/zxing/qrcode/decoder/QRBitMatrixParser.cpp \
    src/zxing/zxing/qrcode/decoder/QRDataBlock.cpp \
    src/zxing/zxing/qrcode/decoder/QRDataMask.cpp \
    src/zxing/zxing/qrcode/decoder/QRDecodedBitStreamParser.cpp \
    src/zxing/zxing/qrcode/decoder/QRDecoder.cpp \
    src/zxing/zxing/qrcode/decoder/QRMode.cpp \
    src/zxing/zxing/qrcode/detector/QRAlignmentPattern.cpp \
    src/zxing/zxing/qrcode/detector/QRAlignmentPatternFinder.cpp \
    src/zxing/zxing/qrcode/detector/QRDetector.cpp \
    src/zxing/zxing/qrcode/detector/QRFinderPattern.cpp \
    src/zxing/zxing/qrcode/detector/QRFinderPatternFinder.cpp \
    src/zxing/zxing/qrcode/detector/QRFinderPatternInfo.cpp \
    src/zxing/zxing/qrcode/encoder/ByteMatrix.cpp \
    src/zxing/zxing/qrcode/encoder/MaskUtil.cpp \
    src/zxing/zxing/qrcode/encoder/MatrixUtil.cpp \
    src/zxing/zxing/qrcode/encoder/QRCode.cpp \
    src/zxing/zxing/qrcode/encoder/QREncoder.cpp

HEADERS += \
    src/zxing/zxing/qrcode/decoder/BitMatrixParser.h \
    src/zxing/zxing/qrcode/decoder/DataBlock.h \
    src/zxing/zxing/qrcode/decoder/DataMask.h \
    src/zxing/zxing/qrcode/decoder/DecodedBitStreamParser.h \
    src/zxing/zxing/qrcode/decoder/Decoder.h \
    src/zxing/zxing/qrcode/decoder/Mode.h \
    src/zxing/zxing/qrcode/detector/AlignmentPatternFinder.h \
    src/zxing/zxing/qrcode/detector/AlignmentPattern.h \
    src/zxing/zxing/qrcode/detector/Detector.h \
    src/zxing/zxing/qrcode/detector/FinderPatternFinder.h \
    src/zxing/zxing/qrcode/detector/FinderPattern.h \
    src/zxing/zxing/qrcode/detector/FinderPatternInfo.h \
    src/zxing/zxing/qrcode/encoder/BlockPair.h \
    src/zxing/zxing/qrcode/encoder/ByteMatrix.h \
    src/zxing/zxing/qrcode/encoder/Encoder.h \
    src/zxing/zxing/qrcode/encoder/MaskUtil.h \
    src/zxing/zxing/qrcode/encoder/MatrixUtil.h \
    src/zxing/zxing/qrcode/encoder/QRCode.h \
    src/zxing/zxing/qrcode/ErrorCorrectionLevel.h \
    src/zxing/zxing/qrcode/FormatInformation.h \
    src/zxing/zxing/qrcode/QRCodeReader.h \
    src/zxing/zxing/qrcode/Version.h

SOURCES += \
    src/zxing/zxing/datamatrix/DataMatrixReader.cpp \
    src/zxing/zxing/datamatrix/DataMatrixVersion.cpp \
    src/zxing/zxing/datamatrix/decoder/DataMatrixBitMatrixParser.cpp \
    src/zxing/zxing/datamatrix/decoder/DataMatrixDataBlock.cpp \
    src/zxing/zxing/datamatrix/decoder/DataMatrixDecodedBitStreamParser.cpp \
    src/zxing/zxing/datamatrix/decoder/DataMatrixDecoder.cpp \
    src/zxing/zxing/datamatrix/detector/DataMatrixCornerPoint.cpp \
    src/zxing/zxing/datamatrix/detector/DataMatrixDetector.cpp \
    src/zxing/zxing/datamatrix/detector/DataMatrixDetectorException.cpp

HEADERS += \
    src/zxing/zxing/datamatrix/DataMatrixReader.h \
    src/zxing/zxing/datamatrix/decoder/BitMatrixParser.h \
    src/zxing/zxing/datamatrix/decoder/DataBlock.h \
    src/zxing/zxing/datamatrix/decoder/DecodedBitStreamParser.h \
    src/zxing/zxing/datamatrix/decoder/Decoder.h \
    src/zxing/zxing/datamatrix/detector/CornerPoint.h \
    src/zxing/zxing/datamatrix/detector/DetectorException.h \
    src/zxing/zxing/datamatrix/detector/Detector.h \
    src/zxing/zxing/datamatrix/Version.h

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

