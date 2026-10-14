import UIKit

/// Timeline flow layout for the cap grid.
/// Each section is one pet column. Cells stack top to bottom.
/// The streak rail is the only footer, pinned under the tallest column.
final class CapGridFlowLayout: UICollectionViewFlowLayout {
    var minimumRowHeight: CGFloat = StageMeasure.cueRowHeight
    var railHeight: CGFloat = StageMeasure.railHeight
    /// Cue titles per pet column. Column width is at least the full title.
    var columnCueTitles: [[String]] = []

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var footer: UICollectionViewLayoutAttributes?
    private var content = CGSize.zero

    override func prepare() {
        super.prepare()
        cache.removeAll()
        footer = nil
        guard let collectionView, collectionView.bounds.width > 1 else {
            content = .zero
            return
        }
        let sections = collectionView.numberOfSections
        let gap = StageMeasure.unit
        let margin = StageMeasure.steps(3)
        let widthBudget = collectionView.bounds.width - margin * 2 - gap * CGFloat(max(sections - 1, 0))
        let widths = columnWidths(sectionCount: sections, widthBudget: widthBudget)
        var counts: [Int] = []
        for section in 0..<sections {
            counts.append(collectionView.numberOfItems(inSection: section))
        }
        let tallest = max(counts.max() ?? 0, 0)
        let stackGaps = gap * CGFloat(max(tallest - 1, 0))
        let usable = collectionView.bounds.height - margin * 2 - railHeight - gap - stackGaps
        let grown = tallest > 0 ? floor(usable / CGFloat(tallest)) : minimumRowHeight
        let cellHeight = max(minimumRowHeight, grown)
        var maxBottom = margin
        var x = margin
        for section in 0..<sections {
            var y = margin
            let columnWidth = widths[section]
            let count = counts[section]
            for item in 0..<count {
                let index = IndexPath(item: item, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: index)
                attributes.frame = CGRect(x: x, y: y, width: columnWidth, height: cellHeight)
                cache.append(attributes)
                y += cellHeight + gap
            }
            maxBottom = max(maxBottom, y)
            x += columnWidth + gap
        }
        let used = widths.reduce(0, +) + gap * CGFloat(max(sections - 1, 0))
        let width = max(collectionView.bounds.width, margin * 2 + used)
        if sections > 0 {
            let attributes = UICollectionViewLayoutAttributes(
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                with: IndexPath(item: 0, section: 0)
            )
            let railY = max(maxBottom, collectionView.bounds.height - margin - railHeight)
            attributes.frame = CGRect(x: margin, y: railY, width: width - margin * 2, height: railHeight)
            footer = attributes
            maxBottom = railY + railHeight + margin
        }
        content = CGSize(width: width, height: max(maxBottom, collectionView.bounds.height))
    }

    override var collectionViewContentSize: CGSize { content }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var hits = cache.filter { $0.frame.intersects(rect) }
        if let footer, footer.frame.intersects(rect) {
            hits.append(footer)
        }
        return hits
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.indexPath == indexPath }
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard elementKind == UICollectionView.elementKindSectionFooter, indexPath.section == 0 else {
            return nil
        }
        return footer
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView?.bounds.size != newBounds.size
    }

    /// Each column is wide enough for its longest cue name on one line.
    /// Spare stage width is shared so a short company still fills the screen.
    private func columnWidths(sectionCount: Int, widthBudget: CGFloat) -> [CGFloat] {
        guard sectionCount > 0 else { return [] }
        let font = StageType.uiFont(.headline, bold: true)
        let pad = StageMeasure.steps(2) * 2 + StageMeasure.steps(1)
        var needed: [CGFloat] = []
        for section in 0..<sectionCount {
            let titles = section < columnCueTitles.count ? columnCueTitles[section] : []
            let longest = titles.reduce(CGFloat(0)) { partial, title in
                let measured = (title as NSString).size(withAttributes: [.font: font]).width
                return max(partial, ceil(measured))
            }
            needed.append(max(StageMeasure.steps(16), longest + pad))
        }
        let sum = needed.reduce(0, +)
        if sum >= widthBudget {
            return needed
        }
        let extra = (widthBudget - sum) / CGFloat(sectionCount)
        return needed.map { $0 + extra }
    }
}
