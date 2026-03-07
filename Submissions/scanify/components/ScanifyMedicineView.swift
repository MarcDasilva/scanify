import SwiftUI

struct ScanifyMedicineView: View {
    let product: ScannedProduct
    let data: PharmacyData
    var accentColor: Color = .red

    @State private var medicationInput: String = ""
    @State private var interactionResult: InteractionResult?
    @State private var showDosageInfo = false

    enum InteractionResult {
        case safe(String)
        case warning(DrugInteraction)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product header
                VStack(spacing: 6) {
                    Text(product.brand)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text(String(format: "$%.2f", product.price))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 8)

                // What it treats
                treatsSection

                // What it does NOT treat
                doesNotTreatSection

                // Active ingredients
                ingredientsSection

                // Interaction checker
                interactionSection

                // Generic equivalent
                if let generic = data.genericEquivalent {
                    genericSection(generic)
                }

                // Age restriction
                if let age = data.ageRestriction {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill.questionmark")
                            .foregroundStyle(.orange)
                        Text(age)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Medicine Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Treats

    private var treatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("What This Treats")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            FlowLayout(spacing: 8) {
                ForEach(data.treats, id: \.self) { symptom in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                        Text(symptom)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.green.opacity(0.1), in: .capsule)
                    .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Does NOT treat

    private var doesNotTreatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                Text("Does NOT Treat")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            FlowLayout(spacing: 8) {
                ForEach(data.doesNotTreat, id: \.self) { symptom in
                    Text(symptom)
                        .font(.system(size: 12, weight: .medium))
                        .strikethrough()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { showDosageInfo.toggle() }
            } label: {
                HStack {
                    Text("Active Ingredients & Dosage")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showDosageInfo ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if showDosageInfo {
                VStack(spacing: 6) {
                    ForEach(data.activeIngredients, id: \.name) { ingredient in
                        HStack {
                            Text(ingredient.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(ingredient.dose)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.blue)
                        }
                        .padding(10)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(data.dosage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Interaction Checker

    private var interactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "pills.fill")
                    .foregroundStyle(.blue)
                Text("Interaction Checker")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 8) {
                TextField("Enter a medication name...", text: $medicationInput)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onSubmit { checkInteraction() }

                Button(action: checkInteraction) {
                    Text("Check")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.blue, in: .capsule)
                }
                .disabled(medicationInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))

            // Quick suggestion pills
            HStack(spacing: 6) {
                Text("Try:")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                ForEach(["Lisinopril", "Vitamin D", "Warfarin"], id: \.self) { med in
                    Button {
                        medicationInput = med
                        checkInteraction()
                    } label: {
                        Text(med)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
            }

            // Result
            if let result = interactionResult {
                interactionResultView(result)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func checkInteraction() {
        let input = medicationInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !input.isEmpty else { return }

        withAnimation(.spring(duration: 0.3)) {
            if let interaction = data.interactions.first(where: { $0.drugName.lowercased() == input }) {
                interactionResult = .warning(interaction)
            } else {
                interactionResult = .safe(medicationInput)
            }
        }
    }

    @ViewBuilder
    private func interactionResultView(_ result: InteractionResult) -> some View {
        switch result {
        case .safe(let drugName):
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Interactions Found")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                    Text("Safe to take with \(drugName).")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.25), lineWidth: 1))

        case .warning(let interaction):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(interaction.severity.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(interaction.severity.rawValue.uppercased()) INTERACTION")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(interaction.severity.color)
                        Text("with \(interaction.drugName)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }

                Text(interaction.reason)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(interaction.severity.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(interaction.severity.color.opacity(0.25), lineWidth: 1))
        }
    }

    // MARK: - Generic Equivalent

    private func genericSection(_ generic: GenericEquivalent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.green)
                Text("Save Money")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(generic.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("Same active ingredients")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(String(format: "$%.2f", generic.price))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.green)
                        Text(String(format: "(save $%.2f)", generic.savings))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
                Text(generic.aisle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
            .padding(14)
            .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 1))
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
