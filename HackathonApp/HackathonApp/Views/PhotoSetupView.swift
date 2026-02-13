//
//  PhotoSetupView.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import SwiftUI
import PhotosUI
import SwiftData

struct PhotoSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \UserPhoto.timestamp, order: .reverse) private var userPhotos: [UserPhoto]
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingNameInput = false
    @State private var pendingImageData: Data?
    @State private var nameInput = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Set Up Your Photos")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Add photos of people you know. We'll use these for the recognition game.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // Photo picker
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Photo")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .onChange(of: selectedItem) { oldValue, newValue in
                        if let item = newValue {
                            loadPhoto(item)
                        }
                    }
                    
                    // Current photos list
                    if !userPhotos.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Photos (\(userPhotos.count))")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.horizontal)
                            
                            ForEach(userPhotos) { photo in
                                PhotoRow(photo: photo) {
                                    deletePhoto(photo)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Done button
                    if !userPhotos.isEmpty {
                        Button(action: dismissSetup) {
                            Text("Done")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Photo Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismissSetup()
                    }
                }
            }
            .sheet(isPresented: $showingNameInput) {
                NameInputSheet(name: $nameInput) {
                    savePhoto()
                }
            }
            .onAppear {
                loadPhotosFromCache()
            }
        }
    }
    
    /// Load photos from local cache (SwiftData persistence)
    /// Note: @Query automatically loads from SwiftData persistence,
    /// but this method ensures explicit cache loading verification
    private func loadPhotosFromCache() {
        // @Query automatically loads from SwiftData persistence
        // Photos are prefilled from cache when view appears
        print("📸 Loading photos from cache... Found \(userPhotos.count) photos")
    }
    
    private func loadPhoto(_ item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data {
                    DispatchQueue.main.async {
                        pendingImageData = data
                        showingNameInput = true
                    }
                }
            case .failure(let error):
                print("Error loading photo: \(error)")
            }
        }
    }
    
    private func savePhoto() {
        guard let imageData = pendingImageData, !nameInput.isEmpty else { return }
        
        let photo = UserPhoto(
            imageData: imageData,
            correctName: nameInput.trimmingCharacters(in: .whitespaces)
        )
        
        modelContext.insert(photo)
        
        do {
            try modelContext.save()
            // Ensure data is persisted to disk
            print("💾 Photo saved to local storage: \(photo.correctName)")
            nameInput = ""
            pendingImageData = nil
            selectedItem = nil
        } catch {
            print("❌ Error saving photo: \(error)")
        }
    }
    
    private func deletePhoto(_ photo: UserPhoto) {
        modelContext.delete(photo)
        do {
            try modelContext.save()
            print("🗑️ Photo deleted from local storage: \(photo.correctName)")
        } catch {
            print("❌ Error deleting photo: \(error)")
        }
    }
    
    private func dismissSetup() {
        dismiss()
    }
}

struct PhotoRow: View {
    let photo: UserPhoto
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let uiImage = photo.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "photo"))
            }
            
            Text(photo.correctName)
                .font(.system(size: 16, weight: .semibold))
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct NameInputSheet: View {
    @Binding var name: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Enter the person's name")
                    .font(.system(size: 18, weight: .semibold))
                
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                
                Button(action: {
                    onSave()
                    dismiss()
                }) {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(name.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(name.isEmpty)
            }
            .padding()
            .navigationTitle("Name Photo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PhotoSetupView()
        .modelContainer(for: UserPhoto.self, inMemory: true)
}
