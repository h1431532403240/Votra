//
//  SkippedSegmentsSheet.swift
//  Votra
//
//  Sheet displaying segments that couldn't be processed by AI due to content restrictions.
//  Follows macOS 26 Liquid Glass design guidelines.
//

import SwiftUI

struct SkippedSegmentsSheet: View {
    // MARK: - Properties

    let skippedTexts: [String]

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()

            Divider()

            // Content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(skippedTexts.indices, id: \.self) { index in
                        segmentRow(index: index, text: skippedTexts[index])
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300)

            Divider()

            // Footer
            footerView
                .padding()
        }
        .frame(width: 500)
        .background(.regularMaterial)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .symbolRenderingMode(.multicolor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Content Restrictions Detected")
                    .font(.headline)

                Text("\(skippedTexts.count) segment(s) could not be processed by AI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var footerView: some View {
        HStack {
            Text("These segments were kept as-is without AI segmentation.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("OK") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func segmentRow(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 8))
    }
}

#Preview {
    SkippedSegmentsSheet(skippedTexts: [
        "我的身體這麼熱，有點不好意思，不要摸哪裡，不行",
        "討厭，被克羅斯君做了很多事的我",
        "竟然自己擠出來喝，這樣的感覺真的太奇怪了"
    ])
}
