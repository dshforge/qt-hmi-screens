#include "framestats.h"

#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QMutexLocker>
#include <algorithm>

namespace {

QElapsedTimer g_processClock;

// Upper edge of each bucket, in milliseconds. The interesting boundary
// is 16.7: everything at or under it made the frame, everything above
// it did not.
constexpr qreal kEdges[] = { 8.0, 12.0, 15.0, 16.7, 20.0, 33.4, 1e9 };
const char *kLabels[] = { "<8", "8-12", "12-15", "15-16.7", "16.7-20", "20-33", ">33" };

} // namespace

void FrameStats::markProcessStart()
{
    g_processClock.start();
}

FrameStats::FrameStats(QObject *parent)
    : QObject(parent)
{
    m_ring.resize(kCapacity, 0.0);
    m_frameClock.start();

    connect(&m_notify, &QTimer::timeout, this, &FrameStats::updated);
    m_notify.start(100);
}

void FrameStats::attach(QQuickWindow *window)
{
    if (!window)
        return;

    // Direct connection: this runs on the render thread, which is where
    // the swap actually happened.
    connect(window, &QQuickWindow::frameSwapped,
            this, &FrameStats::onFrameSwapped, Qt::DirectConnection);

    // Report the backend actually in use rather than the one this
    // platform usually picks -- it can be overridden by environment,
    // and on a target it is the first thing to check when frames slip.
    if (auto *ri = window->rendererInterface()) {
        switch (ri->graphicsApi()) {
        case QSGRendererInterface::Direct3D11: m_graphicsApi = "Direct3D 11"; break;
        case QSGRendererInterface::Direct3D12: m_graphicsApi = "Direct3D 12"; break;
        case QSGRendererInterface::Vulkan:     m_graphicsApi = "Vulkan";      break;
        case QSGRendererInterface::Metal:      m_graphicsApi = "Metal";       break;
        case QSGRendererInterface::OpenGL:     m_graphicsApi = "OpenGL";      break;
        case QSGRendererInterface::Software:   m_graphicsApi = "Software";    break;
        default:                               m_graphicsApi = "unknown";     break;
        }
        emit graphicsApiChanged();
    }
}

void FrameStats::onFrameSwapped()
{
    const qint64 nowNs = m_frameClock.nsecsElapsed();

    if (!m_bootCaptured) {
        m_bootCaptured = true;
        m_bootMs = g_processClock.isValid()
                 ? qreal(g_processClock.nsecsElapsed()) / 1e6 : 0.0;
        QMetaObject::invokeMethod(this, &FrameStats::bootChanged, Qt::QueuedConnection);
        m_lastNs = nowNs;
        return;
    }

    const qreal ms = qreal(nowNs - m_lastNs) / 1e6;
    m_lastNs = nowNs;

    // A frame delayed past ~5x the budget is the compositor being
    // throttled (window hidden, machine asleep), not a dropped frame.
    if (ms <= 0.0 || ms > 100.0)
        return;

    QMutexLocker guard(&m_lock);

    m_last = ms;
    m_sum += ms;
    ++m_count;
    if (ms > m_max)
        m_max = ms;
    if (ms > budgetMs() * 1.5)
        ++m_missed;

    for (int i = 0; i < kBucketCount; ++i) {
        if (ms <= kEdges[i]) { ++m_hist[i]; break; }
    }

    m_ring[m_writeIndex] = ms;
    m_writeIndex = (m_writeIndex + 1) % kCapacity;
    if (m_writeIndex == 0)
        m_wrapped = true;
}

qreal FrameStats::lastMs() const { QMutexLocker g(&m_lock); return m_last; }
qreal FrameStats::maxMs()  const { QMutexLocker g(&m_lock); return m_max; }
int FrameStats::frameCount()   const { QMutexLocker g(&m_lock); return m_count; }
int FrameStats::missedFrames() const { QMutexLocker g(&m_lock); return m_missed; }

qreal FrameStats::meanMs() const
{
    QMutexLocker g(&m_lock);
    return m_count > 0 ? m_sum / m_count : 0.0;
}

qreal FrameStats::percentile(qreal q) const
{
    QMutexLocker g(&m_lock);
    const int n = m_wrapped ? kCapacity : m_writeIndex;
    if (n <= 0)
        return 0.0;

    std::vector<qreal> sorted(m_ring.begin(), m_ring.begin() + n);
    std::sort(sorted.begin(), sorted.end());

    int idx = int(q * (n - 1) + 0.5);
    idx = std::clamp(idx, 0, n - 1);
    return sorted[size_t(idx)];
}

QVariantList FrameStats::histogram() const
{
    QMutexLocker g(&m_lock);
    QVariantList out;
    for (int i = 0; i < kBucketCount; ++i)
        out.append(m_hist[i]);
    return out;
}

QVariantList FrameStats::buckets() const
{
    QVariantList out;
    for (int i = 0; i < kBucketCount; ++i)
        out.append(QString::fromLatin1(kLabels[i]));
    return out;
}

QVariantList FrameStats::recent() const
{
    QMutexLocker g(&m_lock);
    const int n = m_wrapped ? kCapacity : m_writeIndex;
    QVariantList out;
    const int take = std::min(n, 180);
    for (int i = n - take; i < n; ++i) {
        const int idx = m_wrapped ? (m_writeIndex + i) % kCapacity : i;
        out.append(m_ring[size_t(idx)]);
    }
    return out;
}
