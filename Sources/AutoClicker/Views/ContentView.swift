import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    private var lang: AppLanguage { model.language }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if !AccessibilityService.isTrusted {
                        permissionBanner
                    }
                    summaryCard
                    presetSection
                    keySection
                    SequenceEditor(model: model)
                    profileSection
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)

            stickyStartBar
        }
        .frame(minWidth: 420, idealWidth: 440, minHeight: 560)
        .background {
            ZStack {
                VisualEffectBackground()
                Theme.canvas.opacity(0.72)
                WindowConfigurator()
            }
            .ignoresSafeArea()
        }
        .alert(
            lang.pick("권한이 필요합니다", "Accessibility permission required"),
            isPresented: $model.showAccessibilityAlert
        ) {
            Button(lang.pick("개인정보 보호 설정 열기", "Open Privacy Settings")) {
                AccessibilityService.openSystemSettings()
            }
            Button(lang.pick("취소", "Cancel"), role: .cancel) {}
        } message: {
            Text(lang.pick(
                """
                시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용
                목록에서 Auto Clicker를 켠 뒤 앱을 재실행하세요.
                """,
                """
                System Settings → Privacy & Security → Accessibility
                Turn on Auto Clicker in the list, then relaunch the app.
                """
            ))
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: 6) {
            SectionLabel("TOTAL TIME")
            Text(TimeFormat.total(model.totalSeconds))
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .tracking(-1)
                .foregroundStyle(Theme.ink)
            Text(summaryLine(slides: model.slides.count, key: model.advanceKey))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .glassSurface(cornerRadius: 22)
    }

    private func summaryLine(slides: Int, key: AdvanceKey) -> String {
        lang.pick("슬라이드 \(slides)장  ·  \(key.title)", "\(slides) slides  ·  \(key.title)")
    }

    // MARK: - Preset / advance key

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("PRESET")
            HStack(spacing: 8) {
                ForEach(TimingPreset.allCases) { preset in
                    GlassChip(
                        title: preset.title,
                        isSelected: model.selectedPreset == preset,
                        isEnabled: model.canEdit
                    ) {
                        model.applyPreset(preset)
                    }
                }
            }
        }
    }

    private var keySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("ADVANCE KEY")
            HStack(spacing: 8) {
                ForEach(AdvanceKey.allCases) { key in
                    GlassChip(
                        title: key.title,
                        isSelected: model.advanceKey == key,
                        isEnabled: model.canEdit
                    ) {
                        model.setAdvanceKey(key)
                    }
                }
            }
        }
    }

    // MARK: - Profiles

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel("PROFILES")
                Spacer()
                Button(model.showProfiles
                    ? lang.pick("접기", "Hide")
                    : lang.pick("펼치기", "Show")) {
                    model.showProfiles.toggle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
            }

            if model.showProfiles {
                HStack(spacing: 8) {
                    TextField(
                        lang.pick("프로필 이름", "Profile name"),
                        text: $model.profileNameDraft
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassSurface(cornerRadius: 14)

                    QuietButton(
                        title: lang.pick("저장", "Save"),
                        isEnabled: !model.profileNameDraft
                            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        model.saveProfile()
                    }
                }

                if model.profiles.isEmpty {
                    Text(lang.pick("저장된 프로필이 없습니다.", "No saved profiles yet."))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkMuted)
                } else {
                    ForEach(model.profiles) { profile in
                        profileRow(profile)
                    }
                }
            }
        }
    }

    private func profileRow(_ profile: TimingProfile) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(summaryLine(slides: profile.seconds.count, key: profile.advanceKey))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkMuted)
            }
            Spacer()
            QuietButton(title: lang.pick("불러오기", "Load"), isEnabled: model.canEdit) {
                model.loadProfile(profile)
            }
            Button {
                model.deleteProfile(profile)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .glassSurface(cornerRadius: 16)
    }

    // MARK: - Permission banner

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.accent)
                Text(lang.pick(
                    "키 입력을 보내려면 권한이 필요합니다",
                    "Auto Clicker needs permission to send keystrokes"
                ))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.ink)
            }
            Text(lang.pick(
                "시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용\n(왼쪽 ‘손쉬운 사용’ 메뉴가 아니라, 자물쇠·손 아이콘 쪽입니다)",
                "System Settings → Privacy & Security → Accessibility\n(not the Accessibility pane in the sidebar — the one behind the lock icon)"
            ))
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
            QuietButton(title: lang.pick("개인정보 보호 설정 열기", "Open Privacy Settings")) {
                AccessibilityService.openSystemSettings()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassSurface(cornerRadius: 20)
        .overlay(alignment: .leading) {
            // A quiet accent rail: enough to flag the card without shouting
            // over the 시작 button, which is the only accent-filled control.
            Capsule()
                .fill(Theme.accent)
                .frame(width: 3)
                .padding(.vertical, 14)
                .padding(.leading, 1)
        }
    }

    // MARK: - Start bar

    private var stickyStartBar: some View {
        VStack(spacing: 10) {
            Text(lang.pick(
                "시작하면 HUD가 뜹니다. 발표 앱을 앞으로 가져온 뒤 Play를 누르세요.",
                "Starting shows the HUD. Bring your slides to the front, then press Play."
            ))
            .font(.system(size: 11))
            .foregroundStyle(Theme.inkMuted)
            .frame(maxWidth: .infinity, alignment: .leading)

            AccentButton(
                title: lang.pick("시작", "Start"),
                isEnabled: !model.sequencer.isSessionOpen,
                fillsWidth: true
            ) {
                model.start()
            }

            footerRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background {
            Rectangle()
                .fill(Theme.canvas.opacity(0.55))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                }
                .ignoresSafeArea()
        }
    }

    private var footerRow: some View {
        HStack(spacing: 10) {
            teamHumanCredit
            Spacer(minLength: 8)
            languagePicker
        }
    }

    private var teamHumanCredit: some View {
        Link(destination: URL(string: "https://withteamhuman.com")!) {
            HStack(spacing: 4) {
                Text(lang.pick("만든 팀", "Made by"))
                    .foregroundStyle(Theme.inkMuted)
                Text("Team Human")
                    .foregroundStyle(Theme.accent)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .font(.system(size: 11, weight: .medium))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("withteamhuman.com")
    }

    private var languagePicker: some View {
        HStack(spacing: 4) {
            ForEach(AppLanguage.allCases) { option in
                let isSelected = model.language == option
                Button(option.title) {
                    model.setLanguage(option)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.onAccent : Theme.ink)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .glassSurface(
                    cornerRadius: 11,
                    tint: isSelected ? Theme.accent : nil,
                    interactive: true
                )
            }
        }
    }
}
