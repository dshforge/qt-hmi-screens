#pragma once

#include <QObject>
#include <QFontDatabase>
#include <QStringList>

/*  Picks a font family that the machine actually has.

    Naming "Segoe UI" and stopping there is a Windows-only decision:
    on Linux and macOS the request fails silently, Qt substitutes
    something, and the type scale drifts with nothing in the log to
    say why. This resolves against QFontDatabase once at startup and
    reports what it chose, so a wrong-looking build on another
    platform is one line of output away from an explanation.        */
class Typography : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString ui   READ ui   CONSTANT)
    Q_PROPERTY(QString mono READ mono CONSTANT)

public:
    explicit Typography(QObject *parent = nullptr)
        : QObject(parent)
    {
        m_ui = firstAvailable({
            QStringLiteral("Segoe UI"),        // Windows
            QStringLiteral("SF Pro Text"),     // macOS
            QStringLiteral("Helvetica Neue"),
            QStringLiteral("Inter"),
            QStringLiteral("Noto Sans"),       // most Linux desktops
            QStringLiteral("DejaVu Sans"),
            QStringLiteral("Liberation Sans")
        }, QFontDatabase::systemFont(QFontDatabase::GeneralFont).family());

        m_mono = firstAvailable({
            QStringLiteral("Consolas"),        // Windows
            QStringLiteral("SF Mono"),         // macOS
            QStringLiteral("Menlo"),
            QStringLiteral("JetBrains Mono"),
            QStringLiteral("DejaVu Sans Mono"),
            QStringLiteral("Noto Sans Mono"),
            QStringLiteral("Liberation Mono")
        }, QFontDatabase::systemFont(QFontDatabase::FixedFont).family());
    }

    QString ui()   const { return m_ui; }
    QString mono() const { return m_mono; }

private:
    static QString firstAvailable(const QStringList &preferred, const QString &fallback)
    {
        const QStringList installed = QFontDatabase::families();
        for (const QString &name : preferred) {
            if (installed.contains(name, Qt::CaseInsensitive))
                return name;
        }
        return fallback;
    }

    QString m_ui;
    QString m_mono;
};
