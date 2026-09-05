#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QHash>
#include <QByteArray>

/*  Fleet units as a proper item model rather than a QVariantList, so
    the ListView gets per-role change notification and the view never
    rebuilds a delegate it did not need to.                          */
class FleetModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        UnitIdRole = Qt::UserRole + 1,
        MakeRole, StatusRole, SpeedRole, CoolantRole, BrakeTempRole,
        LinkRole, PosRole, FixRole, HoursRole, OdoRole, FuelRole,
        DtcRole, UptimeRole
    };

    struct Unit {
        QString unitId, make, status, pos, fix, hours, odo, fuel, dtc, uptime;
        int speed, coolant, brakeTemp, link;
    };

    explicit FleetModel(QObject *parent = nullptr)
        : QAbstractListModel(parent)
    {
        m_units = {
            { "TRK-1104", "Tipper 6x4", "running", "28.5412 N, 77.2801 E",
              "RTK fixed, 11 sv", "4 812", "186 402 km", "58 %", "none",
              "6 d 04 h", 62, 88, 212, -71 },
            { "TRK-1108", "Tipper 6x4", "watch", "28.5106 N, 77.3390 E",
              "3D, 8 sv", "6 190", "241 887 km", "22 %", "P0217 over-temp",
              "2 d 11 h", 71, 104, 341, -83 },
            { "TRK-1121", "Haul 8x4", "running", "28.5533 N, 77.2644 E",
              "RTK fixed, 13 sv", "1 204", "48 116 km", "91 %", "none",
              "14 d 02 h", 0, 74, 98, -64 },
            { "TRK-1132", "Haul 8x4", "alarm", "28.4938 N, 77.3012 E",
              "2D, 5 sv", "9 733", "390 551 km", "14 %", "C1095 brake temp",
              "0 d 07 h", 18, 112, 468, -96 },
            { "TRK-1140", "Tipper 6x4", "running", "28.5701 N, 77.2489 E",
              "RTK fixed, 12 sv", "3 018", "122 740 km", "67 %", "none",
              "9 d 19 h", 54, 86, 186, -68 },
            { "TRK-1155", "Van 4x2", "idle", "28.5533 N, 77.2644 E",
              "3D, 9 sv", "812", "29 305 km", "46 %", "none",
              "21 d 06 h", 0, 41, 24, -77 }
        };
    }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override
    {
        return parent.isValid() ? 0 : int(m_units.size());
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid() || index.row() < 0 || index.row() >= m_units.size())
            return {};
        const Unit &u = m_units.at(index.row());
        switch (role) {
        case UnitIdRole:    return u.unitId;
        case MakeRole:      return u.make;
        case StatusRole:    return u.status;
        case SpeedRole:     return u.speed;
        case CoolantRole:   return u.coolant;
        case BrakeTempRole: return u.brakeTemp;
        case LinkRole:      return u.link;
        case PosRole:       return u.pos;
        case FixRole:       return u.fix;
        case HoursRole:     return u.hours;
        case OdoRole:       return u.odo;
        case FuelRole:      return u.fuel;
        case DtcRole:       return u.dtc;
        case UptimeRole:    return u.uptime;
        default:            return {};
        }
    }

    QHash<int, QByteArray> roleNames() const override
    {
        return {
            { UnitIdRole, "unitId" }, { MakeRole, "make" }, { StatusRole, "status" },
            { SpeedRole, "speed" }, { CoolantRole, "coolant" },
            { BrakeTempRole, "brakeTemp" }, { LinkRole, "link" },
            { PosRole, "pos" }, { FixRole, "fix" }, { HoursRole, "hours" },
            { OdoRole, "odo" }, { FuelRole, "fuel" }, { DtcRole, "dtc" },
            { UptimeRole, "uptime" }
        };
    }

    // Convenience for the detail pane, which reads one field at a time.
    Q_INVOKABLE QString field(int row, const QString &roleName) const
    {
        const QHash<int, QByteArray> names = roleNames();
        for (auto it = names.cbegin(); it != names.cend(); ++it) {
            if (it.value() == roleName.toUtf8())
                return data(index(row, 0), it.key()).toString();
        }
        return {};
    }

    Q_INVOKABLE int rowCountQml() const { return rowCount(); }

private:
    QList<Unit> m_units;
};
