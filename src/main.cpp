#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QFontDatabase>
#include <QSurfaceFormat>
#include <QTimer>
#include <QImage>

#include "vehicle.h"
#include "framestats.h"
#include "typography.h"
#include "waveforms.h"

int main(int argc, char *argv[])
{
    // Before anything else, so boot-to-first-frame covers the whole
    // process and not just the part after Qt is up.
    FrameStats::markProcessStart();

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("HMI Screens"));
    
    // A cluster is judged on the frame it misses, so ask for vsync and
    // a real swap interval rather than letting the driver decide.
    QSurfaceFormat fmt = QSurfaceFormat::defaultFormat();
    fmt.setSwapInterval(1);
    fmt.setSamples(4);
    QSurfaceFormat::setDefaultFormat(fmt);

    // --screen is 1-based, to match the keyboard shortcuts. Two numbering
    // schemes for the same screens is a bug waiting to happen.
    const QStringList args = app.arguments();

    auto option = [&args](const QString &name) -> QString {
        const int i = args.indexOf(name);
        return (i >= 0 && i + 1 < args.size()) ? args.at(i + 1) : QString();
    };

    int startScreen = 0;
    const QString screenArg = option(QStringLiteral("--screen"));
    if (!screenArg.isEmpty())
        startScreen = qMax(0, screenArg.toInt() - 1);

    const QString shotPath = option(QStringLiteral("--shot"));

    // --record does one sequence per run. Separate launches all restart
    // the drive cycle at the same point.
    const QString recordPrefix = option(QStringLiteral("--record"));
    const int recordFrames = option(QStringLiteral("--frames")).toInt() > 0
                           ? option(QStringLiteral("--frames")).toInt() : 24;
    const int recordEvery = option(QStringLiteral("--every")).toInt() > 0
                          ? option(QStringLiteral("--every")).toInt() : 80;

    // --solo drops the chrome so one screen fills the window.
    const bool solo = args.contains(QStringLiteral("--solo"));

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("startScreen"), startScreen);
    engine.rootContext()->setContextProperty(QStringLiteral("soloMode"), solo);

    // Owned by the application, not the engine: these run timers for the
    // whole process lifetime.
    Vehicle vehicle;
    FrameStats frames;
    Typography typography;
    Waveforms waves;
    qmlRegisterSingletonInstance("Screens.Backend", 1, 0, "Vehicle", &vehicle);
    qmlRegisterSingletonInstance("Screens.Backend", 1, 0, "Frames", &frames);
    qmlRegisterSingletonInstance("Screens.Backend", 1, 0, "Typography", &typography);
    qmlRegisterSingletonInstance("Screens.Backend", 1, 0, "Waves", &waves);
    qInfo("hmi: fonts ui=\"%s\" mono=\"%s\"",
          qPrintable(typography.ui()), qPrintable(typography.mono()));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Screens", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (window)
        frames.attach(window);

    if (window && !recordPrefix.isEmpty()) {
        auto *timer = new QTimer(&app);
        auto *frame = new int(0);
        // Let the scene settle before the first grab, or the opening
        // frames catch the app mid-construction.
        QTimer::singleShot(1800, &app, [=, &app]() {
            timer->start(recordEvery);
            QObject::connect(timer, &QTimer::timeout, &app, [=, &app]() {
                const QImage img = window->grabWindow();
                const QString name = QStringLiteral("%1_%2.png")
                        .arg(recordPrefix)
                        .arg(*frame, 3, 10, QChar('0'));
                if (!img.isNull())
                    img.save(name);
                if (++(*frame) >= recordFrames) {
                    timer->stop();
                    qInfo("hmi: recorded %d frames to %s_NNN.png",
                          recordFrames, qPrintable(recordPrefix));
                    app.quit();
                }
            });
        });
    }
    else if (window && !shotPath.isEmpty()) {
        // Far enough into the drive cycle for the telltales to be lit.
        QTimer::singleShot(2500, &app, [window, shotPath, &app]() {
            const QImage shot = window->grabWindow();
            if (!shot.isNull() && shot.save(shotPath))
                qInfo("hmi: wrote %s (%dx%d)", qPrintable(shotPath),
                      shot.width(), shot.height());
            else
                qWarning("hmi: could not write %s", qPrintable(shotPath));
            app.quit();
        });
    }

    // Boot-to-first-frame regresses quietly, so it goes in the log.
    QObject::connect(&frames, &FrameStats::bootChanged, &app, [&frames]() {
        qInfo("hmi: boot to first frame %.0f ms", frames.bootMs());
    });

    return app.exec();
}
