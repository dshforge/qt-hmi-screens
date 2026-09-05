#pragma once

#include <QObject>
#include <QTimer>
#include <QElapsedTimer>
#include <QVariantList>
#include <QtMath>
#include <QRandomGenerator>

/*  Synthetic sources for the medical and instrument screens.

    The ECG is built from the actual shape of a PQRST complex rather than
    a sine wave, because a clinician recognises the wrong one instantly
    and the whole point of showing this screen is that the domain was
    taken seriously.

    The spectrum is a noise floor with a few real peaks on it, which is
    what an analyser display has to lay out well: a wide dynamic range
    where the interesting part is often near the floor.                 */
class Waveforms : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList ecg   READ ecg   NOTIFY updated)
    Q_PROPERTY(QVariantList pleth READ pleth NOTIFY updated)
    Q_PROPERTY(QVariantList resp  READ resp  NOTIFY updated)
    Q_PROPERTY(QVariantList spectrum READ spectrum NOTIFY updated)

    Q_PROPERTY(int heartRate  READ heartRate  NOTIFY updated)
    Q_PROPERTY(int spo2       READ spo2       NOTIFY updated)
    Q_PROPERTY(int respRate   READ respRate   NOTIFY updated)
    Q_PROPERTY(int sysBp      READ sysBp      NOTIFY updated)
    Q_PROPERTY(int diaBp      READ diaBp      NOTIFY updated)
    Q_PROPERTY(qreal tempC    READ tempC      NOTIFY updated)
    Q_PROPERTY(qreal etco2    READ etco2      NOTIFY updated)

    Q_PROPERTY(qreal peakHz   READ peakHz   NOTIFY updated)
    Q_PROPERTY(qreal peakDbm  READ peakDbm  NOTIFY updated)

public:
    explicit Waveforms(QObject *parent = nullptr) : QObject(parent)
    {
        m_clock.start();
        m_ecg.reserve(kWave); m_pleth.reserve(kWave); m_resp.reserve(kWave);
        for (int i = 0; i < kWave; ++i) { m_ecg.append(0.0); m_pleth.append(0.0); m_resp.append(0.0); }
        for (int i = 0; i < kBins; ++i) m_spectrum.append(-110.0);

        connect(&m_timer, &QTimer::timeout, this, &Waveforms::tick);
        m_timer.setTimerType(Qt::PreciseTimer);
        m_timer.start(40);                       // 25 Hz sweep
        tick();
    }

    QVariantList ecg() const { return m_ecg; }
    QVariantList pleth() const { return m_pleth; }
    QVariantList resp() const { return m_resp; }
    QVariantList spectrum() const { return m_spectrum; }

    int heartRate() const { return m_hr; }
    int spo2() const { return m_spo2; }
    int respRate() const { return m_rr; }
    int sysBp() const { return m_sys; }
    int diaBp() const { return m_dia; }
    qreal tempC() const { return m_temp; }
    qreal etco2() const { return m_etco2; }
    qreal peakHz() const { return m_peakHz; }
    qreal peakDbm() const { return m_peakDbm; }

signals:
    void updated();

private slots:
    void tick()
    {
        const qreal t = m_clock.elapsed() / 1000.0;

        // --- ECG: a PQRST complex placed on a beat phase --------------
        const qreal beat = 60.0 / m_hr;
        for (int step = 0; step < kStep; ++step) {
            m_phase += 0.04 / kStep;
            const qreal p = std::fmod(m_phase, beat) / beat;
            m_ecg.removeFirst();
            m_ecg.append(pqrst(p));
            m_pleth.removeFirst();
            m_pleth.append(pulse(p));
            m_resp.removeFirst();
            m_resp.append(0.5 + 0.42 * qSin(2 * M_PI * (t / (60.0 / m_rr))));
        }

        // --- spectrum: noise floor with a few honest peaks ------------
        for (int i = 0; i < kBins; ++i) {
            const qreal f = qreal(i) / kBins;
            qreal v = -104.0 + QRandomGenerator::global()->bounded(60) / 10.0;
            v += peak(f, 0.18, 0.006, 62.0 + 3.0 * qSin(t * 0.7));
            v += peak(f, 0.41, 0.004, 44.0 + 2.0 * qSin(t * 1.3 + 1.0));
            v += peak(f, 0.63, 0.010, 30.0);
            v += peak(f, 0.82, 0.003, 21.0 + 4.0 * qSin(t * 0.4));
            m_spectrum[i] = v;
        }
        // Read the marker off the array that is actually drawn. Deriving
        // it from the same formula independently lets the readout and the
        // trace disagree by the noise term, which on a real analyser is
        // the difference between a measurement and a decoration.
        const int mk = int(0.18 * kBins);
        m_peakHz  = 0.18 * 2400.0;
        m_peakDbm = m_spectrum.at(qBound(0, mk, kBins - 1)).toReal();

        // vitals drift slowly, the way real ones do
        m_hr   = 72 + int(4 * qSin(t * 0.11));
        m_spo2 = 97 + int(1.4 * qSin(t * 0.07));
        m_rr   = 14 + int(2 * qSin(t * 0.05));
        m_temp = 36.8 + 0.2 * qSin(t * 0.03);
        m_etco2 = 38.0 + 1.6 * qSin(t * 0.09);

        emit updated();
    }

private:
    static qreal peak(qreal f, qreal at, qreal width, qreal amp)
    {
        const qreal d = (f - at) / width;
        return amp * qExp(-d * d);
    }

    // one cardiac cycle, phase 0..1
    static qreal pqrst(qreal p)
    {
        qreal v = 0.0;
        v += 0.09 * qExp(-qPow((p - 0.16) / 0.026, 2));   // P
        v -= 0.07 * qExp(-qPow((p - 0.255) / 0.008, 2));  // Q
        v += 1.00 * qExp(-qPow((p - 0.278) / 0.0075, 2)); // R
        v -= 0.18 * qExp(-qPow((p - 0.305) / 0.011, 2));  // S
        v += 0.21 * qExp(-qPow((p - 0.44) / 0.045, 2));   // T
        return v;
    }
    static qreal pulse(qreal p)
    {
        qreal v = qExp(-qPow((p - 0.34) / 0.10, 2));
        v += 0.34 * qExp(-qPow((p - 0.54) / 0.07, 2));    // dicrotic notch
        return v;
    }

    static constexpr int kWave = 260;
    static constexpr int kBins = 220;
    static constexpr int kStep = 5;

    QVariantList m_ecg, m_pleth, m_resp, m_spectrum;
    QTimer m_timer;
    QElapsedTimer m_clock;
    qreal m_phase = 0.0;
    int m_hr = 72, m_spo2 = 98, m_rr = 14, m_sys = 118, m_dia = 74;
    qreal m_temp = 36.8, m_etco2 = 38.0, m_peakHz = 432.0, m_peakDbm = -42.0;
};
