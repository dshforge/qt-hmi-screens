#pragma once

#include <QObject>
#include <QElapsedTimer>
#include <QTimer>
#include <QMutex>
#include <QVariantList>
#include <vector>

class QQuickWindow;

/*  Frame timing for this application, measured on itself.

    Automakers generally want the cluster showing correct values within
    two seconds of ignition, and a 60 Hz panel gives you 16.7 ms a frame.
    Both are worst-case numbers, so an average is the wrong statistic:
    this keeps p95, p99 and the outright maximum, which are the ones a
    reviewer will ask about.

    frameSwapped is emitted on the render thread, so the timestamp is
    taken there under a mutex rather than being queued to the GUI thread
    first, which would measure event-loop latency instead of the frame.
    QML is notified at 10 Hz, because a property update per frame would
    itself become part of what is being measured.                     */
class FrameStats : public QObject
{
    Q_OBJECT

    Q_PROPERTY(qreal lastMs   READ lastMs   NOTIFY updated)
    Q_PROPERTY(qreal meanMs   READ meanMs   NOTIFY updated)
    Q_PROPERTY(qreal p50Ms    READ p50Ms    NOTIFY updated)
    Q_PROPERTY(qreal p95Ms    READ p95Ms    NOTIFY updated)
    Q_PROPERTY(qreal p99Ms    READ p99Ms    NOTIFY updated)
    Q_PROPERTY(qreal maxMs    READ maxMs    NOTIFY updated)
    Q_PROPERTY(qreal budgetMs READ budgetMs CONSTANT)
    Q_PROPERTY(int frameCount   READ frameCount   NOTIFY updated)
    Q_PROPERTY(int missedFrames READ missedFrames NOTIFY updated)
    Q_PROPERTY(QVariantList histogram READ histogram NOTIFY updated)
    Q_PROPERTY(QVariantList buckets   READ buckets   CONSTANT)
    Q_PROPERTY(QVariantList recent    READ recent    NOTIFY updated)
    Q_PROPERTY(qreal bootMs     READ bootMs     NOTIFY bootChanged)
    Q_PROPERTY(qreal bootBudget READ bootBudget CONSTANT)
    Q_PROPERTY(QString graphicsApi READ graphicsApi NOTIFY graphicsApiChanged)

public:
    explicit FrameStats(QObject *parent = nullptr);

    // Call before QGuiApplication is constructed.
    static void markProcessStart();

    void attach(QQuickWindow *window);

    qreal lastMs() const;
    qreal meanMs() const;
    qreal p50Ms()  const { return percentile(0.50); }
    qreal p95Ms()  const { return percentile(0.95); }
    qreal p99Ms()  const { return percentile(0.99); }
    qreal maxMs()  const;
    qreal budgetMs() const { return 1000.0 / 60.0; }

    int frameCount()   const;
    int missedFrames() const;

    QVariantList histogram() const;
    QVariantList buckets() const;
    QVariantList recent() const;

    qreal bootMs() const { return m_bootMs; }
    QString graphicsApi() const { return m_graphicsApi; }
    qreal bootBudget() const { return 2000.0; }

signals:
    void updated();
    void bootChanged();
    void graphicsApiChanged();

private:
    void onFrameSwapped();
    qreal percentile(qreal q) const;

    static constexpr int kCapacity = 600;      // 10 s at 60 Hz
    static constexpr int kBucketCount = 7;

    mutable QMutex m_lock;
    std::vector<qreal> m_ring;
    int m_writeIndex = 0;
    bool m_wrapped = false;
    qint64 m_lastNs = 0;
    qreal m_last = 0;
    qreal m_max = 0;
    qreal m_sum = 0;
    int m_count = 0;
    int m_missed = 0;
    int m_hist[kBucketCount] = { 0 };

    QElapsedTimer m_frameClock;
    QTimer m_notify;
    qreal m_bootMs = 0;
    bool m_bootCaptured = false;
    QString m_graphicsApi = QStringLiteral("unknown");
};
