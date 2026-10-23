import ServiceManagement
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: ColorStore
    var onPick: () -> Void

    @State private var copied: ColorFormat?
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 12) {
            hero
            if let color = store.color {
                formats(color)
            }
            footer
        }
        .padding(12)
        .frame(width: 320)
    }

    // MARK: Hero swatch

    private var hero: some View {
        let light = store.color?.isLight ?? false
        let ink: Color = light ? .black.opacity(0.82) : .white

        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(store.color.map { AnyShapeStyle($0.color) } ?? AnyShapeStyle(placeholder))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                if let color = store.color {
                    Text(color.hex)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                    if store.format != .hex {
                        Text(color.string(store.format))
                            .font(.system(size: 11, design: .monospaced))
                            .opacity(0.75)
                            .lineLimit(1)
                    }
                } else {
                    Text("Pick a color")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Text("Click the drop in the menu bar or press ⇧⌘C")
                        .font(.system(size: 11))
                        .opacity(0.8)
                }
            }
            .foregroundStyle(ink)
            .padding(14)

            Button(action: onPick) {
                Image(systemName: "eyedropper")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ink)
                    .frame(width: 30, height: 30)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(ink.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Pick a color (⇧⌘C)")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(10)
        }
        .frame(height: 112)
    }

    private var placeholder: LinearGradient {
        LinearGradient(colors: [Color(red: 1, green: 0.42, blue: 0.53), Color(red: 0.72, green: 0.3, blue: 1),
                                Color(red: 0.24, green: 0.48, blue: 1)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Formats

    private func formats(_ color: RGBColor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 0) {
                ForEach(Array(ColorFormat.allCases.enumerated()), id: \.element) { index, format in
                    if index > 0 {
                        Divider().opacity(0.5).padding(.leading, 68)
                    }
                    FormatRow(
                        format: format,
                        value: color.string(format),
                        isDefault: format == store.format,
                        isCopied: format == copied
                    ) {
                        store.copy(color, as: format)
                        withAnimation(.easeOut(duration: 0.2)) { store.format = format }
                        flashCopied(format)
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            )

            Text("Click to copy · ✓ is the format new picks use")
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(.system(size: 11))
                .onChange(of: launchAtLogin) { on in
                    try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                }
            Spacer()
            Text("⇧⌘C")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.primary.opacity(0.07)))
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
                .font(.system(size: 10.5, weight: isDefault ? .bold : .semibold))
                .foregroundStyle(isDefault ? .primary : .secondary)
                .frame(width: 48, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: isDefault ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 4)
            trailing
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.08 : 0))
        )
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }
        .onTapGesture(perform: action)
    }

    @ViewBuilder private var trailing: some View {
        if isCopied {
            Label("Copied", systemImage: "checkmark")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.green)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
        } else if isDefault {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.primary)
        } else if hovering {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}
