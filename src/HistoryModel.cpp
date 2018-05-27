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

#include "HistoryModel.h"
#include "Database.h"
#include "scanner/CaptureImageProvider.h"

#include "HarbourDebug.h"
#include "HarbourTask.h"

#include <QDirIterator>
#include <QThreadPool>
#include <QFileInfo>
#include <QImage>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlTableModel>

#define DEFAULT_MAX_COUNT (100)

// ==========================================================================
// HistoryModel::CleanupTask
// Removes image files not associated with any rows in the database
// ==========================================================================

class HistoryModel::CleanupTask : public HarbourTask {
    Q_OBJECT
public:
    CleanupTask(QThreadPool* aPool, QStringList aList);
    void performTask() Q_DECL_OVERRIDE;

public:
    QStringList iList;
};

HistoryModel::CleanupTask::CleanupTask(QThreadPool* aPool, QStringList aList) :
    HarbourTask(aPool), iList(aList)
{
}

void HistoryModel::CleanupTask::performTask()
{
    QDirIterator it(Database::imageDir().path(), QDir::Files);
    while (it.hasNext()) {
        it.next();
        const QString name(it.fileName());
        if (name.endsWith(CaptureImageProvider::IMAGE_EXT)) {
            const QString base(name.left(name.length() -
                CaptureImageProvider::IMAGE_EXT.length()));
            const int pos = iList.indexOf(base);
            if (pos >= 0) {
                iList.removeAt(pos);
            } else {
                const QString path(it.filePath());
                HDEBUG("deleting" << base << qPrintable(path));
                if (!QFile::remove(path)) {
                    HWARN("Failed to delete" << qPrintable(path));
                }
            }
        }
    }
    HDEBUG("done");
}

// ==========================================================================
// HistoryModel::SaveTask
// ==========================================================================

class HistoryModel::SaveTask : public HarbourTask {
    Q_OBJECT
public:
    SaveTask(QThreadPool* aPool, QImage aImage, QString aId);
    void performTask() Q_DECL_OVERRIDE;

public:
    QImage iImage;
    QString iId;
    QString iName;
};

HistoryModel::SaveTask::SaveTask(QThreadPool* aPool, QImage aImage, QString aId) :
    HarbourTask(aPool), iImage(aImage), iId(aId),
    iName(aId + CaptureImageProvider::IMAGE_EXT)
{
}

void HistoryModel::SaveTask::performTask()
{
    QDir dir(Database::imageDir());
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    const QString path(dir.path() + QDir::separator() + iName);
    HDEBUG(qPrintable(path));
    if (!iImage.save(path)) {
        HWARN("Fails to save" << qPrintable(path));
    }
    HDEBUG("done");
}

// ==========================================================================
// HistoryModel::PurgeTask
// ==========================================================================

class HistoryModel::PurgeTask : public HarbourTask {
    Q_OBJECT
public:
    PurgeTask(QThreadPool* aPool) : HarbourTask(aPool) {}
    void performTask() Q_DECL_OVERRIDE;
};

void HistoryModel::PurgeTask::performTask()
{
    QDirIterator it(Database::imageDir().path(), QDir::Files);
    while (it.hasNext()) {
        it.next();
        const QString name(it.fileName());
        if (name.endsWith(CaptureImageProvider::IMAGE_EXT)) {
            bool ok = false;
            const QString base(name.left(name.length() -
                CaptureImageProvider::IMAGE_EXT.length()));
            base.toInt(&ok);
            if (ok) {
                const QString path(it.filePath());
                HDEBUG("deleting" << base << qPrintable(path));
                if (!QFile::remove(path)) {
                    HWARN("Failed to delete" << qPrintable(path));
                }
            }
        }
    }
    HDEBUG("done");
}

// ==========================================================================
// HistoryModel::Private
// ==========================================================================

