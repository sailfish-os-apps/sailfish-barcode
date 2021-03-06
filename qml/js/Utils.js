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

.pragma library

function isVcard(text) {
    if (text !== "") {
        var vcard = text.match(/^(BEGIN:VCARD(\r|\n)+)/)
        return vcard && vcard.length > 0
    }
    return false
}

function isLink(text) {
    if (text !== "") {
        var urls = text.match(/^(http[s]*:\/\/.{3,500}|www\..{3,500}|sms:.*)$/)
        // is a known url scheme and not a vcard
        return urls && urls.length > 0 && !isVcard(text)
    }
    return false
}

function isText(text) {
    return !isLink(text);
}

function removeLineBreak(text) {
    return text.replace(/(\r|\n)+/g, ' ')
}

function convertLineBreaks(text) {
    return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
}

function getValueText(value) {
    if (isLink(value)) {
        return value
    } else {
        return removeLineBreak(value)
    }
}

function barcodeFormat(format) {
    if (format == "AZTEC") {
        return "Aztec"
    } else if (format == "CODABAR") {
        return "Codabar"
    } else if (format == "CODE_39") {
        return "Code 39"
    } else if (format == "CODE_93") {
        return "Code 93"
    } else if (format == "CODE_128") {
        return "Code 128"
    } else if (format == "DATA_MATRIX") {
        return "Data Matrix"
    } else if (format == "EAN_8") {
        return "EAN-8"
    } else if (format == "EAN_13") {
        return "EAN-13"
    } else if (format == "ITF") {
        return "ITF-14"
    } else if (format == "MAXICODE") {
        return "MaxiCode"
    } else if (format == "PDF_417") {
        return "PDF417"
    } else if (format == "QR_CODE") {
        return "QR Code"
    } else if (format == "RSS_14") {
        return "RSS-14"
    } else if (format == "RSS_EXPANDED") {
        return "RSS"
    } else if (format == "UPC_A") {
        return "UPC-A"
    } else if (format == "UPC_E") {
        return "UPC-E"
    } else if (format == "UPC_EAN_EXTENSION") {
        return "EAN"
    } else if (format == "ASSUME_GS1") {
        return "GS1"
    } else {
        return ""
    }
}
