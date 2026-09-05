#pragma once

#include <QQuickItem>
#include <QVariantList>
#include <QColor>
#include <QtQml/qqmlregistration.h>

/*  A fixed-scale waveform trace on the scene graph.

    Sparkline auto-scales to whatever it is given, which is right for a
    trend and wrong for anything clinical or metrological: an ECG that
    rescales itself hides the amplitude change that mattered. This one
    takes an explicit minY and maxY and never moves them, so two traces
    on screen can honestly be compared against each other.

    Optional area fill under the curve, drawn as a second triangle strip
    from the baseline, for spectra and envelopes.                       */
class WaveTrace : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList samples READ samples WRITE setSamples NOTIFY samplesChanged)
    Q_PROPERTY(QColor stroke READ stroke WRITE setStroke NOTIFY strokeChanged)
    Q_PROPERTY(qreal minY READ minY WRITE setMinY NOTIFY rangeChanged)
    Q_PROPERTY(qreal maxY READ maxY WRITE setMaxY NOTIFY rangeChanged)
    Q_PROPERTY(qreal lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)
    Q_PROPERTY(bool filled READ filled WRITE setFilled NOTIFY filledChanged)
    Q_PROPERTY(qreal fillOpacity READ fillOpacity WRITE setFillOpacity NOTIFY filledChanged)

public:
    explicit WaveTrace(QQuickItem *parent = nullptr);

    QVariantList samples() const { return m_samples; }
    void setSamples(const QVariantList &s);

    QColor stroke() const { return m_stroke; }
    void setStroke(const QColor &c);

    qreal minY() const { return m_minY; }
    void setMinY(qreal v);
    qreal maxY() const { return m_maxY; }
    void setMaxY(qreal v);

    qreal lineWidth() const { return m_lineWidth; }
    void setLineWidth(qreal w);

    bool filled() const { return m_filled; }
    void setFilled(bool f);
    qreal fillOpacity() const { return m_fillOpacity; }
    void setFillOpacity(qreal o);

signals:
    void samplesChanged();
    void strokeChanged();
    void rangeChanged();
    void lineWidthChanged();
    void filledChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    QVariantList m_samples;
    QColor m_stroke = QColor("#4FD8E8");
    qreal m_minY = 0.0;
    qreal m_maxY = 1.0;
    qreal m_lineWidth = 1.8;
    bool  m_filled = false;
    qreal m_fillOpacity = 0.25;
};
