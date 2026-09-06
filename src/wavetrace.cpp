#include "wavetrace.h"

#include <QSGGeometryNode>
#include <QSGFlatColorMaterial>
#include <QVector2D>
#include <vector>

WaveTrace::WaveTrace(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

void WaveTrace::setSamples(const QVariantList &s) { m_samples = s; emit samplesChanged(); update(); }
void WaveTrace::setStroke(const QColor &c) { if (m_stroke == c) return; m_stroke = c; emit strokeChanged(); update(); }
void WaveTrace::setMinY(qreal v) { if (qFuzzyCompare(m_minY, v)) return; m_minY = v; emit rangeChanged(); update(); }
void WaveTrace::setMaxY(qreal v) { if (qFuzzyCompare(m_maxY, v)) return; m_maxY = v; emit rangeChanged(); update(); }
void WaveTrace::setLineWidth(qreal w) { if (qFuzzyCompare(m_lineWidth, w)) return; m_lineWidth = w; emit lineWidthChanged(); update(); }
void WaveTrace::setFilled(bool f) { if (m_filled == f) return; m_filled = f; emit filledChanged(); update(); }
void WaveTrace::setFillOpacity(qreal o) { if (qFuzzyCompare(m_fillOpacity, o)) return; m_fillOpacity = o; emit filledChanged(); update(); }

QSGNode *WaveTrace::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    const int n = m_samples.size();
    if (n < 2 || width() <= 0 || height() <= 0) {
        delete oldNode;
        return nullptr;
    }

    const qreal span = (m_maxY - m_minY) != 0.0 ? (m_maxY - m_minY) : 1.0;
    const qreal w = width(), h = height();

    std::vector<QVector2D> pts;
    pts.reserve(n);
    for (int i = 0; i < n; ++i) {
        const qreal v = qBound(m_minY, m_samples.at(i).toReal(), m_maxY);
        const qreal x = (qreal(i) / (n - 1)) * w;
        const qreal y = h - ((v - m_minY) / span) * h;
        pts.emplace_back(float(x), float(y));
    }

    auto *root = oldNode ? oldNode : new QSGNode;
    while (root->childCount() > (m_filled ? 2 : 1))
        delete root->childAtIndex(root->childCount() - 1);

    // area fill, drawn first so the stroke sits on top
    if (m_filled) {
        auto *fillNode = root->childCount() > 0
                       ? static_cast<QSGGeometryNode *>(root->childAtIndex(0)) : nullptr;
        if (!fillNode) {
            fillNode = new QSGGeometryNode;
            auto *g = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), n * 2);
            g->setDrawingMode(QSGGeometry::DrawTriangleStrip);
            fillNode->setGeometry(g);
            fillNode->setFlag(QSGNode::OwnsGeometry);
            auto *m = new QSGFlatColorMaterial;
            fillNode->setMaterial(m);
            fillNode->setFlag(QSGNode::OwnsMaterial);
            root->prependChildNode(fillNode);
        }
        auto *g = fillNode->geometry();
        if (g->vertexCount() != n * 2) g->allocate(n * 2);
        auto *v = g->vertexDataAsPoint2D();
        for (int i = 0; i < n; ++i) {
            v[i * 2 + 0].set(pts[i].x(), pts[i].y());
            v[i * 2 + 1].set(pts[i].x(), float(h));
        }
        QColor fc = m_stroke;
        fc.setAlphaF(float(m_fillOpacity));
        auto *mat = static_cast<QSGFlatColorMaterial *>(fillNode->material());
        if (mat->color() != fc) { mat->setColor(fc); fillNode->markDirty(QSGNode::DirtyMaterial); }
        fillNode->markDirty(QSGNode::DirtyGeometry);
    }

    // the stroke, expanded into a ribbon
    const int strokeIndex = m_filled ? 1 : 0;
    auto *lineNode = root->childCount() > strokeIndex
                   ? static_cast<QSGGeometryNode *>(root->childAtIndex(strokeIndex)) : nullptr;
    if (!lineNode) {
        lineNode = new QSGGeometryNode;
        auto *g = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), n * 2);
        g->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        lineNode->setGeometry(g);
        lineNode->setFlag(QSGNode::OwnsGeometry);
        auto *m = new QSGFlatColorMaterial;
        m->setColor(m_stroke);
        lineNode->setMaterial(m);
        lineNode->setFlag(QSGNode::OwnsMaterial);
        root->appendChildNode(lineNode);
    }
    auto *lg = lineNode->geometry();
    if (lg->vertexCount() != n * 2) lg->allocate(n * 2);
    auto *lv = lg->vertexDataAsPoint2D();
    const float half = float(m_lineWidth) / 2.0f;
    for (int i = 0; i < n; ++i) {
        QVector2D dir = (i == 0) ? pts[1] - pts[0]
                      : (i == n - 1) ? pts[n - 1] - pts[n - 2]
                                     : pts[i + 1] - pts[i - 1];
        if (dir.lengthSquared() < 1e-12f) dir = QVector2D(1.0f, 0.0f);
        dir.normalize();
        const QVector2D nrm(-dir.y(), dir.x());
        lv[i * 2 + 0].set(pts[i].x() + nrm.x() * half, pts[i].y() + nrm.y() * half);
        lv[i * 2 + 1].set(pts[i].x() - nrm.x() * half, pts[i].y() - nrm.y() * half);
    }
    auto *lmat = static_cast<QSGFlatColorMaterial *>(lineNode->material());
    if (lmat->color() != m_stroke) { lmat->setColor(m_stroke); lineNode->markDirty(QSGNode::DirtyMaterial); }
    lineNode->markDirty(QSGNode::DirtyGeometry);

    return root;
}
