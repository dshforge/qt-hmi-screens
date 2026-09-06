#pragma once

#include <QAbstractListModel>
#include <QTimer>
#include <QElapsedTimer>
#include <QVariantList>
#include <QtMath>

/*  Decoded CAN signals with a short rolling history each. The source
    sits behind tick(), which a QCanBusDevice readyRead handler replaces
    without the roles or the view changing.                          */
class CanModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int frameRate READ frameRate NOTIFY frameRateChanged)

public:
    enum Role {
        FrameIdRole = Qt::UserRole + 1,
        SignalNameRole, RawRole, ScaledRole, DecimalsRole,
        UnitRole, AgeMsRole, AlarmRole, HistoryRole
    };

    struct Signal_ {
        QString frameId, name, unit;
        qreal base, amplitude;
        int decimals;
        qreal phase;
        qreal value = 0;
        int ageMs = 0;
        QVariantList history;
    };

    explicit CanModel(QObject *parent = nullptr)
        : QAbstractListModel(parent)
    {
        m_signals = {
            { "0x0C1", "EngineSpeed",   "r/min", 2480, 520,  0, 0.0 },
            { "0x0D3", "VehicleSpeed",  "km/h",    71,   9,  1, 0.7 },
            { "0x1A4", "CoolantTemp",   "degC",    88,   6,  0, 1.4 },
            { "0x1A4", "OilPressure",   "kPa",    412,  22,  0, 2.1 },
            { "0x215", "ThrottlePos",   "%",       34,  14,  1, 2.8 },
            { "0x2C0", "BrakePressure", "bar",    1.8, 1.1,  2, 3.5 },
            { "0x3E8", "SteerAngle",    "deg",      0,  26,  1, 4.2 },
            { "0x420", "BattVoltage",   "V",     27.6, 0.4,  2, 4.9 }
        };
        for (Signal_ &s : m_signals) {
            s.value = s.base;
            for (int i = 0; i < kHistory; ++i)
                s.history.append(s.base);
        }

        m_clock.start();
        connect(&m_timer, &QTimer::timeout, this, &CanModel::tick);
        m_timer.start(100);          // 10 Hz refresh of the view
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override
    {
        return parent.isValid() ? 0 : int(m_signals.size());
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid() || index.row() < 0 || index.row() >= m_signals.size())
            return {};
        const Signal_ &s = m_signals.at(index.row());
        switch (role) {
        case FrameIdRole:    return s.frameId;
        case SignalNameRole: return s.name;
        case RawRole:        return QStringLiteral("0x%1")
                                    .arg(quint16(qAbs(s.value) * 4), 4, 16, QChar('0'))
                                    .toUpper().replace("0X", "0x");
        case ScaledRole:     return s.value;
        case DecimalsRole:   return s.decimals;
        case UnitRole:       return s.unit;
        case AgeMsRole:      return s.ageMs;
        case AlarmRole:      return s.name == QLatin1String("CoolantTemp") && s.value > 92;
        case HistoryRole:    return s.history;
        default:             return {};
        }
    }

    QHash<int, QByteArray> roleNames() const override
    {
        return {
            { FrameIdRole, "frameId" }, { SignalNameRole, "signalName" },
            { RawRole, "raw" }, { ScaledRole, "scaled" },
            { DecimalsRole, "decimals" }, { UnitRole, "unit" },
            { AgeMsRole, "ageMs" }, { AlarmRole, "alarm" },
            { HistoryRole, "history" }
        };
    }

    int frameRate() const { return m_frameRate; }

signals:
    void frameRateChanged();

private slots:
    void tick()
    {
        const qreal t = m_clock.elapsed() / 1000.0;

        for (Signal_ &s : m_signals) {
            s.value = s.base
                    + qSin(t * 0.9 + s.phase) * s.amplitude
                    + qSin(t * 3.1 + s.phase * 2) * s.amplitude * 0.16;
            s.ageMs = 8 + int(qAbs(qSin(t + s.phase)) * 22);
            s.history.append(s.value);
            while (s.history.size() > kHistory)
                s.history.removeFirst();
        }

        emit dataChanged(index(0, 0), index(rowCount() - 1, 0),
                         { RawRole, ScaledRole, AgeMsRole, AlarmRole, HistoryRole });

        m_frameRate = 1780 + int(qAbs(qSin(t * 0.4)) * 120);
        emit frameRateChanged();
    }

private:
    static constexpr int kHistory = 26;

    QList<Signal_> m_signals;
    QTimer m_timer;
    QElapsedTimer m_clock;
    int m_frameRate = 1780;
};