class HistoryModel::Private : public QSqlTableModel {
    Q_OBJECT
public:
    enum {
        FIELD_ID,
        FIELD_VALUE,
        FIELD_TIMESTAMP, // DB_SORT_COLUMN (see below)
        FIELD_FORMAT,
        NUM_FIELDS
    };
    static const int DB_SORT_COLUMN = FIELD_TIMESTAMP;
    static const QString DB_TABLE;
    static const QString DB_FIELD[NUM_FIELDS];

#define DB_FIELD_ID DB_FIELD[HistoryModel::Private::FIELD_ID]
#define DB_FIELD_VALUE DB_FIELD[HistoryModel::Private::FIELD_VALUE]
#define DB_FIELD_TIMESTAMP DB_FIELD[HistoryModel::Private::FIELD_TIMESTAMP]
#define DB_FIELD_FORMAT DB_FIELD[HistoryModel::Private::FIELD_FORMAT]

    Private(HistoryModel* aModel);
    ~Private();

    HistoryModel* historyModel() const;
    QVariant valueAt(int aRow, int aField) const;
    bool removeExtraRows(int aReserve = 0);
    void commitChanges();
    void cleanupFiles();

    QHash<int,QByteArray> roleNames() const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex& aIndex, int aRole) const Q_DECL_OVERRIDE;

private Q_SLOTS:
    void onSaveDone();

public:
    QThreadPool* iThreadPool;
    bool iSaveImages;
    int iMaxCount;
    int iLastKnownCount;
    int iFieldIndex[NUM_FIELDS];
};

const QString HistoryModel::Private::DB_TABLE(QLatin1String(HISTORY_TABLE));
const QString HistoryModel::Private::DB_FIELD[] = {
    QLatin1String(HISTORY_FIELD_ID),
    QLatin1String(HISTORY_FIELD_VALUE),
    QLatin1String(HISTORY_FIELD_TIMESTAMP),
    QLatin1String(HISTORY_FIELD_FORMAT)
};

HistoryModel::Private::Private(HistoryModel* aPublicModel) :
    QSqlTableModel(aPublicModel, Database::database()),
    iThreadPool(new QThreadPool(this)),
    iSaveImages(true),
    iMaxCount(DEFAULT_MAX_COUNT),
    iLastKnownCount(0)
{
    iThreadPool->setMaxThreadCount(1);
    for (int i = 0; i < NUM_FIELDS; i++) iFieldIndex[i] = -1;
    QSqlDatabase db = database();
    if (db.open()) {
        HDEBUG("database opened");
        setTable(DB_TABLE);
        select();
        for (int i = 0; i < NUM_FIELDS; i++) {
            const QString name(DB_FIELD[i]);
            iFieldIndex[i] = fieldIndex(name);
            HDEBUG(iFieldIndex[i] << name);
        }
    } else {
        HWARN(db.lastError());
    }
    const int sortColumn = iFieldIndex[DB_SORT_COLUMN];
    if (sortColumn >= 0) {
        HDEBUG("sort column" << sortColumn);
        setSort(sortColumn, Qt::DescendingOrder);
        sort(sortColumn, Qt::DescendingOrder);
    }
    setEditStrategy(QSqlTableModel::OnManualSubmit);
    // At startup we assume that images are being saved
    cleanupFiles();
}

HistoryModel::Private::~Private()
{
    commitChanges();
    iThreadPool->waitForDone();
}

HistoryModel* HistoryModel::Private::historyModel() const
{
    return qobject_cast<HistoryModel*>(QObject::parent());
}

QHash<int,QByteArray> HistoryModel::Private::roleNames() const
{
    QHash<int,QByteArray> roles;
    for (int i = 0; i < NUM_FIELDS; i++) {
        roles.insert(Qt::UserRole + i, DB_FIELD[i].toUtf8());
    }
    return roles;
}

QVariant HistoryModel::Private::data(const QModelIndex& aIndex, int aRole) const
{
    if (aRole < Qt::UserRole) {
        return QSqlTableModel::data(aIndex, aRole);
    } else if (aRole >= Qt::UserRole) {
        const int i = aRole - Qt::UserRole;
        if (i < NUM_FIELDS) {
            int column = iFieldIndex[i];
            if (column >= 0) {
                return QSqlTableModel::data(index(aIndex.row(), column));
            }
        }
    }
    return QVariant();
}

