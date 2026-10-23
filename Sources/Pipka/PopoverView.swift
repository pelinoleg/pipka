import ServiceManagement
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: ColorStore
    var onPick: () -> Void

    @State private var copied: ColorFormat?
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 10) {
            swatch
            if let color = store.color {
                VStack(spacing: 2) {
                    ForEach(ColorFormat.allCases) { format in
                        FormatRow(
                            format: format,
                            value: color.string(format),
                            isDefault: format == store.format,
                            isCopied: format == copied
                        ) {
                            store.copy(color, as: format)
                            store.format = format
                            flashCopied(format)
                        }
                    }
                }
            }
            Divider().padding(.horizontal, 4)
            footer
        }
        .padding(12)
        .frame(width: 320)
    }

    private var swatch: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(store.color.map { AnyShapeStyle($0.color) } ?? AnyShapeStyle(placeholder))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                )

            let light = store.color?.isLight ?? false
            Text(store.color?.hex ?? "Pick a color")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(light ? Color.black.opacity(0.8) : .white)
                .padding(14)

            Button(action: onPick) {
                Image(systemName: "eyedropper")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(light ? Color.black.opacity(0.75) : .white)
                    .frame(width: 30, height: 30)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Pick a color (⇧⌘C)")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(10)
        }
        .frame(height: 96)
    }

    private var placeholder: LinearGradient {
        LinearGradient(colors: [Color(red: 1, green: 0.37, blue: 0.55), Color(red: 0.49, green: 0.3, blue: 1),
                                Color(red: 0.2, green: 0.6, blue: 1)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(.system(size: 11))
                .onChange(of: launchAtLogin) { on in
                    try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                }
            Spacer()
            Text("⇧⌘C")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.secondary)
                .help("Global shortcut to pick a color")
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power").font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Quit Pipka")
        }
        .padding(.horizontal, 4)
    }

    private func flashCopied(_ format: ColorFormat) {
        withAnimation(.easeOut(duration: 0.15)) { copied = format }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copied == format { withAnimation(.easeOut(duration: 0.25)) { copied = nil } }
        }
    }
}

private struct FormatRow: View {
    let format: ColorFormat
    let value: String
    let isDefault: Bool
    let isCopied: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Text(format.title)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(isDefault ? Color.accentColor : .secondary)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .minimumScaleFactor(0.85)
                .lineLimit(1)
                .textSelection(.disabled)
            Spacer(minLength: 4)
            trailing.frame(width: 16)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.08 : isDefault ? 0.045 : 0))
        )
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }
        .onTapGesture(perform: action)
        .help(isDefault ? "Default format — click to copy" : "Click to copy and make default")
    }

    @ViewBuilder private var trailing: some View {
        if isCopied {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.green)
                .transition(.scale.combined(with: .opacity))
        } else if hovering {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else if isDefault {
            Circle().fill(Color.accentColor).frame(width: 6, height: 6)
        }
    }
}
