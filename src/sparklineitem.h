#pragma once

#include <QQuickItem>
#include <QVariantList>
#include <QColor>
#include <QtQml/qqmlregistration.h>

/*  A rolling trace rendered straight into the scene graph.

    The obvious QML answer is Canvas, but Canvas keeps an FBO per item
    and repaints it on the GUI thread; eight of them in a list is eight
    render targets and eight paint calls per tick. This builds one
    triangle strip per trace on the render thread instead.

    Line width is done as geometry rather than by asking for a thick
    GL line: D3D11 ignores line width entirely, so a wide line strip
    renders one pixel wide on Windows and looks fine on nothing else. */
class SparklineItem : public QQuickItem
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Sparkline)

    Q_PROPERTY(QVariantList samples READ samples WRITE setSamples NOTIFY samplesChanged)
    Q_PROPERTY(QColor stroke READ stroke WRITE setStroke NOTIFY strokeChanged)
    Q_PROPERTY(qreal lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)

public:
    explicit SparklineItem(QQuickItem *parent = nullptr);

    QVariantList samples() const { return m_samples; }
    void setSamples(const QVariantList &s);

    QColor stroke() const { return m_stroke; }
    void setStroke(const QColor &c);

    qreal lineWidth() const { return m_lineWidth; }
    void setLineWidth(qreal w);

signals:
    void samplesChanged();
    void strokeChanged();
    void lineWidthChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    QVariantList m_samples;
    QColor m_stroke = QColor("#4FD8E8");
    qreal m_lineWidth = 1.6;
};
