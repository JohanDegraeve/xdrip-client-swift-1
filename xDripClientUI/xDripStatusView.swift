//
//  xDripStatusView.swift
//  xDripClientUI
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit


struct xDripStatusView<Model>: View where Model: xDripStatusModel {
    
    @ObservedObject var viewModel: Model
    
    @Environment(\.glucoseTintColor) var glucoseTintColor
    @Environment(\.guidanceColors) var guidanceColors
    
    @State var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            overviewSection
            latestReadingSection
            deletionSection
        }
        .insetGroupedListStyle()
        .navigationBarTitle(Text("xDrip4iOS", comment: "Title text for the CGM status view"))
        .navigationBarItems(trailing: dismissButton)
    }
    
    var overviewSection: some View {
        Section() {
            VStack(alignment: .leading) {
                Spacer()
                HStack(alignment: .center) {
                    Image(uiImage: UIImage(named: "xDrip4iOS") ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: ContentMode.fit)
                        .frame(height: 85)
                    DescriptiveText(label: "Click on 'Open App' down below to quickly navigate to xDrip4iOS for any adjustment to settings etc.")
                }
                Spacer()
            }
            Link("Open App", destination: viewModel.cgmManager.appURL!)
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle())
    }
    
    var latestReadingSection: some View {
        Section(header: SectionHeader(label: LocalizedString("Latest Reading", comment: "Section title for latest glucose reading"))) {
            LabeledGlucoseView(
                label: LocalizedString("Glucose", comment: "Title describing glucose reading"),
                glucose: viewModel.latestReading?.quantity,
                preferredUnit: viewModel.preferredUnit,
                unitFormatter: viewModel.unitFormatter
            )
            LabeledDateView(
                label: LocalizedString("Date", comment: "Title describing reading date"),
                date: viewModel.latestReading?.startDate,
                dateFormatter: viewModel.dateFormatter
            )
            LabeledValueView(
                label: LocalizedString("Trend", comment: "Title describing glucose trend"),
                value: viewModel.latestReading?.trendType?.localizedDescription
            )
        }
    }
    
    var deletionSection: some View {
        Section(header: Spacer()) {
            Button(action: {
                showingDeleteConfirmation = true
            }, label: {
                HStack {
                    Spacer()
                    Text("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")
                        .foregroundColor(guidanceColors.critical)
                    Spacer()
                }
            }).actionSheet(isPresented: $showingDeleteConfirmation) {
                deleteConfirmationActionSheet
            }
        }
    }
    
    var deleteConfirmationActionSheet: ActionSheet {
        ActionSheet(title: Text("Are you sure you want to delete this CGM?", comment: "Confirmation message for deleting a CGM"), buttons: [
            .destructive(Text("Delete CGM", comment: "Title text for the button to remove a CGM from Loop")) { viewModel.notifyDeletion() },
            .cancel()
        ])
    }
    
    var dismissButton: some View {
        Button(action: { viewModel.hasCompleted?() }) { Text("Done").bold() }
    }
}

struct LabeledGlucoseView: View {
    
    var label: String
    var glucose: HKQuantity?
    var preferredUnit: HKUnit
    var unitFormatter: QuantityFormatter
        
    private var glucoseString: String? {
        guard let glucose = self.glucose else { return nil }
        return unitFormatter.string(from: glucose, for: preferredUnit)
    }
    
    var body: some View {
        LabeledValueView(label: label, value: glucoseString)
    }
}
