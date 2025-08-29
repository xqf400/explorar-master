//
//  Cards.swift
//  explorar
//
//  Created by Fabian Kuschke on 10.08.25.
//
import SwiftUI

struct Card: Identifiable {
    let id: Int
    let image: UIImage
    var offset: CGFloat = 0
    var zIndex: Double
    var ki: Bool
}

struct CardStackView: View {
    @State private var selectedIndex = 0
    @Binding private var selectedCardIndex: Int
    @State private var items: [Card]
    let imageSize: CGSize
    let maximumOffset: CGFloat
    var coordinator: UICoordinator
    
    init(imagesAndNames: [ImagePlusName], selectedCardIndex: Binding<Int>? = nil, imageSize: CGSize = CGSize(width: 100, height: 150), coordinator: UICoordinator) {
        var createdItems = [Card]()
        for(id, card) in imagesAndNames.enumerated() {
            var isKi = false
            if card.name.contains("1920") || card.name.contains("2120") {
                isKi = true
            }
            createdItems.append (Card(id: id, image: card.image, zIndex: Double (imagesAndNames.count - 1 - id), ki: isKi))
        }
        self.coordinator = coordinator
        self._selectedCardIndex = selectedCardIndex ?? .constant(0)
        self.items = createdItems
        self.imageSize = imageSize
        self.maximumOffset = imageSize.width * 0.75
    }
    
    var body: some View {
        ZStack{
            ForEach(items) { item in
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFill()
                    //.scaledToFit()
                    .frame(width: imageSize.width, height: imageSize.height)
                    .clipShape(.rect(cornerRadius: imageSize.height * 0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: imageSize.height * 0.05)
                            .stroke(.yellow.opacity(0.20),lineWidth: 4)
                            .padding (-1.5)
                    }
                    .overlay(alignment: .topTrailing) {
                        if item.ki {
                            Text("KI")
                                .font(.caption2)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(6)
                        }
                    }
                    .onTapGesture {
                        if let matchingItem = coordinator.items.first(where: { $0.id == String(item.id) }) {
                            coordinator.selectedItem = matchingItem
                            coordinator.toggleView(show: true)
                        }
                    }
                    .offset(x: item.offset)
                    .zIndex(item.zIndex)
                    .rotation3DEffect(
                        .degrees(item.offset / maximumOffset * -25.0), axis: (x: 0, y: 1, z: 0)
                    )
                    .rotationEffect(.degrees(item.id == selectedIndex ? (item.offset / maximumOffset * 10.0) : item.id % 2 == 0 ?(15 * (1 - (abs(items[selectedIndex].offset / maximumOffset)))) : (-15 * (1 - (abs(items[selectedIndex].offset / maximumOffset))))), anchor: item.id % 2 == 0 ? .bottomLeading : .bottomTrailing)
                    .scaleEffect(item.id == selectedIndex ? CGSize(width: 1 - (abs (item.offset / maximumOffset) * 0.5), height: 1 - (abs(item.offset / maximumOffset) * 0.3)) : CGSize(width: 0.8 + (0.2 * abs (items[selectedIndex].offset / maximumOffset)), height: 0.8 + (0.2 * abs (items[selectedIndex].offset / maximumOffset))))
                    .offset(x: item.offset / 4)
                    .containerShape(Rectangle())
                    .gesture(
                        item.id != selectedIndex ? nil : DragGesture()
                            .onChanged({ value in
                                withAnimation(.linear(duration: 0.1)) {
                                    if abs(value.translation.width) <= maximumOffset {
                                        items[selectedIndex].offset = value.translation.width
                                        withAnimation {
                                            items[selectedIndex].zIndex = Double(items.count - 1)
                                        }
                                    }else {
                                        items[selectedIndex].zIndex = 0
                                    }
                                }
                            })
                            .onEnded({ value in
                                if abs(value.translation.width) > maximumOffset {
                                    items.forEach { items[$0.id].zIndex += 1 }
                                    items[selectedIndex].zIndex = 0
                                }
                                withAnimation {
                                    items[selectedIndex].offset = .zero
                                    selectedIndex = items.first(where: {$0.zIndex == Double(items.count - 1 )})?.id ?? 0
                                    selectedCardIndex = selectedIndex
                                }
                            })
                    )
            }
        }
    }
}
