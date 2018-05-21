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

#include "DebugLog.h"
#include "Database.h"
#include "HistoryModel.h"
#include "Settings.h"

#include <QQmlEngine>
#include <QCryptographicHash>
#include <QDir>

#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>

#define SETTINGS_TABLE          "settings"
#define SETTINGS_FIELD_KEY      "key"
#define SETTINGS_FIELD_VALUE    "value"

// ==========================================================================
// Database::Private
// ==========================================================================

class Database::Private {
public:
    static const QString DB_TYPE;
    static const QString DB_NAME;

    static QString gDatabasePath;

    typedef void (Settings::*SetBool)(bool aValue);
    typedef void (Settings::*SetInt)(int aValue);
    typedef void (Settings::*SetString)(QString aValue);

    static QVariant settingsValue(QSqlDatabase aDb, QString aKey);
    static void migrateBool(QSqlDatabase aDb, QString aKey,
        Settings* aSettings, SetBool aSetter);
    static void migrateInt(QSqlDatabase aDb, QString aKey,
        Settings* aSettings, SetInt aSetter);
    static void migrateString(QSqlDatabase aDb, QString aKey,
        Settings* aSettings, SetString aSetter);
};

const QString Database::Private::DB_TYPE("QSQLITE");
const QString Database::Private::DB_NAME("CodeReader");

QString Database::Private::gDatabasePath;

QVariant Database::Private::settingsValue(QSqlDatabase aDb, QString aKey)
{
    QSqlQuery query(aDb);
    query.prepare("SELECT value FROM settings WHERE key = ?");
    query.addBindValue(aKey);
    if (query.exec()) {
        if (query.next()) {
            QVariant result = query.value(0);
            if (result.isValid()) {
               DLOG(aKey << result);
                return result;
            }
        } else {
            WARN(aKey << query.lastError());
        }
    } else {
        WARN(aKey << query.lastError());
    }
    return QVariant();
}

void Database::Private::migrateBool(QSqlDatabase aDb, QString aKey,
    Settings* aSettings, SetBool aSetter)
{
    QVariant value = settingsValue(aDb, aKey);
    if (value.isValid()) {
        bool bval = value.toBool();
        DLOG(aKey << "=" << bval);
        (aSettings->*aSetter)(bval);
    }
}

void Database::Private::migrateInt(QSqlDatabase aDb, QString aKey,
    Settings* aSettings, SetInt aSetter)
{
    QVariant value = settingsValue(aDb, aKey);
    if (value.isValid()) {
        bool ok;
        int ival = value.toInt(&ok);
        if (ok) {
            DLOG(aKey << "=" << ival);
            (aSettings->*aSetter)(ival);
        } else {
            // JavaScript was storing some integers as floating point
            // e.g. "result_view_duration" = "4.0"
            double dval = value.toDouble(&ok);
            if (ok) {
                ival = round(dval);
                DLOG(aKey << "=" << ival);
                (aSettings->*aSetter)(ival);
            } else {
                WARN("Can't convert" << value.toString() << "to int");
            }
        }
    }
}

void Database::Private::migrateString(QSqlDatabase aDb, QString aKey,
    Settings* aSettings, SetString aSetter)
{
    QVariant value = settingsValue(aDb, aKey);
    if (value.isValid()) {
        QString str(value.toString());
        DLOG(aKey << "=" << str);
        (aSettings->*aSetter)(str);
    }
}

// ==========================================================================
// Database
// ==========================================================================

void Database::initialize(QQmlEngine* aEngine, Settings* aSettings)
{
    QDir dir(aEngine->offlineStoragePath() + QDir::separator() +
        QLatin1String("Databases"));
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    // This is how LocalStorage plugin generates database file name
    QCryptographicHash md5(QCryptographicHash::Md5);
    md5.addData(Private::DB_NAME.toUtf8());
    Private::gDatabasePath = dir.path() + QDir::separator() +
        QLatin1String(md5.result().toHex()) + QLatin1String(".sqlite");

    DLOG("Database path:" << qPrintable(Private::gDatabasePath));

    QSqlDatabase db = QSqlDatabase::database(Private::DB_NAME);
    if (!db.isValid()) {
        DLOG("Adding database" << Private::DB_NAME);
        db = QSqlDatabase::addDatabase(Private::DB_TYPE, Private::DB_NAME);
    }
    db.setDatabaseName(Private::gDatabasePath);

    QStringList tables;
    if (db.open()) {
        tables = db.tables();
        DLOG(tables);
    } else {
        WARN(db.lastError());
    }

    // Check if we need to upgrade or initialize the database
    QString history(HISTORY_TABLE);
    if (tables.contains(history)) {
        // The history table is there, check if we need to upgrade it
        QSqlRecord record(db.record(history));
        if (record.indexOf(HISTORY_FIELD_FORMAT) < 0) {
            // There's no format field, need to add one
            DLOG("Upgrading the database");
            QSqlQuery query(db);
            query.prepare("ALTER TABLE " HISTORY_TABLE " ADD COLUMN "
                HISTORY_FIELD_FORMAT " TEXT DEFAULT ''");
            if (!query.exec()) {
                WARN(query.lastError());
            }
        }
        if (tables.contains(SETTINGS_TABLE)) {
            // The settings table is there, copy those to dconf
            DLOG("Migrating settings");
            Private::migrateBool(db, KEY_SOUND,
                aSettings, &Settings::setSound);
            Private::migrateInt(db, KEY_DIGITAL_ZOOM,
                aSettings, &Settings::setDigitalZoom);
            Private::migrateInt(db, KEY_SCAN_DURATION,
                aSettings, &Settings::setScanDuration);
            Private::migrateInt(db, KEY_RESULT_VIEW_DURATION,
                aSettings, &Settings::setResultViewDuration);
            Private::migrateString(db, KEY_MARKER_COLOR,
                aSettings, &Settings::setMarkerColor);
            Private::migrateInt(db, KEY_HISTORY_SIZE,
                aSettings, &Settings::setHistorySize);
            Private::migrateBool(db, KEY_SCAN_ON_START,
                aSettings, &Settings::setScanOnStart);

            // And drop the table when we are done
            QSqlQuery query(db);
            query.prepare("DROP TABLE IF EXISTS " SETTINGS_TABLE);
            if (!query.exec()) {
                WARN(query.lastError());
            }
        }
    } else {
        // The database doesn't seem to exist at all (fresh install)
        DLOG("Initializing the database");
        QSqlQuery query(db);
        if (!query.exec("CREATE TABLE " HISTORY_TABLE " ("
            HISTORY_FIELD_VALUE " TEXT, "
            HISTORY_FIELD_TIMESTAMP " TEXT, "
            HISTORY_FIELD_FORMAT " TEXT)")) {
            WARN(query.lastError());
        }
    }
}

QSqlDatabase Database::database()
{
    QSqlDatabase db = QSqlDatabase::database(Private::DB_NAME);
    ASSERT(db.isValid());
    return db;
}
