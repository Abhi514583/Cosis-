import SwiftUI

public enum SuggestionType: Int, CaseIterable {
    case pr = 0
    case overload = 1
    case deload = 2
    
    var title: String {
        switch self {
        case .pr: return "PR"
        case .overload: return "PROG"
        case .deload: return "DELOAD"
        }
    }
    
    func calculateWeight(base: Double, unit: WeightUnit) -> Double {
        switch self {
        case .pr: return base
        case .overload: 
            // 2.5kg jump or 5lb jump
            return base + (unit == .kg ? 2.5 : 5.0)
        case .deload: return base * 0.90 // -10%
        }
    }
}

public struct SuggestionPill: View {

    let baseWeightKg: Double
    let baseReps: Int
    var onTap: ((Double, Int) -> Void)? = nil
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = .zero
    @State private var showInfoAlert = false
    @AppStorage("hasHiddenSuggestionInfo") private var hasHiddenSuggestionInfo = false
    
    public init(baseWeightKg: Double, baseReps: Int, onTap: ((Double, Int) -> Void)? = nil) {
        self.baseWeightKg = baseWeightKg
        self.baseReps = baseReps
        self.onTap = onTap
    }
    
    private var currentType: SuggestionType {
        SuggestionType(rawValue: currentIndex) ?? .pr
    }
    
    private var displayWeight: Double {
        currentType.calculateWeight(base: baseWeightKg, unit: dataManager.weightUnit)
    }
    
    // Simplistic logic to vary reps or just keep them same
    private var displayReps: Int {
        switch currentType {
        case .pr: return baseReps
        case .overload: return max(1, baseReps - 1) // Typically fewer reps on prog jump if static
        case .deload: return baseReps + 2 // More reps on deload
        }
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                // Left swipe affordance
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.5))
                
                VStack(spacing: 2) {
                    Text(currentType.title)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                    
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(displayWeight, specifier: "%.1f")")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText())
                    
                    Text("\(dataManager.weightUnit.rawValue) × \(displayReps)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                }
                .foregroundColor(.white)
                
                // Right swipe affordance
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        dragOffset = value.translation.width / 3
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 20
                        var changed = false
                        
                        if value.translation.width < -threshold {
                            // Swiped left -> next
                            if currentIndex < SuggestionType.allCases.count - 1 {
                                currentIndex += 1
                                changed = true
                            }
                        } else if value.translation.width > threshold {
                            // Swiped right -> prev
                            if currentIndex > 0 {
                                currentIndex -= 1
                                changed = true
                            }
                        }
                        
                        if changed {
                            let generator = UIImpactFeedbackGenerator(style: .rigid)
                            generator.impactOccurred()
                        }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onTap?(displayWeight, displayReps)
            }
            
            // Small info button
            if !hasHiddenSuggestionInfo {
                Button(action: {
                    showInfoAlert = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.onSurfaceVariant.opacity(0.5))
                }
                .alert("Smart Suggestions", isPresented: $showInfoAlert) {
                    Button("Read & Dismiss", role: .cancel) { }
                    Button("Don't Show Again", role: .destructive) {
                        hasHiddenSuggestionInfo = true
                    }
                } message: {
                    Text("Swipe left or right to calculate Overload and Deload weights. Tap the pill to auto-fill your set!")
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SuggestionPill(baseWeightKg: 100, baseReps: 10)
        SuggestionPill(baseWeightKg: 80, baseReps: 8)
    }
    .padding()
    .background(Theme.Colors.surfaceContainerLow)
    .environmentObject(WorkoutDataManager())
}
