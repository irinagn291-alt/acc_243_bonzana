import SwiftUI

/// SwiftUI host for the single custom collection.
/// Pets are sections. Cues are cells. The streak rail is the footer.
struct CapGridView: UIViewRepresentable {
    var fold: GridFold
    var document: GridDocument
    var rowHeight: CGFloat
    var railHeight: CGFloat
    var isBusy: Bool
    var onSwipe: (UUID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(fold: fold, document: document, onSwipe: onSwipe)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = CapGridFlowLayout()
        layout.minimumRowHeight = rowHeight
        layout.railHeight = railHeight
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = true
        view.alwaysBounceHorizontal = true
        view.showsHorizontalScrollIndicator = true
        view.register(CueColumnCell.self, forCellWithReuseIdentifier: CueColumnCell.reuse)
        view.register(
            StreakRailView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: StreakRailView.reuse
        )
        view.dataSource = context.coordinator
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.fold = fold
        context.coordinator.document = document
        context.coordinator.onSwipe = onSwipe
        if let layout = uiView.collectionViewLayout as? CapGridFlowLayout {
            layout.minimumRowHeight = rowHeight
            layout.railHeight = railHeight
            layout.columnCueTitles = fold.columns.map { column in
                column.cues.map(\.title)
            }
        }
        uiView.isUserInteractionEnabled = isBusy == false
        uiView.alpha = isBusy ? 0.72 : 1
        uiView.reloadData()
        uiView.collectionViewLayout.invalidateLayout()
    }

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        var fold: GridFold
        var document: GridDocument
        var onSwipe: (UUID) -> Void

        init(fold: GridFold, document: GridDocument, onSwipe: @escaping (UUID) -> Void) {
            self.fold = fold
            self.document = document
            self.onSwipe = onSwipe
        }

        func numberOfSections(in collectionView: UICollectionView) -> Int {
            fold.columns.count
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            fold.columns[section].cues.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CueColumnCell.reuse, for: indexPath)
            guard let cueCell = cell as? CueColumnCell else { return cell }
            let column = fold.columns[indexPath.section]
            let cue = column.cues[indexPath.item]
            let pet = document.pets.first { $0.id == column.petID }
            let struck = document.strikeMarks.contains { $0.routineID == cue.routineID && $0.daykey == fold.daykey }
            cueCell.configure(cue: cue, pet: pet, struck: struck, isHead: column.head?.cueID == cue.id)
            cueCell.onSwipe = { [weak self] id in
                self?.onSwipe(id)
            }
            return cueCell
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let cue = fold.columns[indexPath.section].cues[indexPath.item]
            onSwipe(cue.id)
            collectionView.deselectItem(at: indexPath, animated: false)
        }

        func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath
        ) -> UICollectionReusableView {
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: StreakRailView.reuse,
                for: indexPath
            )
            if let rail = view as? StreakRailView, indexPath.section == 0 {
                rail.configure(streak: fold.streak, daykey: fold.daykey)
            }
            return view
        }
    }
}
