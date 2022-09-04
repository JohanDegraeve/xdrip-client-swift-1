//
//  xDripStatusView.swift
//  xDripClientUI
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//
// Adapted by Johan Degraeve

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit
import xDripClient
import CoreBluetooth
import MessageUI

/// read timeStampStartOfAutoBasal from UserDefaults and return as string
fileprivate let getTimeStampStartOfAutoBasalDateAsString:() -> String = {
    
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale.current
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short

    if let date = UserDefaults.standard.object(forKey: "keyTimeStampStartOfAutoBasal") as? Date {
        return dateFormatter.string(from: date)
    } else {
        return ""
    }
}

/// not yet used
fileprivate let getTimeStampStartOfAddManualTempBasalAsString:() -> String = {

    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale.current
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short

    if let date = UserDefaults.standard.object(forKey: "keyTimeStampStartAddManualTempBasals") as? Date {
        return dateFormatter.string(from: date)
    } else {
        return ""
    }

}

fileprivate let healthKitStore = HKHealthStore()

/// calculates insulin doses from
fileprivate func calculateTotalInsulin(from: Date, to: Date?, completion: @escaping (Double?) -> ()) {
    
    let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [])
    
    let query = HKSampleQuery(sampleType: HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.insulinDelivery)!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
        
        if error != nil {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
        
        guard let results = results as? [HKQuantitySample] else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        guard !results.isEmpty else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        let total = results.reduce(0.0, { (base, result) -> Double in
            
            let newresult = result.quantity.doubleValue(for: HKUnit.internationalUnit())
            //result.
            print("newresult date = \(result.startDate.description(with:.current)), newresult value = \(newresult.description)")
            
            return base + newresult
                                                        
        })
        
        DispatchQueue.main.async {
            completion(Double(Int(total * 10.0))/10.0)
        }

    }
    
    healthKitStore.execute(query)
    
}

struct xDripStatusView<Model>: View where Model: xDripStatusModel {
    
    @ObservedObject var viewModel: Model
    
    @Environment(\.glucoseTintColor) var glucoseTintColor
    @Environment(\.guidanceColors) var guidanceColors
    
    @State var showingDeleteConfirmation = false
     
    @State private var showEmailNotConfiguredWarning = false
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingMailView = false
    
    @State private var showScreenLockConfirmation = false
    
    @AppStorage(UserDefaults.Key.useCGMAsHeartbeat.rawValue) private var useCGMAsHeartbeat: Bool = false

    @AppStorage(UserDefaults.Key2.keyForAddManualTempBasals.rawValue) private var usetempBasalAsIOB: Bool = false
    
    @AppStorage(UserDefaults.Key2.keyForDurationAddManualTempBasalsInHours.rawValue) private var durationAddManualTempBasalsInHours: Int = UserDefaults.standard.durationAddManualTempBasalsInHours

    @AppStorage(UserDefaults.Key2.keyForUseVariableBasal.rawValue) private var useVariableBasal: Bool = false
    
    @AppStorage(UserDefaults.Key2.keyForPercentageVariableBasal.rawValue) private var percentageVariableBasal: Int = UserDefaults.standard.percentageVariableBasal
    
    @AppStorage(UserDefaults.Key.heartBeatState.rawValue) private var heartBeatState: String = ""
    
    @AppStorage(UserDefaults.Key2.keyAutoBasalRunning.rawValue) private var autoBasalRunning: Bool = false
    
    @AppStorage(UserDefaults.Key2.keyAutoBasalMultiplier.rawValue) private var autoBasalMultiplier: Double = UserDefaults.standard.autoBasalMultiplier
    
    @AppStorage(UserDefaults.Key2.keyForAutoBasalDurationInHours.rawValue) private var autoBasalDurationInHours: Int = UserDefaults.standard.autoBasalDurationInHours

    @AppStorage(UserDefaults.Key.shouldSyncToRemoteService.rawValue) private var shouldSyncToRemoteService: Bool = false

    /// for some reason the TextEditor that shows the heartBeatState doesn't immediately use multiline. By removing and re-adding it, multiline is used. A trick to force multiline, is to set showHeartBeatText to false as soon as the View is shown, and immediately back to true. Then multiline is used
    @State var showHeartBeatText = true
    
    @State var timeStampStartOfAutoBasal = getTimeStampStartOfAutoBasalDateAsString()
    
    @State var timeSTampAddManualTempBasal = getTimeStampStartOfAddManualTempBasalAsString()
    
