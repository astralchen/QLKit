//
//  ViewController.swift
//  MessageCell
//
//  Created by Sondra on 2025/12/17.
//

import UIKit
import AppLocalization

final class MesssageViewController: DemoViewController {

    override var localizedTitleKey: String? { "demo.messages.title" }

    private var collectionView: UICollectionView!
    private var data: [MessageModel] = MessageModel.mockData

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupCollectionView()
        reloadLocalizedContent()
        reloadLayoutDirection(DemoLocalization.currentUIKitDirection)
    }

    override func reloadLocalizedContent() {
        super.reloadLocalizedContent()
        data = MessageModel.localizedMockData()
        collectionView?.reloadData()
    }

    override func reloadLayoutDirection(_ direction: UIUserInterfaceLayoutDirection) {
        super.reloadLayoutDirection(direction)
        collectionView?.applyUserInterfaceLayoutDirection(
            direction.appLayoutDirection,
            preservingVisibleItem: false
        )
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: makeLayout()
        )

        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground

        collectionView.register(
            MessageCell.self,
            forCellWithReuseIdentifier: "MessageCell"
        )

        collectionView.dataSource = self
        view.addSubview(collectionView)
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(80)
            )

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(80)
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: groupSize,
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)

            return section
        }
    }
}

extension MesssageViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MessageCell",
            for: indexPath
        ) as! MessageCell

        cell.configure(data[indexPath.item])
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.layer.cornerRadius = 8

        return cell
    }
}


#Preview {
    UINavigationController(rootViewController: MesssageViewController())
}
