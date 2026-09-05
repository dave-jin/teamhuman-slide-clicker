import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    private let accent = Color(red: 15 / 255, green: 118 / 255, blue: 110 / 255)
    private let bg = Color(red: 238 / 255, green: 240 / 255, blue: 243 / 255)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !AccessibilityService.isTrusted {
                        permissionBanner
                    }
                    summaryCard
                    presetRow
                    keyRow
                    SequenceEditor(model: model)
                    profileRow
                }
                .padding(20)
                .padding(.bottom, 8)
            }

            stickyStartBar
        }
        .frame(minWidth: 420, idealWidth: 440, minHeight: 560)
        .background(bg)
        .alert("권한이 필요합니다", isPresented: $model.showAccessibilityAlert) {
            Button("개인정보 보호 설정 열기") {
                AccessibilityService.openSystemSettings()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("""
            시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용
            목록에서 Auto Clicker를 켠 뒤 앱을 재실행하세요.
            """)
        }
    }

    private var stickyStartBar: some View {
        VStack(spacing: 8) {
            Divider()
            Text("시작 후 우하단에 Play가 뜹니다. 직접 눌러 카운트다운을 시작하세요.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                model.start()
            } label: {
                Text("시작")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .controlSize(.large)
            .disabled(model.sequencer.isSessionOpen)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(
            bg.shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
        )
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("키 입력을 보내려면 권한이 필요합니다")
                .font(.system(size: 13, weight: .semibold))
            Text("시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용\n(왼쪽 ‘손쉬운 사용’ 메뉴가 아니라, 자물쇠/손 아이콘 쪽입니다)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("개인정보 보호 설정 열기") {
                AccessibilityService.openSystemSettings()
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    private var summaryCard: some View {
        VStack(spacing: 4) {
            Text("TOTAL TIME")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(TimeFormat.total(model.totalSeconds))
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .tracking(-1)
            Text("\(model.slides.count) slides  ·  \(model.advanceKey.title)")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRESET")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(TimingPreset.allCases) { preset in
                    let active = model.selectedPreset == preset
                    Button(preset.title) {
                        model.applyPreset(preset)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(active ? accent : Color(nsColor: .controlBackgroundColor))
                    .foregroundStyle(active ? Color.white : Color.primary)
                    .clipShape(Capsule())
                    .disabled(!model.canEdit)
                }
            }
        }
    }

    private var keyRow: some View {
        HStack {
            Text("Advance key")
                .foregroundStyle(.secondary)
            Spacer()
            Picker("", selection: Binding(
                get: { model.advanceKey },
                set: { model.setAdvanceKey($0) }
            )) {
                ForEach(AdvanceKey.allCases) { key in
                    Text(key.title).tag(key)
                }
            }
            .labelsHidden()
            .frame(width: 140)
            .disabled(!model.canEdit)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var profileRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PROFILES")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(model.showProfiles ? "Hide" : "Show") {
                    model.showProfiles.toggle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(accent)
            }

            if model.showProfiles {
                HStack(spacing: 8) {
                    TextField("프로필 이름", text: $model.profileNameDraft)
                        .textFieldStyle(.roundedBorder)
                    Button("저장") {
                        model.saveProfile()
                    }
                    .disabled(model.profileNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if model.profiles.isEmpty {
                    Text("저장된 프로필이 없습니다.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.profiles) { profile in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text("\(profile.seconds.count) slides · \(profile.advanceKey.title)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("불러오기") {
                                model.loadProfile(profile)
                            }
                            .disabled(!model.canEdit)
                            Button {
                                model.deleteProfile(profile)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }
}