    @State var timeStampStartCalculateTotalDoses: Date = UserDefaults.standard.timeStampStartCalculateTotalDoses
    
    @State var timeStampEndCalculateTotalDoses: Date = UserDefaults.standard.timeStampEndCalculateTotalDoses
    
    @State var totalDose = 0.0
    
    let percentageformatter: NumberFormatter =  {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    
    var body: some View {
        List {
            overviewSection
            latestReadingSection
            heartBeatSection
            shouldSyncToRemoteServiceSection
            lockScreenSection
            usemanualtempbasalSection
            useVariableBasalSection
            calculateTotalDoseSection
            autoBasalRunningSecion
            deletionSection
        }
        .insetGroupedListStyle()
        .navigationBarTitle(Text("xDrip4iOS", comment: "Title text for the CGM status view"))
        .navigationBarItems(trailing: dismissButton)
    }
    
    var calculateTotalDoseSection: some View {

        Section(header: SectionHeader(label: LocalizedString("Calculate total dose (inclusive scheduled basal)", comment: ""))) {

            VStack(alignment: .leading) {

                Text(NSLocalizedString("Start Date", comment: "Date picker label"))

                DatePicker(
                    "",
                    selection: $timeStampStartCalculateTotalDoses,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .pickerStyle(WheelPickerStyle())
                .onChange(of: timeStampStartCalculateTotalDoses, perform: { value in
                    
                    UserDefaults.standard.timeStampStartCalculateTotalDoses = timeStampStartCalculateTotalDoses
                    
                    calculateTotalInsulin(from: timeStampStartCalculateTotalDoses, to: timeStampEndCalculateTotalDoses, completion: { total in
                        totalDose = total ?? 0.0
                    })
                    
                })
                
            }

            VStack(alignment: .leading) {
                
                Text(NSLocalizedString("End Date", comment: "Date picker label"))

                DatePicker(
                    "",
                    selection: $timeStampEndCalculateTotalDoses,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .pickerStyle(WheelPickerStyle())
                .onChange(of: timeStampEndCalculateTotalDoses, perform: { value in
                    
                    UserDefaults.standard.timeStampEndCalculateTotalDoses = timeStampEndCalculateTotalDoses
                    
                    calculateTotalInsulin(from: timeStampStartCalculateTotalDoses, to: timeStampEndCalculateTotalDoses, completion: { total in
                        totalDose = total ?? 0.0
                    })
                    
                })
                
            }

            LabeledValueView(
                label: LocalizedString("Amount", comment: ""),
                value: totalDose.description
            )
            .onAppear(perform: {
                calculateTotalInsulin(from: timeStampStartCalculateTotalDoses, to: timeStampEndCalculateTotalDoses, completion: { total in
                    totalDose = total ?? 0.0
                })
            })
        }

    }
    
    var lockScreenSection: some View {
        
        VStack(alignment: .leading) {
            Text("Lock Screen", comment: "The title text for the cell to lock the screen")
                .padding(.vertical, 3)
        }
        .onTapGesture {
            // prevent screen dim/lock
            UIApplication.shared.isIdleTimerDisabled = true
            
            UserDefaults.standard.screenLockedByxDrip4iOSClient = true
            
            showScreenLockConfirmation = true
            
        }
        .alert(isPresented: $showScreenLockConfirmation, content: { Alert(title: Text("Screen locked. Bring the app to the background to unlock.", comment: "confirmation that screen is locked")) })

        
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
    
    var heartBeatSection: some View {
        
        Section(header: SectionHeader(label: LocalizedString("Heartbeat", comment: "Section title for heartbeat info"))) {
            
            Toggle(isOn: $useCGMAsHeartbeat) {
                VStack(alignment: .leading) {
                    Text("Use CGM as heartbeat", comment: "The title text for the cgm heartbeat enabled switch cell")
                        .padding(.vertical, 3)
                }
            }
            if useCGMAsHeartbeat && showHeartBeatText {
                VStack(alignment: .leading) {
                    TextEditor(text: $heartBeatState)
                        .multilineTextAlignment(.leading)
                        .disabled(true)
                        .lineLimit(nil)
                        
                }
                    
            }

        }
    }
    
    var shouldSyncToRemoteServiceSection: some View {
        
        Section(header: SectionHeader(label: LocalizedString("Sync", comment: "Section title for sync to remote service section"))) {
            
            Toggle(isOn: $shouldSyncToRemoteService) {
                VStack(alignment: .leading) {
                    Text("Loop should sync to remote service", comment: "The title text for sync to remote service enabled switch cell")
                        .padding(.vertical, 3)
                }
            }

        }
        // for some reason the heartbeat text in heartBeatSection is not completely shown, unless it's refreshed done at the right moment, which is here.
        .onAppear(perform: {
            showHeartBeatText = false;
            showHeartBeatText = true
        })

    }
    
    var sendTraceFileSection: some View {
        Section {
            Button(action: {
                if MFMailComposeViewController.canSendMail() {
                    self.isShowingMailView.toggle()
                } else {
                    print("Can't send emails from this device")
                    showEmailNotConfiguredWarning = true
                }
                if result != nil {
                    print("Result: \(String(describing: result))")
                }
            }) {
                HStack {
                    Image(systemName: "envelope")
                    Text("Send Issue Report", comment: "Title text for the button to send issue report")
                    
                }
            }
        }
        .sheet(isPresented: $isShowingMailView) {
            MailView(result: $result) { composer in
                
                composer.setToRecipients(["xdrip@proximus.be"])
                composer.setMessageBody(NSLocalizedString("Problem Description: ", comment: "default text in email body, when user wants to send trace file."), isHTML: true)

                // add all trace files as attachment
                let traceFilesInData = Trace.getTraceFilesInData()
                for (index, traceFileInData) in traceFilesInData.0.enumerated() {
                    composer.addAttachmentData(traceFileInData as Data, mimeType: "text/txt", fileName: traceFilesInData.1[index])
                }

            }
        }
        .alert(isPresented: $showEmailNotConfiguredWarning, content: { Alert(title: Text("You must  have an email account configured.", comment: "Explain to user that email account must be configured")) })
    }

    var usemanualtempbasalSection: some View {
        
        Section(header: SectionHeader(label: LocalizedString("Use manual temp basal in GlucoseEfect", comment: "Section title"))) {
            
            Toggle(isOn: $usetempBasalAsIOB) {
                VStack(alignment: .leading) {
                    Text("Use manual temp basal", comment: "The title")
                        .padding(.vertical, 3)
                }
            }
            .onChange(of: usetempBasalAsIOB) { value in
                UserDefaults.standard.addManualTempBasals = value
            }

            HStack {
                Picker("Duration (hours)", selection: $durationAddManualTempBasalsInHours) {
                    ForEach(Array(stride(from: 1, to: 6, by: 1)), id: \.self) { index in
                        Text("\(index)")
                    }
                }
                
            }

        }
    }
    
    var autoBasalRunningSecion: some View {
        
        Section(header: SectionHeader(label: LocalizedString("Use auto basal after meal", comment: "Section title"))) {
            
            Toggle(isOn: $autoBasalRunning) {
                VStack(alignment: .leading) {
                    Text("Use auto basal", comment: "The title")
                        .padding(.vertical, 3)
                }
            }
            .onChange(of: autoBasalRunning) { value in
                UserDefaults.standard.autoBasalRunning = value
                timeStampStartOfAutoBasal = getTimeStampStartOfAutoBasalDateAsString()
            }
            
            VStack(alignment: .leading) {
                Text("Last start \(timeStampStartOfAutoBasal)", comment: "The title")
                    .padding(.vertical, 3)
            }

            HStack {
                Picker("Multiplier", selection: $autoBasalMultiplier) {
                    ForEach(Array(stride(from: 0.8, to: 4.0, by: 0.2)), id: \.self) { index in
                        Text("\(String(format: "%.1f", index))")
                    }
                }
                
            }

            HStack {
                Picker("Duration (hours)", selection: $autoBasalDurationInHours) {
                    ForEach(Array(stride(from: 1, to: 6, by: 1)), id: \.self) { index in
                        Text("\(index)")
                    }
                }
                
            }

        }
    }
    
    var useVariableBasalSection: some View {
        
        Section(header: SectionHeader(label: LocalizedString("Use variable basal", comment: "Section title"))) {
            
            if !usetempBasalAsIOB {

                Toggle(isOn: $useVariableBasal) {
                    VStack(alignment: .leading) {
                        Text("Use variable basal", comment: "The title")
                            .padding(.vertical, 3)
                    }
                }
                
                HStack {
                    Picker("Percentage", selection: $percentageVariableBasal) {
                        ForEach(Array(stride(from: 0, to: 101, by: 10)), id: \.self) { index in
                            Text("\(index)")
                        }
                    }
                    
                }

            } else {
                
                LabeledValueView(
                    label: LocalizedString("Use variable basal", comment: "Section title"),
                    value: "Off"
                )
                
            }
            
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
