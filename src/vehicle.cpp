#include "vehicle.h"

#include <QGuiApplication>
#include <QtMath>
#include <array>

namespace {

// Drive cycle: 30 s loop, smoothstepped between keyframes (seconds, km/h).
struct Key { qreal t; qreal v; };
constexpr std::array<Key, 7> kCycle {{
    { 0,  0 }, { 7, 74 }, { 12, 74 }, { 16, 112 },
    { 22, 112 }, { 27, 38 }, { 30, 0 }
}};

// Gear windows (km/h). Real ratios would come from the powertrain
// model; these are shaped to give the tach a plausible saw-tooth.
constexpr std::array<std::pair<qreal, qreal>, 5> kGears {{
    { 0, 24 }, { 24, 46 }, { 46, 74 }, { 74, 104 }, { 104, 150 }
}};

inline qreal smoothstep(qreal x) { return x * x * (3.0 - 2.0 * x); }

} // namespace

Vehicle::Vehicle(QObject *parent)
    : QObject(parent)
{
    m_clock.start();
    m_lastMs = m_clock.elapsed();

    connect(&m_timer, &QTimer::timeout, this, &Vehicle::tick);
    m_timer.setTimerType(Qt::PreciseTimer);
    m_timer.start(16);                    // 62.5 Hz, ahead of a 60 Hz panel

    tick();                               // publish a valid first frame
}

qreal Vehicle::speedAt(qreal t)
{
    t = std::fmod(t, 30.0);
    if (t < 0)
        t += 30.0;
    for (size_t i = 0; i + 1 < kCycle.size(); ++i) {
        const Key &a = kCycle[i];
        const Key &b = kCycle[i + 1];
        if (t >= a.t && t <= b.t) {
            const qreal u = (t - a.t) / (b.t - a.t);
            return a.v + (b.v - a.v) * smoothstep(u);
        }
    }
    return 0.0;
}

int Vehicle::gearFor(qreal v)
{
    for (size_t i = 0; i < kGears.size(); ++i) {
        if (v < kGears[i].second)
            return int(i);
    }
    return int(kGears.size()) - 1;
}

qreal Vehicle::rpmFor(qreal v, int gear)
{
    if (v < 2.0)
        return 780.0;                     // idle

    // An upshift lands near the middle of the band, not at idle, so the
    // bottom of every gear is 1250 rpm rather than a stalled engine.
    const auto [lo, hi] = kGears[size_t(gear)];
    const qreal r = 1250.0 + ((v - lo) / (hi - lo)) * 3950.0;
    return qBound(720.0, r, 7600.0);
}

void Vehicle::setRunning(bool on)
{
    if (m_running == on)
        return;
    m_running = on;
    emit runningChanged();
}

void Vehicle::tick()
{
    const qint64 nowMs = m_clock.elapsed();
    const qreal dt = qMin(qreal(nowMs - m_lastMs) / 1000.0, 0.1);
    m_lastMs = nowMs;

    if (m_running)
        m_cycleT += dt;

    const qreal t = m_cycleT;
    const qreal cyc = std::fmod(t, 30.0);

    m_speed   = speedAt(t);
    m_gear    = gearFor(m_speed);
    m_rpm     = rpmFor(m_speed, m_gear);
    m_fuel    = 34.0 - std::fmod(t / 30.0, 1.0) * 1.2;
    m_coolant = 82.0 + (m_speed / 112.0) * 10.0;

    m_odometer += m_speed * dt / 3600.0;
    m_trip     += m_speed * dt / 3600.0;

    // Indicator lamps flash at ~1.5 Hz, which is inside the 60-120
    // cycles/min that ECE R48 allows for direction indicators.
    const bool blink = int(t * 1.5) % 2 == 0;
    m_ttRight = cyc > 2.0  && cyc < 6.4  && blink;
    m_ttLeft  = cyc > 17.0 && cyc < 21.4 && blink;
    m_ttBeam  = cyc > 12.0 && cyc < 22.0;
    m_ttAbs   = cyc > 24.0 && cyc < 25.6;
    m_ttBrake = cyc > 26.6 || cyc < 1.2;

    emit stateChanged();                  // one coherent snapshot per tick
}

QColor Vehicle::statusColor(const QString &status) const
{
    if (status == QLatin1String("alarm"))   return QColor("#FF5B4D");
    if (status == QLatin1String("watch"))   return QColor("#F2A20C");
    if (status == QLatin1String("running")) return QColor("#3FD07E");
    return QColor("#6E7986");
}

