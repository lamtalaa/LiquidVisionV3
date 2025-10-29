//
//  SentimentView.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import SwiftUI

struct SentimentView: View {
    @StateObject private var viewModel: SentimentViewModel

    init(viewModel: SentimentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.mint.opacity(0.3), .teal.opacity(0.3)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .blur(radius: 60)
                .overlay(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Enter Text")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)

                    ZStack(alignment: .topLeading) {
                        if viewModel.state.inputText.isEmpty {
                            Text("Share how you feel about something...")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 20)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        TextEditor(text: viewModel.binding(\.inputText))
                            .frame(height: 180)
                            .padding(12)
                            .background(Color.clear)
                            .multilineTextAlignment(.center)
                    }
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .white.opacity(0.1), radius: 8, y: 4)
                }

                VStack(spacing: 8) {
                    Text("Sentiment")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Text(viewModel.state.sentimentLabel)
                        .font(.title3.bold())
                        .foregroundStyle(
                            LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if viewModel.hasResult {
                        Text(String(format: "Score: %.2f", viewModel.state.sentimentScore))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .white.opacity(0.2), radius: 20, y: 8)

                Button {
                    viewModel.analyze()
                } label: {
                    if viewModel.state.isAnalyzing {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Label("Analyze Sentiment", systemImage: "text.bubble")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .disabled(viewModel.state.isAnalyzing)
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

                if let error = viewModel.state.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(30)
        }
    }
}
