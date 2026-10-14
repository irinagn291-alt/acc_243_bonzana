import UIKit

/// One cue block in a pet column.
/// The whole cell is the hit target. A right swipe or a tap reports the cue id.
/// The column head is labeled Open. A struck cue is labeled Struck.
final class CueColumnCell: UICollectionViewCell {
    static let reuse = "CueColumnCell"

    var onSwipe: ((UUID) -> Void)?
    private var cueID: UUID?
    private let nameLabel = UILabel()
    private let petLabel = UILabel()
    private let stateLabel = UILabel()
    private let markView = UIImageView()
    private let textStack = UIStackView()
    private let row = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(DesignTokens.surface)
        contentView.layer.cornerRadius = StageMeasure.card
        contentView.layer.borderWidth = StageMeasure.hairline
        contentView.layer.borderColor = UIColor(DesignTokens.muted).cgColor
        contentView.clipsToBounds = true

        markView.translatesAutoresizingMaskIntoConstraints = false
        markView.contentMode = .scaleAspectFit
        markView.clipsToBounds = true
        markView.layer.cornerRadius = StageMeasure.chip
        markView.isAccessibilityElement = false
        markView.image = UIImage(named: "ftl_ControlFace")

        nameLabel.adjustsFontForContentSizeCategory = false
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        petLabel.adjustsFontForContentSizeCategory = false
        petLabel.numberOfLines = 1
        petLabel.lineBreakMode = .byTruncatingTail
        petLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        stateLabel.adjustsFontForContentSizeCategory = false
        stateLabel.numberOfLines = 1
        stateLabel.lineBreakMode = .byTruncatingTail
        stateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(petLabel)
        textStack.axis = .vertical
        textStack.spacing = StageMeasure.unit
        textStack.alignment = .fill

        let stateRow = UIStackView(arrangedSubviews: [markView, stateLabel])
        stateRow.axis = .horizontal
        stateRow.alignment = .center
        stateRow.spacing = StageMeasure.unit

        row.addArrangedSubview(textStack)
        row.addArrangedSubview(stateRow)
        row.axis = .vertical
        row.alignment = .fill
        row.spacing = StageMeasure.unit
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        let pad = StageMeasure.steps(2)
        NSLayoutConstraint.activate([
            markView.widthAnchor.constraint(equalToConstant: StageMeasure.steps(4)),
            markView.heightAnchor.constraint(equalToConstant: StageMeasure.steps(4)),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: pad),
            row.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -pad),
        ])

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .right
        contentView.addGestureRecognizer(swipe)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { contentView.alpha = isHighlighted ? 0.72 : 1 }
    }

    func configure(cue: CueRecord, pet: PetRecord?, struck: Bool, isHead: Bool) {
        cueID = cue.id
        nameLabel.font = StageType.uiFont(.headline, bold: true)
        nameLabel.textColor = UIColor(DesignTokens.ink)
        petLabel.font = StageType.uiFont(.caption)
        petLabel.textColor = UIColor(DesignTokens.ink)
        stateLabel.font = StageType.uiFont(.caption, bold: true)
        nameLabel.text = cue.title
        let petName = pet?.name ?? "Pet"
        petLabel.text = petName
        let state = struck ? "Struck" : (isHead ? "Open" : "Waiting")
        stateLabel.text = state
        stateLabel.textColor = UIColor(DesignTokens.ink)
        markView.isHidden = isHead == false
        let slot = AccentSlot.color(for: pet?.accentSlot ?? "violet")
        contentView.layer.borderColor = UIColor(slot).cgColor
        accessibilityLabel = "\(cue.title), \(petName), \(state)"
        accessibilityHint = isHead ? "Swipe right to strike this column." : "Swipe right to keep the order."
    }

    @objc private func swiped() {
        guard let cueID else { return }
        onSwipe?(cueID)
    }
}

/// Footer supplementary view. Counts sealed days walking backward.
final class StreakRailView: UICollectionReusableView {
    static let reuse = "StreakRailView"
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(DesignTokens.surface)
        layer.cornerRadius = StageMeasure.card
        layer.borderWidth = StageMeasure.hairline
        layer.borderColor = UIColor(DesignTokens.muted).cgColor
        label.adjustsFontForContentSizeCategory = false
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        let pad = StageMeasure.steps(2)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            label.topAnchor.constraint(equalTo: topAnchor, constant: pad),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -pad),
        ])
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(streak: Int, daykey: Int) {
        label.font = StageType.uiFont(.body)
        label.textColor = UIColor(DesignTokens.ink)
        let days = StageType.digits(streak)
        let day = StageType.calendarDay(daykey)
        label.text = "Seal streak \(days). This day is \(day)."
        accessibilityLabel = label.text
    }
}
