import SwiftUI
import Brudcast

extension View {
    /// Records a screen view each time the screen appears, the way an app tells Brudcast where the
    /// user is so screen-triggered campaigns can show.
    ///
    /// - Parameters:
    ///   - name: The screen name campaigns match on.
    ///   - properties: Extra detail, such as the product on a product page.
    func trackScreen(_ name: String, properties: BrudcastProperties = [:]) -> some View {
        onAppear { Brudcast.screen(name, properties: properties) }
    }
}

/// A hairline rule between pieces of content.
struct Rule: View {
    var strong = false

    var body: some View {
        Rectangle()
            .fill(strong ? Palette.borderStrong : Palette.border)
            .frame(height: 1)
    }
}

/// A screen's title and description above a strong rule.
struct PageHeader: View {
    let title: String
    var description: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(Typography.pageTitle).tracking(-0.6)
            if let description {
                Text(description).font(Typography.description).foregroundStyle(Palette.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        Rule(strong: true)
    }
}

/// A group of content under a heading, bounded by type and whitespace rather than a box.
struct SectionBlock<Content: View>: View {
    let title: String
    var description: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(Typography.sectionTitle).tracking(-0.4)
            if let description {
                Text(description)
                    .font(Typography.description)
                    .foregroundStyle(Palette.mutedForeground)
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 12) { content }
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
}

/// A filled primary button.
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.button)
            .foregroundStyle(Palette.primaryForeground)
            .padding(.horizontal, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 40)
            .background(Palette.primary, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// A hairline-bordered button on the card surface.
struct OutlineButtonStyle: ButtonStyle {
    var fullWidth = false
    var destructive = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.button)
            .foregroundStyle(destructive ? Palette.destructiveForeground : Palette.foreground)
            .padding(.horizontal, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 40)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.button, style: .continuous).stroke(Palette.border))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// A text field with its label above it. Focus settles on a neutral border rather than a brand ring.
struct Field: View {
    let label: String
    @Binding var text: String
    var placeholder = ""
    var keyboard: UIKeyboardType = .default
    var identifier: String?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(Typography.label).foregroundStyle(Palette.mutedForeground)
            TextField(placeholder, text: $text)
                .font(Typography.body)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.input, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                        .stroke(focused ? Palette.inputActive : Palette.border)
                )
                .accessibilityIdentifier(identifier ?? label)
        }
    }
}

/// A row of large numerals sitting on a rule, for counts.
struct MetricLedger: View {
    let metrics: [(label: String, value: Int)]

    var body: some View {
        VStack(spacing: 0) {
            Rule(strong: true)
            HStack(alignment: .top) {
                ForEach(metrics, id: \.label) { metric in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.label).font(Typography.label).foregroundStyle(Palette.mutedForeground)
                        Text("\(metric.value)").font(Typography.metric).tracking(-0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            Rule()
        }
    }
}

/// A brand-tinted icon chip.
struct IconChip: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Palette.brand)
            .frame(width: 36, height: 36)
            .background(Palette.brandSubtle, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
    }
}

/// A tinted notice: a success, warning or error the reader should see without an alert.
struct Notice: View {
    let text: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(Typography.description)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.input, style: .continuous))
    }
}

/// A label and value on one line, for read-only details.
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label).foregroundStyle(Palette.mutedForeground)
            Spacer(minLength: 0)
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(Typography.description)
    }
}