QVariant HistoryModel::Private::valueAt(int aRow, int aField) const
{
    if (aField >= 0 && aField < NUM_FIELDS) {
        const int column = iFieldIndex[aField];
        if (column >= 0) {
            return QSqlTableModel::data(index(aRow, column));
        }
    }
    return QVariant();
}

bool HistoryModel::Private::removeExtraRows(int aReserve)
{
    if (iMaxCount > 0) {
        HistoryModel* filter = historyModel();
        const int max = qMax(iMaxCount - aReserve, 0);
        const int n = filter->rowCount();
        if (n > max) {
            for (int i = n; i > max; i--) {
                const int row = i - 1;
                QModelIndex index = filter->mapToSource(filter->index(row, 0));
                HDEBUG("Removing row" << row << "(" << index.row() << ")");
                removeRow(index.row());
            }
            return true;
        }
    }
    return false;
}

void HistoryModel::Private::commitChanges()
{
    if (isDirty()) {
        QSqlDatabase db = database();
        db.transaction();
        HDEBUG("Commiting changes");
        if (submitAll()) {
            db.commit();
        } else {
            HWARN(db.lastError());
            db.rollback();
        }
    }
}

void HistoryModel::Private::cleanupFiles()
{
    QSqlQuery query(database());
    query.prepare("SELECT " HISTORY_FIELD_ID " FROM " HISTORY_TABLE);
    if (query.exec()) {
        QStringList ids;
        while (query.next()) {
            ids.append(query.value(0).toString());
        }
        // Submit the cleanup task
        HDEBUG("ids:" << ids);
        HarbourTask* task = new CleanupTask(iThreadPool, ids);
        task->submit();
        task->release();
    } else {
        HWARN(query.lastError());
    }
}

void HistoryModel::Private::onSaveDone()
{
    SaveTask* task = qobject_cast<SaveTask*>(sender());
    HASSERT(task);
    if (task) {
        if (CaptureImageProvider::instance()) {
            CaptureImageProvider::instance()->dropFromCache(task->iId);
        }
        task->release();
    }
}

// ==========================================================================
// HistoryModel
// ==========================================================================

HistoryModel::HistoryModel(QObject* aParent) :
    QSortFilterProxyModel(aParent),
    iPrivate(new Private(this))
{
    setSourceModel(iPrivate);
    setDynamicSortFilter(true);
    if (iPrivate->removeExtraRows()) {
        invalidateFilter();
        commitChanges();
    }
    iPrivate->iLastKnownCount = rowCount();
    connect(this, SIGNAL(rowsInserted(QModelIndex,int,int)), SLOT(checkCount()));
    connect(this, SIGNAL(rowsRemoved(QModelIndex,int,int)), SLOT(checkCount()));
    connect(this, SIGNAL(modelReset()), SLOT(checkCount()));
}

bool HistoryModel::filterAcceptsRow(int aRow, const QModelIndex& aParent) const
{
    return !iPrivate->isDirty(iPrivate->index(aRow, 0, aParent));
}

void HistoryModel::checkCount()
{
    const int count = rowCount();
    if (iPrivate->iLastKnownCount != count) {
        HDEBUG(iPrivate->iLastKnownCount << "=>" << count);
        iPrivate->iLastKnownCount = count;
        Q_EMIT countChanged();
    }
}

int HistoryModel::maxCount() const
{
    return iPrivate->iMaxCount;
}

void HistoryModel::setMaxCount(int aValue)
{
    if (iPrivate->iMaxCount != aValue) {
        iPrivate->iMaxCount = aValue;
        HDEBUG(aValue);
        if (iPrivate->removeExtraRows()) {
            invalidateFilter();
            commitChanges();
            iPrivate->cleanupFiles();
        }
        Q_EMIT maxCountChanged();
    }
}

