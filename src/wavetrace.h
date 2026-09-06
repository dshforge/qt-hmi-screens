#pragma once

#include <QQuickItem>
#include <QVariantList>
#include <QColor>
#include <QtQml/qqmlregistration.h>

/*  A fixed-scale waveform trace on the scene graph.

    Sparkline auto-scales, which suits a trend and ruins anything
    clinical: an ECG that rescales itself hides the amplitude change
    that mattered. minY and maxY are explicit here and never move, so
    two traces can be compared against each other.

    Optional area fill, a second triangle strip from the baseline.    */
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
