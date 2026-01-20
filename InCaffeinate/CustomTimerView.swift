import SwiftUI

struct CustomTimerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var controller: CaffeinateController
    
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    
    private let maxHours = 24
    private let maxMinutes = 59
    
    var totalMinutes: Int {
        selectedHours * 60 + selectedMinutes
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Custom Timer")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            HStack(spacing: 30) {
                // Hours scroller
                VStack(spacing: 8) {
                    Text("Hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ScrollablePicker(
                        selection: $selectedHours,
                        range: 0...maxHours
                    )
                    .frame(width: 80, height: 120)
                }
                
                Text(":")
                    .font(.title)
                    .padding(.top, 20)
                
                // Minutes scroller
                VStack(spacing: 8) {
                    Text("Minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ScrollablePicker(
                        selection: $selectedMinutes,
                        range: 0...maxMinutes
                    )
                    .frame(width: 80, height: 120)
                }
            }
            .padding(.vertical)
            
            Text("Total: \(totalMinutes) minutes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Start Timer") {
                    controller.startTimer(minutes: totalMinutes)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(totalMinutes == 0 || !controller.isActive)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(width: 300, height: 380)
    }
}

struct ScrollablePicker: View {
    @Binding var selection: Int
    let range: ClosedRange<Int>
    @State private var itemPositions: [Int: CGFloat] = [:]
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling = false
    @State private var snapWorkItem: DispatchWorkItem?
    
    private let itemHeight: CGFloat = 40
    
    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                let highlightOffset = -itemHeight / 26
                let centerY = geometry.size.height / 2 + highlightOffset
                let padding = (geometry.size.height - itemHeight) / 2
                
                ZStack {
                    // Background highlight for selected item with rounded corners
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(height: itemHeight)
                        .offset(y: highlightOffset)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(range), id: \.self) { value in
                                Text("\(value)")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(value == selection ? .primary : .secondary)
                                    .frame(width: geometry.size.width, height: itemHeight)
                                    .multilineTextAlignment(.center)
                                    .contentShape(Rectangle())
                                    .id(value)
                                    .background(
                                        GeometryReader { itemGeo in
                                            Color.clear.preference(
                                                key: ItemPositionKey.self,
                                                value: [value: itemGeo.frame(in: .named("scroll")).midY]
                                            )
                                        }
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selection = value
                                            proxy.scrollTo(value, anchor: .center)
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, padding)
                        .background(
                            GeometryReader { scrollGeo in
                                Color.clear.preference(
                                    key: ScrollPositionKey.self,
                                    value: -scrollGeo.frame(in: .named("scroll")).minY
                                )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ItemPositionKey.self) { positions in
                        itemPositions = positions
                        updateSelection(centerY: centerY)
                    }
                    .onPreferenceChange(ScrollPositionKey.self) { offset in
                        scrollOffset = offset
                        
                        // Mark as scrolling
                        isScrolling = true
                        snapWorkItem?.cancel()
                        
                        // Calculate which item should be centered based on scroll offset
                        let padding = (geometry.size.height - itemHeight) / 2
                        let adjustedOffset = offset - padding
                        let calculatedIndex = Int(round(adjustedOffset / itemHeight))
                        let clampedIndex = min(max(calculatedIndex, range.lowerBound), range.upperBound)
                        
                        // Update selection if different
                        if clampedIndex != selection {
                            DispatchQueue.main.async {
                                selection = clampedIndex
                            }
                        }
                        
                        // Schedule snap after scrolling stops
                        let workItem = DispatchWorkItem {
                            isScrolling = false
                            
                            // Find closest item to center from actual positions
                            var closestValue = selection
                            var closestDistance: CGFloat = .greatestFiniteMagnitude
                            
                            for (value, yPos) in itemPositions {
                                let distance = abs(yPos - centerY)
                                if distance < closestDistance {
                                    closestDistance = distance
                                    closestValue = value
                                }
                            }
                            
                            // Always snap to closest item for perfect alignment
                            DispatchQueue.main.async {
                                if closestValue != selection {
                                    selection = closestValue
                                }
                                
                                // Force snap to center
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    proxy.scrollTo(selection, anchor: .center)
                                }
                            }
                        }
                        
                        snapWorkItem = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
                    }
                    .onChange(of: selection) { _, newValue in
                        snapWorkItem?.cancel()
                        if !isScrolling {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(selection, anchor: .center)
                        }
                    }
                    .onDisappear {
                        snapWorkItem?.cancel()
                    }
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.15),
                                .init(color: .black, location: 0.85),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
    }
    
    private func updateSelection(centerY: CGFloat) {
        // Only update if we have enough position data
        guard itemPositions.count > 0 else { return }
        
        // Find closest item to center
        var closestValue = selection
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        
        for (value, yPos) in itemPositions {
            let distance = abs(yPos - centerY)
            if distance < closestDistance {
                closestDistance = distance
                closestValue = value
            }
        }
        
        // Update if significantly closer (within half item height)
        if closestValue != selection && closestDistance < itemHeight / 2 {
            DispatchQueue.main.async {
                selection = closestValue
            }
        }
    }
}

struct ItemPositionKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct ScrollPositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
