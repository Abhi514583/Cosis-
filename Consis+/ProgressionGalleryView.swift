import SwiftUI

struct ProgressionGalleryView: View {
    let side: PhotoSide
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedIndex: Int = 0
    @State private var showComparison: Bool = false
    
    private var photos: [ProgressionPhoto] {
        dataManager.progressionPhotos.filter { $0.side == side }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(side == .front ? "FRONT" : "BACK")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(dataManager.primaryColor)
                        Text("PROGRESSION")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: { showComparison.toggle() }) {
                        Image(systemName: showComparison ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle")
                            .font(.system(size: 22))
                            .foregroundColor(showComparison ? dataManager.primaryColor : .white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                if photos.isEmpty {
                    Spacer()
                    Text("No progression photos yet.")
                        .foregroundColor(.gray)
                    Spacer()
                } else if showComparison && photos.count >= 2 {
                    // Side-by-side comparison
                    HStack(spacing: 4) {
                        if let first = dataManager.loadImage(filename: photos.first!.filename) {
                            VStack(spacing: 8) {
                                Image(uiImage: first)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 420)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                Text(photos.first!.date.progressionLabel())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                        if let last = dataManager.loadImage(filename: photos.last!.filename) {
                            VStack(spacing: 8) {
                                Image(uiImage: last)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 420)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                Text("Today")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(dataManager.primaryColor)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                } else {
                    // Full-screen swipeable gallery
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { idx, photo in
                            if let image = dataManager.loadImage(filename: photo.filename) {
                                ZStack(alignment: .bottom) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(24)
                                    
                                    // Date badge
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(photo.date.progressionLabel())
                                                .font(.system(size: 16, weight: .black, design: .rounded))
                                                .foregroundColor(.white)
                                            Text(photo.date, format: .dateTime.day().month().year())
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        Spacer()
                                        Button(action: {
                                            dataManager.deleteProgressionPhoto(photo)
                                            if selectedIndex >= photos.count {
                                                selectedIndex = max(0, photos.count - 1)
                                            }
                                        }) {
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(20)
                                    .background(
                                        LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                                            .clipShape(RoundedRectangle(cornerRadius: 24))
                                    )
                                }
                                .padding(.horizontal, 16)
                                .tag(idx)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Custom dot indicator
                    HStack(spacing: 6) {
                        ForEach(0..<photos.count, id: \.self) { idx in
                            Circle()
                                .fill(selectedIndex == idx ? dataManager.primaryColor : .white.opacity(0.3))
                                .frame(width: selectedIndex == idx ? 8 : 5, height: selectedIndex == idx ? 8 : 5)
                                .animation(.spring(), value: selectedIndex)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }
}