bool HistoryModel::saveImages() const
{
    return iPrivate->iSaveImages;
}

void HistoryModel::setSaveImages(bool aValue)
{
    if (iPrivate->iSaveImages != aValue) {
        iPrivate->iSaveImages = aValue;
        HDEBUG(aValue);
        if (!aValue) {
            if (CaptureImageProvider::instance()) {
                CaptureImageProvider::instance()->clearCache();
            }
            // Delete all files on a separate thread
            HarbourTask* task = new PurgeTask(iPrivate->iThreadPool);
            task->submit();
            task->release();
        }
        Q_EMIT saveImagesChanged();
    }
}

QVariantMap HistoryModel::get(int aRow)
{
    QString id;
    QVariantMap map;
    QModelIndex modelIndex = index(aRow, 0);
    for (int i = 0; i < Private::NUM_FIELDS; i++) {
        QVariant value = data(modelIndex, Qt::UserRole + i);
        if (value.isValid()) {
            map.insert(Private::DB_FIELD[i], value);
            if (i == Private::FIELD_ID) {
                id = value.toString();
            }
        }
    }
    // Addition field telling QML whether image file exists
    static const QString HAS_IMAGE("hasImage");
    QString path(Database::imageDir().path() + QDir::separator() + id +
        CaptureImageProvider::IMAGE_EXT);
    map.insert(HAS_IMAGE, QVariant::fromValue(QFile::exists(path)));

    HDEBUG(aRow << map);
    return map;
}

QString HistoryModel::getValue(int aRow)
{
    return iPrivate->valueAt(aRow, Private::FIELD_VALUE).toString();
}

QString HistoryModel::insert(QString aText, QString aFormat)
{
    QString id;
    QString timestamp(QDateTime::currentDateTime().toString(Qt::ISODate));
    HDEBUG(aText << aFormat << timestamp);
    QSqlRecord record(iPrivate->database().record(Private::DB_TABLE));
    record.setValue(Private::DB_FIELD_VALUE, aText);
    record.setValue(Private::DB_FIELD_TIMESTAMP, timestamp);
    record.setValue(Private::DB_FIELD_FORMAT, aFormat);
    if (iPrivate->removeExtraRows(1)) {
        invalidateFilter();
        commitChanges();
    }
    const int row = 0;
    if (iPrivate->insertRecord(row, record)) {
        invalidateFilter();
        // Just commit the changes, no need for cleanup:
        iPrivate->commitChanges();
        id = iPrivate->valueAt(row, Private::FIELD_ID).toString();
        HDEBUG(id << iPrivate->record(row));
        if (iPrivate->iSaveImages) {
            // Save the image on a separate thread. While we are saving
            // it, the image will remain cached by CaptureImageProvider.
            // It will be removed from the cache by Private::onSaveDone()
            CaptureImageProvider* ip = CaptureImageProvider::instance();
            if (ip && ip->cacheMarkedImage(id)) {
                (new SaveTask(iPrivate->iThreadPool, ip->iMarkedImage, id))->
                    submit(iPrivate, SLOT(onSaveDone()));
            }
        }
    }
    return id;
}

void HistoryModel::remove(int aRow)
{
    HDEBUG(aRow);
    removeRows(aRow, 1);
    invalidateFilter();
}

void HistoryModel::removeAll()
{
    HDEBUG("clearing history");
    const int n = rowCount();
    if (n > 0) {
        removeRows(0, n);
        invalidateFilter();
    }
}

void HistoryModel::commitChanges()
{
    iPrivate->commitChanges();
    if (iPrivate->iSaveImages) {
        iPrivate->cleanupFiles();
    }
}

QString HistoryModel::formatTimestamp(QString aTimestamp)
{
    static const QString format("dd.MM.yyyy  hh:mm:ss");
    return QDateTime::fromString(aTimestamp, Qt::ISODate).toString(format);
}

#include "HistoryModel.moc"
