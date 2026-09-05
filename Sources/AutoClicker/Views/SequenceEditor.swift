import SwiftUI

struct SequenceEditor: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SLIDES")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("+ Add") {
                    model.addSlide()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 15 / 255, green: 118 / 255, blue: 110 / 255))
                .disabled(!model.canEdit)
            }

            VStack(spacing: 0) {
                ForEach(Array(model.slides.enumerated()), id: \.element.id) { index, slide in
                    HStack(spacing: 12) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 13, weight: .medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .leading)

                        Text("Slide")
                            .font(.system(size: 13))

                        Spacer()

                        HStack(spacing: 8) {
                            Button("-") {
                                model.updateSeconds(id: slide.id, seconds: slide.seconds - 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(!model.canEdit || slide.seconds <= 1)

                            Text("\(slide.seconds)s")
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .frame(minWidth: 36)

                            Button("+") {
                                model.updateSeconds(id: slide.id, seconds: slide.seconds + 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(!model.canEdit || slide.seconds >= 999)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Button {
                            model.removeSlide(slide.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(!model.canEdit || model.slides.count <= 1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if index < model.slides.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
