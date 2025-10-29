//
//  ClassificationView.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import PhotosUI
import SwiftUI

struct ClassificationView: View {
    @StateObject private var viewModel: ClassificationViewModel
    @State private var isCameraPresented = false
    @State private var selectedItem: PhotosPickerItem?

    init(viewModel: ClassificationViewModel) {
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

            VStack(spacing: 28) {
                imagePreview
                predictionCard
                pickerActions

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
        .sheet(isPresented: $isCameraPresented) {
            CameraView(
                selectedImage: viewModel.binding(\.selectedImage),
                onCapture: { image in
                    viewModel.handleCapturedImage(image)
                }
            )
        }
    }

    private var imagePreview: some View {
        Group {
            if let image = viewModel.state.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .white.opacity(0.15), radius: 12, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if viewModel.state.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding()
                                .background(.thinMaterial, in: Circle())
                                .shadow(radius: 10)
                                .padding()
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .frame(height: 260)
                    .overlay(Text("No image selected").foregroundColor(.secondary))
                    .shadow(color: .white.opacity(0.1), radius: 8)
            }
        }
    }

    private var predictionCard: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(spacing: 8) {
                Text("Prediction")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Text(viewModel.state.prediction)
                    .font(.title3.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut, value: viewModel.state.prediction)

                if viewModel.state.confidence > 0 {
                    Text("\(Int(viewModel.state.confidence * 100))% confidence")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }

            Divider().opacity(0.4)

            VStack(spacing: 10) {
                Text("Prediction Sentiment")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                if viewModel.state.sentiment.isAnalyzing {
                    ProgressView()
                        .tint(.secondary)
                } else if let sentimentError = viewModel.state.sentiment.errorMessage {
                    Text(sentimentError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                } else if viewModel.state.sentiment.label.isEmpty == false {
                    Text("\(viewModel.state.sentiment.label) (Score: \(String(format: "%.2f", viewModel.state.sentiment.score)))")
                        .font(.callout)
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .purple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sentiment will appear after classification.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: .white.opacity(0.2), radius: 20, y: 8)
    }

    private var pickerActions: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing),
                                    lineWidth: 1)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 10, y: 4)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await viewModel.processPickedItem(newItem) }
            }

            Button {
                isCameraPresented = true
            } label: {
                Label("Capture Photo", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing),
                                    lineWidth: 1)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
    }
}
