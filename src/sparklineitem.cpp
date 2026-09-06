#include "sparklineitem.h"

#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QVector2D>
#include <vector>

SparklineItem::SparklineItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void SparklineItem::setSamples(const QVariantList &s)
{
    m_samples = s;
    emit samplesChanged();
    update();
}

void SparklineItem::setStroke(const QColor &c)
{
    if (m_stroke == c)
        return;
    m_stroke = c;
    emit strokeChanged();
    update();
}

void SparklineItem::setLineWidth(qreal w)
{
    if (qFuzzyCompare(m_lineWidth, w))
        return;
    m_lineWidth = w;
    emit lineWidthChanged();
    update();
}

QSGNode *SparklineItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    const int n = m_samples.size();
    if (n < 2 || width() <= 0 || height() <= 0) {
        delete oldNode;
        return nullptr;
    }

    // map samples into the item's box
    qreal lo = m_samples.at(0).toReal();
    qreal hi = lo;
    for (int i = 1; i < n; ++i) {
        const qreal v = m_samples.at(i).toReal();
        lo = qMin(lo, v);
        hi = qMax(hi, v);
    }
    const qreal span = (hi - lo) > 1e-9 ? (hi - lo) : 1.0;

    const qreal padX = 2.0;
    const qreal padY = 3.0;
    const qreal usableW = qMax(1.0, width() - padX * 2);
    const qreal usableH = qMax(1.0, height() - padY * 2);

    std::vector<QVector2D> pts;
    pts.reserve(n);
    for (int i = 0; i < n; ++i) {
        const qreal x = padX + (qreal(i) / (n - 1)) * usableW;
        const qreal y = padY + usableH
                        - ((m_samples.at(i).toReal() - lo) / span) * usableH;
        pts.emplace_back(float(x), float(y));
    }

    // expand the polyline into a triangle strip
    QSGGeometryNode *node = static_cast<QSGGeometryNode *>(oldNode);
    QSGGeometry *geom = nullptr;

    const int vertexCount = n * 2;

    if (!node) {
        node = new QSGGeometryNode;
        geom = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), vertexCount);
        geom->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        node->setGeometry(geom);
        node->setFlag(QSGNode::OwnsGeometry);

        auto *mat = new QSGFlatColorMaterial;
        mat->setColor(m_stroke);
        node->setMaterial(mat);
        node->setFlag(QSGNode::OwnsMaterial);
    } else {
        geom = node->geometry();
        if (geom->vertexCount() != vertexCount)
            geom->allocate(vertexCount);
        auto *mat = static_cast<QSGFlatColorMaterial *>(node->material());
        if (mat->color() != m_stroke) {
            mat->setColor(m_stroke);
            node->markDirty(QSGNode::DirtyMaterial);
        }
    }

    QSGGeometry::Point2D *v = geom->vertexDataAsPoint2D();
    const float half = float(m_lineWidth) / 2.0f;

    for (int i = 0; i < n; ++i) {
        // Normal of the averaged direction at this vertex, so joints
        // stay the right thickness instead of pinching on corners.
        QVector2D dir;
        if (i == 0)
            dir = pts[1] - pts[0];
        else if (i == n - 1)
            dir = pts[n - 1] - pts[n - 2];
        else
            dir = (pts[i + 1] - pts[i - 1]);

        if (dir.lengthSquared() < 1e-12f)
            dir = QVector2D(1.0f, 0.0f);
        dir.normalize();

        const QVector2D nrm(-dir.y(), dir.x());
        v[i * 2 + 0].set(pts[i].x() + nrm.x() * half, pts[i].y() + nrm.y() * half);
        v[i * 2 + 1].set(pts[i].x() - nrm.x() * half, pts[i].y() - nrm.y() * half);
    }

    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}
