import SwiftUI

// MARK: - Main Analytics Body View (replaces HumanBodyView)
struct BodyPhotoAnalyticsView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @State private var activeSide: PhotoSide = .front
    @State private var showSetup = false
    @State private var selectedMusclePart: String? = nil
    @State private var showGallery = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Side Toggle + Edit Button
            HStack {
                // Front / Back pill
                HStack(spacing: 4) {
                    ForEach([PhotoSide.front, PhotoSide.back], id: \.self) { side in
                        Button(action: {
                            withAnimation(.spring()) { activeSide = side }
                        }) {
                            Text(side == .front ? "FRONT" : "BACK")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(activeSide == side ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(activeSide == side ? dataManager.primaryColor : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(4)
                .background(Theme.Colors.surfaceContainerHigh)
                .clipShape(Capsule())
                
                Spacer()
                
                Button(action: { showSetup = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("ADD PHOTO")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(dataManager.primaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(dataManager.primaryColor.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            // Main photo area
            if let latest = dataManager.latestPhoto(for: activeSide),
               let image = dataManager.loadImage(filename: latest.filename) {
                // Photo with muscle zone dots
                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                        
                        // Dark gradient overlay for readability
                        LinearGradient(
                            colors: [.clear, .clear, .black.opacity(0.3)],
                            startPoint: .top, endPoint: .bottom
                        )
                        
                        // Zone dots
                        ForEach(dataManager.zones(for: activeSide)) { zone in
                            let x = zone.normalizedX * geo.size.width
                            let y = zone.normalizedY * geo.size.height
                            let color = dataManager.colorForMuscle(zone.muscleName)
                            
                            ZoneMarker(muscleName: zone.muscleName, color: color)
                                .position(x: x, y: y)
                                .onTapGesture {
                                    let gen = UIImpactFeedbackGenerator(style: .medium)
                                    gen.impactOccurred()
                                    selectedMusclePart = zone.muscleName
                                }
                        }
                    }
                }
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
            } else {
                // Empty state
                Button(action: { showSetup = true }) {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(dataManager.primaryColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.fill.viewfinder")
                                .font(.system(size: 32))
                                .foregroundColor(dataManager.primaryColor)
                        }
                        Text("Add Your Body Photo")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Tap areas of your body to assign\nmuscle groups and track progress")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Text("GET STARTED →")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(dataManager.primaryColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(dataManager.primaryColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .background(Theme.Colors.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .ghostBorder(radius: 24)
                }
            }
            
            // Progression Timeline Strip
            if !dataManager.progressionPhotos.filter({ $0.side == activeSide }).isEmpty {
                ProgressionTimelineStrip(side: activeSide, onAdd: { showSetup = true }, onViewAll: { showGallery = true })
            }
        }
        .sheet(isPresented: $showSetup) {
            BodyPhotoSetupView(side: activeSide, editingMode: false)
                .environmentObject(dataManager)
        }
        .sheet(item: Binding(
            get: { selectedMusclePart.map { MuscleSheetItem(name: $0) } },
            set: { selectedMusclePart = $0?.name }
        )) { item in
            AnalyticsDetailView(musclePart: item.name)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showGallery) {
            ProgressionGalleryView(side: activeSide)
                .environmentObject(dataManager)
        }
    }
}

// MARK: - Pulsing Zone Marker

struct ZoneMarker: View {
    let muscleName: String
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: isPulsing ? 52 : 40, height: isPulsing ? 52 : 40)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
            
            // Main dot
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
                .shadow(color: color.opacity(0.6), radius: 6)
            
            // Label
            Text(String(muscleName.prefix(2)))
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white)
        }
        .onAppear { isPulsing = true }
    }
}

// MARK: - Progression Timeline Strip

struct ProgressionTimelineStrip: View {
    let side: PhotoSide
    let onAdd: () -> Void
    let onViewAll: () -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    private var photos: [ProgressionPhoto] {
        dataManager.progressionPhotos.filter { $0.side == side }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PROGRESSION")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                Spacer()
                Button("See All", action: onViewAll)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(dataManager.primaryColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Add button
                    Button(action: onAdd) {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(dataManager.primaryColor.opacity(0.1))
                                .frame(width: 60, height: 80)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(dataManager.primaryColor)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(dataManager.primaryColor.opacity(0.3), lineWidth: 1))
                            Text("ADD")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(dataManager.primaryColor)
                        }
                    }
                    
                    ForEach(photos.reversed()) { photo in
                        if let image = dataManager.loadImage(filename: photo.filename) {
                            VStack(spacing: 6) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
                                Text(photo.date.progressionLabel())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Date {
    func progressionLabel() -> String {
        let days = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days < 7 { return "Day \(days)" }
        let weeks = days / 7
        return "Week \(weeks)"
    }
}
