import SwiftUI
import UIKit

struct ChapterCardView: View {
    let chapter: ChapterRecord
    var photos: PhotoLibraryService
    var allowsExport: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let id = chapter.heroIdentifier, let asset = photos.asset(for: id) {
                AssetImageView(asset: asset)
                    .aspectRatio(4 / 5, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.rewindSurface)
                    .aspectRatio(4 / 5, contentMode: .fit)
            }

            Text(chapter.title)
                .font(RewindFont.heading)
                .foregroundStyle(Color.rewindTextPrimary)
            Text("\(chapter.reviewedCount) reviewed · \(ByteFormat.string(chapter.bytesFreed)) freed")
                .font(RewindFont.caption)
                .foregroundStyle(Color.rewindTextSecondary)

            if allowsExport, let url = exportURL() {
                ShareLink(item: url) {
                    Text("Export card")
                        .font(RewindFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rewindTextPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().stroke(Color.rewindBorder, lineWidth: 1))
                }
            } else if !allowsExport {
                Text("Export is a Premium feature.")
                    .font(RewindFont.caption)
                    .foregroundStyle(Color.rewindTextSecondary)
            }
        }
    }

    private func exportURL() -> URL? {
        let renderer = ImageRenderer(content: exportBody)
        renderer.scale = 1
        guard let data = renderer.uiImage?.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rewind-\(chapter.title).png")
        try? data.write(to: url)
        return url
    }

    private var exportBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rewind")
                .font(RewindFont.caption)
                .textCase(.uppercase)
            Text(chapter.title)
                .font(RewindFont.title)
            Text("\(chapter.reviewedCount) photos reviewed")
                .font(RewindFont.body)
        }
        .foregroundStyle(Color.rewindTextPrimary)
        .padding(48)
        .frame(width: 1080, height: 1350, alignment: .bottomLeading)
        .background(Color.rewindBackground)
    }
}
