import SwiftUI

struct SequenceEditor: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel("SLIDES")
                Spacer()
                Button {
                    model.addSlide()
                } label: {
                    Label("추가", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .disabled(!model.canEdit)
                .opacity(model.canEdit ? 1 : 0.45)
            }

            VStack(spacing: 0) {
                ForEach(Array(model.slides.enumerated()), id: \.element.id) { index, slide in
                    slideRow(index: index, slide: slide)

                    if index < model.slides.count - 1 {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                }
            }
            .glassSurface(cornerRadius: 20)
        }
    }

    private func slideRow(index: Int, slide: SlideItem) -> some View {
        HStack(spacing: 12) {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.inkMuted)
                .frame(width: 26, alignment: .leading)

            Text("Slide")
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink)

            Spacer()

            stepper(slide: slide)

            Button {
                model.removeSlide(slide.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkMuted)
            }
            .buttonStyle(.plain)
            .disabled(!model.canEdit || model.slides.count <= 1)
            .opacity(model.canEdit && model.slides.count > 1 ? 1 : 0.35)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    private func stepper(slide: SlideItem) -> some View {
        HStack(spacing: 4) {
            stepButton("minus", enabled: model.canEdit && slide.seconds > 1) {
                model.updateSeconds(id: slide.id, seconds: slide.seconds - 1)
            }

            Text("\(slide.seconds)s")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 38)

            stepButton("plus", enabled: model.canEdit && slide.seconds < 999) {
                model.updateSeconds(id: slide.id, seconds: slide.seconds + 1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassSurface(cornerRadius: 13)
    }

    private func stepButton(
        _ symbol: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(enabled ? Theme.accent : Theme.inkMuted)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }
}
