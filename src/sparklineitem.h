#pragma once

#include <QQuickItem>
#include <QVariantList>
#include <QColor>
#include <QtQml/qqmlregistration.h>

/*  A rolling trace built straight into the scene graph.

    Canvas keeps an FBO per item and repaints on the GUI thread, so
    eight in a list is eight render targets and eight paint calls a
    tick. This builds one triangle strip per trace on the render thread.

    Line width is geometry, not a thick GL line: D3D11 ignores line
    width, so a wide strip renders one pixel wide on Windows.        */
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
