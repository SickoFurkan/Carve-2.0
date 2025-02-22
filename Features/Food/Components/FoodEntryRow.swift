import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry
    let dailyGoals: (calories: Int, protein: Int, carbs: Int, fat: Int)
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name == "Foto analyse" ? entry.description : entry.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if entry.name != "Foto analyse" && !entry.description.isEmpty {
                        Text(entry.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                    
                    Text("\(entry.amount)g")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(entry.calories) kcal")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        MacroLabel(value: entry.protein, label: "P", color: .blue)
                        MacroLabel(value: entry.carbs, label: "K", color: .orange)
                        MacroLabel(value: entry.fat, label: "V", color: .red)
                    }
                }
            }
            
            if let imageBase64 = entry.imageBase64,
               let imageData = Data(base64Encoded: imageBase64),
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            print("🎯 Rendering FoodEntryRow:")
            print("   - Name: \(entry.name)")
            print("   - Description: \(entry.description)")
        }
    }
}

private struct MacroLabel: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .font(.subheadline)
            Text(label)
                .font(.caption)
        }
        .foregroundColor(color)
    }
} 