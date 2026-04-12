import SwiftUI
import PhotosUI

struct BodyPhotoSetupView: View {
    @EnvironmentObject var dataManager: WorkoutDataManager
    @Environment(\.dismiss) var dismiss
    
    let side: PhotoSide
    let editingMode: Bool // true = just assigning zones, false = full setup including photo
    
    @State private var capturedImage: UIImage?
    @State private var showPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedMuscle: MusclePart?
    @State private var pendingZonePoint: CGPoint?
    @State private var showMuscleChips = false
    
    var body: some View {
        ZStack {
            Theme.Colors.surface.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(side == .front ? "FRONT" : "BACK")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(dataManager.primaryColor)
                        Text(capturedImage == nil ? "Add Photo" : "Assign Zones")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: {
                        // Phase 8 fix: Only persist on explicit save action
                        if capturedImage != nil && selectedItem != nil {
                            if let img = capturedImage {
                                dataManager.saveProgressionPhoto(img, side: side)
                            }
                        }
                        dismiss()
                    }) {
                        Text("SAVE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor((capturedImage != nil && selectedItem != nil) || editingMode ? dataManager.primaryColor : .gray)
                    }
                    .disabled(capturedImage == nil)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                if let image = capturedImage {
                    // Photo with tappable zone overlay
                    GeometryReader { geo in
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    pendingZonePoint = location
                                    pendingGeoSize = geo.size
                                    showMuscleChips = true
                                }
                            
                            // Placed zones
                            ForEach(dataManager.zones(for: side)) { zone in
                                let x = zone.normalizedX * geo.size.width
                                let y = zone.normalizedY * geo.size.height
                                let color = dataManager.colorForMuscle(zone.muscleName)
                                
                                ZStack {
                                    Circle()
                                        .fill(color.opacity(0.3))
                                        .frame(width: 44, height: 44)
                                    Circle()
                                        .fill(color)
                                        .frame(width: 20, height: 20)
                                        .overlay(Circle().stroke(.white, lineWidth: 2))
                                    Text(String(zone.muscleName.prefix(2)))
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundColor(.white)
                                }
                                .position(x: x, y: y)
                                .onLongPressGesture {
                                    let gen = UIImpactFeedbackGenerator(style: .heavy)
                                    gen.impactOccurred()
                                    dataManager.removeZone(id: zone.id)
                                }
                            }
                            
                            // Instruction overlay
                            if dataManager.zones(for: side).isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "hand.tap.fill")
                                        .font(.system(size: 24))
                                    Text("TAP ON YOUR BODY")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                    Text("to assign muscle groups")
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .padding(20)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 16)
                    
                } else {
                    // Empty state — invite photo
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "person.fill.viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(dataManager.primaryColor.opacity(0.4))
                        Text("Add a full-body photo")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Stand in good light, arms slightly out.\nWe'll save it only on your device.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle")
                                Text("CHOOSE FROM LIBRARY")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(dataManager.primaryColor)
                            .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                
                // Bottom info
                if capturedImage != nil {
                    Text("Long-press a dot to remove it")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }
            }
        }
        // Muscle picker sheet
        .sheet(isPresented: $showMuscleChips) {
            MuscleSelectorSheet(selectedMuscle: $selectedMuscle) { muscle in
                if let point = pendingZonePoint, let geo = pendingGeoSize {
                    let zone = BodyZone(
                        muscleName: muscle.name,
                        normalizedX: point.x / geo.width,
                        normalizedY: point.y / geo.height,
                        side: side
                    )
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    dataManager.addZone(zone)
                }
                showMuscleChips = false
                pendingZonePoint = nil
            }
            .presentationDetents([.fraction(0.4)])
            .presentationBackground(Theme.Colors.surface)
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    capturedImage = ui
                }
            }
        }
    }
    
    // We store last geo size to calculate normalized coordinates
    @State private var pendingGeoSize: CGSize?
}

// MARK: - Muscle Selector Sheet

struct MuscleSelectorSheet: View {
    @Binding var selectedMuscle: MusclePart?
    let onSelect: (MusclePart) -> Void
    @EnvironmentObject var dataManager: WorkoutDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Capsule().fill(.white.opacity(0.15)).frame(width: 36, height: 4).frame(maxWidth: .infinity).padding(.top, 12)
            
            Text("ASSIGN MUSCLE")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(dataManager.primaryColor)
                .padding(.horizontal, 24)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                ForEach(dataManager.availableParts) { part in
                    Button(action: { onSelect(part) }) {
                        VStack(spacing: 6) {
                            Image(systemName: part.icon)
                                .font(.system(size: 18))
                                .foregroundColor(part.color)
                            Text(part.name)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(part.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(part.color.opacity(0.4), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}
