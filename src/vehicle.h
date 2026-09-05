#pragma once

#include <QObject>
#include <QTimer>
#include <QElapsedTimer>
#include <QColor>
#include <QString>

#include "fleetmodel.h"
#include "canmodel.h"

/*  Vehicle state for the cluster.

    All the fast-moving values share one `stateChanged` signal and are
    published together at the end of a tick. That is deliberate: a
    cluster should never render a frame built from half of one sample
    and half of the next, and per-property notifiers make that easy to
    do by accident.

    On a target, tick() is fed by the bus instead of the drive cycle;
    the properties and everything above them stay as they are.       */
class Vehicle : public QObject
{
    Q_OBJECT

    Q_PROPERTY(qreal speedKph   READ speedKph   NOTIFY stateChanged)
    Q_PROPERTY(qreal rpm        READ rpm        NOTIFY stateChanged)
    Q_PROPERTY(qreal fuelPct    READ fuelPct    NOTIFY stateChanged)
    Q_PROPERTY(qreal coolantC   READ coolantC   NOTIFY stateChanged)
    Q_PROPERTY(qreal odometerKm READ odometerKm NOTIFY stateChanged)
    Q_PROPERTY(qreal tripKm     READ tripKm     NOTIFY stateChanged)
    Q_PROPERTY(qreal rangeKm    READ rangeKm    NOTIFY stateChanged)
    Q_PROPERTY(QString gearLabel READ gearLabel NOTIFY stateChanged)
    Q_PROPERTY(QString driveMode READ driveMode NOTIFY stateChanged)

    Q_PROPERTY(bool ttLeft  READ ttLeft  NOTIFY stateChanged)
    Q_PROPERTY(bool ttRight READ ttRight NOTIFY stateChanged)
    Q_PROPERTY(bool ttBeam  READ ttBeam  NOTIFY stateChanged)
    Q_PROPERTY(bool ttAbs   READ ttAbs   NOTIFY stateChanged)
    Q_PROPERTY(bool ttBrake READ ttBrake NOTIFY stateChanged)
    Q_PROPERTY(bool ttTemp  READ ttTemp  NOTIFY stateChanged)
    Q_PROPERTY(bool ttFuel  READ ttFuel  NOTIFY stateChanged)
    Q_PROPERTY(bool ttBatt  READ ttBatt  NOTIFY stateChanged)

    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)

    Q_PROPERTY(FleetModel *fleet READ fleet CONSTANT)
    Q_PROPERTY(CanModel   *can   READ can   CONSTANT)
    Q_PROPERTY(QString qtVersion   READ qtVersion   CONSTANT)

public:
    explicit Vehicle(QObject *parent = nullptr);

    qreal speedKph()   const { return m_speed; }
    qreal rpm()        const { return m_rpm; }
    qreal fuelPct()    const { return m_fuel; }
    qreal coolantC()   const { return m_coolant; }
    qreal odometerKm() const { return m_odometer; }
    qreal tripKm()     const { return m_trip; }
    qreal rangeKm()    const { return m_fuel * 12.4; }
    QString gearLabel() const { return QStringLiteral("D%1").arg(m_gear + 1); }
    QString driveMode() const { return QStringLiteral("D"); }

    bool ttLeft()  const { return m_ttLeft; }
    bool ttRight() const { return m_ttRight; }
    bool ttBeam()  const { return m_ttBeam; }
    bool ttAbs()   const { return m_ttAbs; }
    bool ttBrake() const { return m_ttBrake; }
    bool ttTemp()  const { return m_coolant > 91.4; }
    bool ttFuel()  const { return m_fuel < 35.0; }
    bool ttBatt()  const { return false; }

    bool running() const { return m_running; }
    void setRunning(bool on);

    FleetModel *fleet() { return &m_fleet; }
    CanModel   *can()   { return &m_can; }

    QString qtVersion()   const { return QString::fromLatin1(qVersion()); }

    Q_INVOKABLE QColor statusColor(const QString &status) const;

signals:
    void stateChanged();
    void runningChanged();

private slots:
    void tick();

private:
    static qreal speedAt(qreal t);
    static int   gearFor(qreal v);
    static qreal rpmFor(qreal v, int gear);

    FleetModel m_fleet;
    CanModel   m_can;

    QTimer m_timer;
    QElapsedTimer m_clock;
    qint64 m_lastMs = 0;
    qreal m_cycleT = 13.0;      // open mid-cycle, not at a standstill

    qreal m_speed = 0, m_rpm = 780, m_fuel = 34, m_coolant = 82;
    qreal m_odometer = 41208.6, m_trip = 128.4;
    int   m_gear = 0;
    bool  m_ttLeft = false, m_ttRight = false, m_ttBeam = false;
    bool  m_ttAbs = false, m_ttBrake = false;
    bool  m_running = true;
};
