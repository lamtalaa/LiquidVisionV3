//
//  AudioAnalyzerView.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AudioAnalyzerView: View {
    @StateObject private var viewModel: AudioAnalyzerViewModel
    @State private var isFileImporterPresented = false
    @State private var alertItem: AlertItem?

    init(viewModel: AudioAnalyzerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .blur(radius: 60)
            .overlay(.ultraThinMaterial)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    statusCard
                    actionButtons
                    transcriptionCard
                    classificationCard

                    if let error = viewModel.state.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
                .padding(30)
            }
            .scrollIndicators(.hidden)
        }
        .alert(item: $alertItem) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.mpeg4Audio, .audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                handleImportedFile(url)
            case .failure(let error):
                alertItem = AlertItem(title: "File Import", message: error.localizedDescription)
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Audio Source")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                switch viewModel.state.activeSource {
                case .file(let name):
                    badge(text: name, systemImage: "doc.fill")
                case .live:
                    badge(text: viewModel.state.isRecordingLive ? "Live" : "Mic", systemImage: "waveform")
                case .none:
                    badge(text: "Idle", systemImage: "pause.circle")
                }
            }

            if let info = viewModel.state.infoMessage {
                Text(info)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Import an audio file or start a live session to begin analysis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if viewModel.state.isAnalyzingFile || viewModel.state.isRecordingLive {
                ProgressView()
                    .tint(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .white.opacity(0.18), radius: 18, y: 6)
    }

    private var classificationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Top Predictions")
                .font(.headline)
                .foregroundStyle(.secondary)

            if viewModel.state.classifications.isEmpty {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(height: 120)
                    .overlay(
                        Text("No predictions yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    )
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.state.classifications, id: \.identifier) { result in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(result.identifier.capitalized)
                                    .font(.headline)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.cyan, .purple],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                Spacer()
                                Text(confidenceText(for: result.confidence))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.05)],
                                                      startPoint: .topLeading,
                                                      endPoint: .bottomTrailing))
                                .frame(height: 8)
                                .overlay(
                                    GeometryReader { proxy in
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [.cyan, .purple],
                                                                 startPoint: .leading,
                                                                 endPoint: .trailing))
                                            .frame(width: proxy.size.width * CGFloat(max(0, min(1, result.confidence))))
                                    }
                                )
                                .frame(height: 8)
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .white.opacity(0.18), radius: 18, y: 6)
    }

    private var transcriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Transcription")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.state.transcription.isEmpty == false {
                    badge(text: "On Device", systemImage: "brain.head.profile")
                }
            }

            if viewModel.state.transcription.isEmpty {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(height: 140)
                    .overlay(
                        Text("Transcripts will appear here once analysis begins.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                            .multilineTextAlignment(.center)
                    )
            } else {
                Text(viewModel.state.transcription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .white.opacity(0.18), radius: 18, y: 6)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button {
                isFileImporterPresented = true
            } label: {
                Label("Analyze Audio File", systemImage: "doc.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(buttonStroke)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.state.isAnalyzingFile)
            .opacity(viewModel.state.isAnalyzingFile ? 0.7 : 1)

            Button {
                viewModel.toggleLiveAnalysis()
            } label: {
                Label(
                    viewModel.state.isRecordingLive ? "Stop Live Analysis" : "Start Live Analysis",
                    systemImage: viewModel.state.isRecordingLive ? "stop.circle" : "waveform"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(liveButtonBackground(isRecording: viewModel.state.isRecordingLive))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(liveButtonStroke(isRecording: viewModel.state.isRecordingLive))
            }
            .buttonStyle(.plain)
        }
    }

    private var buttonBackground: some View {
        LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .background(.thinMaterial)
    }

    private var buttonStroke: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(
                LinearGradient(colors: [.white.opacity(0.4), .clear],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                lineWidth: 1
            )
    }

    private func liveButtonBackground(isRecording: Bool) -> some View {
        let colors: [Color] = isRecording
            ? [Color(red: 0.95, green: 0.2, blue: 0.2), Color(red: 0.75, green: 0.05, blue: 0.15)]
            : [Color(red: 0.1, green: 0.75, blue: 0.3), Color(red: 0.05, green: 0.55, blue: 0.2)]

        return LinearGradient(colors: colors,
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            .background(.thinMaterial)
    }

    private func liveButtonStroke(isRecording: Bool) -> some View {
        let strokeColor = isRecording
            ? Color(red: 0.95, green: 0.2, blue: 0.2)
            : Color(red: 0.1, green: 0.75, blue: 0.3)
        return RoundedRectangle(cornerRadius: 18)
            .stroke(
                LinearGradient(colors: [strokeColor, .clear],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                lineWidth: 1
            )
    }

    private func confidenceText(for value: Double) -> String {
        let percentage = max(0, min(1, value)) * 100
        return String(format: "%.1f%% confidence", percentage)
    }

    private func handleImportedFile(_ url: URL) {
        do {
            let accessibleURL = try prepareFileURL(url)
            Task { await viewModel.analyzeFile(at: accessibleURL) }
        } catch {
            alertItem = AlertItem(title: "File Import", message: error.localizedDescription)
        }
    }

    private func prepareFileURL(_ url: URL) throws -> URL {
        let fileManager = FileManager.default
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            return try copyToTemporaryDirectory(url: url, fileManager: fileManager)
        } else if url.isFileURL {
            return try copyToTemporaryDirectory(url: url, fileManager: fileManager)
        }
        throw AudioFileAnalysisError.invalidFile
    }

    private func copyToTemporaryDirectory(url: URL, fileManager: FileManager) throws -> URL {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
        try fileManager.removeItemIfNeeded(at: tempURL)
        try fileManager.copyItem(at: url, to: tempURL)
        return tempURL
    }

    private func badge(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

private extension FileManager {
    func removeItemIfNeeded(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
    }
}

private struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
