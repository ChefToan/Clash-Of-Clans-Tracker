// SearchPlayersView.swift
import SwiftUI
import AlertToast

struct SearchPlayersView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var tabState: TabState
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#1a1a2e"), Color(hex: "#0f0f1e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Search interface - always show this as the root view
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo
                    ZStack {
                        Circle()
                            .fill(Constants.blue.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Constants.blue)
                    }
                    .scaleEffect(isSearchFieldFocused ? 0.8 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSearchFieldFocused)
                    
                    // Title
                    VStack(spacing: 10) {
                        Text("Search Players")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Enter a player tag to view their stats")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Search box
                    VStack(spacing: 20) {
                        HStack {
                            Text("#")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            TextField("Player Tag", text: $viewModel.searchTag)
                                .textFieldStyle(.plain)
                                .font(.title3)
                                .foregroundColor(.white)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .focused($isSearchFieldFocused)
                                .onSubmit {
                                    if !viewModel.searchTag.isEmpty {
                                        performSearch()
                                    }
                                }
                            
                            if !viewModel.searchTag.isEmpty {
                                Button {
                                    HapticManager.shared.lightImpactFeedback()
                                    viewModel.searchTag = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(isSearchFieldFocused ? Constants.blue : Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
                        
                        Button {
                            performSearch()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text("Search")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.searchTag.isEmpty ? Color.gray : Constants.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .disabled(viewModel.searchTag.isEmpty || viewModel.isLoading)
                        .scaleEffect(viewModel.searchTag.isEmpty ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.searchTag.isEmpty)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .onTapGesture {
                    isSearchFieldFocused = false
                }
            }
            .navigationBarHidden(true)
            // Use navigationDestination with a binding to the player
            .navigationDestination(item: $viewModel.player) { player in
                PlayerDetailView(
                    player: player,
                    viewModel: viewModel,
                    onSaveProfile: {
                        Task {
                            let saved = await viewModel.saveAsProfile()
                            if saved {
                                // Wait a bit to ensure data is fully saved
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                
                                // Clear the current player to go back to search
                                viewModel.clearCurrentSearch()
                                
                                // Then switch to profile tab
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    tabState.switchToProfile()
                                }
                            }
                        }
                    },
                    onNewSearch: {
                        // Just clear the player to go back to search view
                        viewModel.clearCurrentSearch()
                        // Focus the search field when going back
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isSearchFieldFocused = true
                        }
                    }
                )
            }
            .toast(isPresenting: $viewModel.showError) {
                AlertToast(
                    type: .error(Color.red),
                    title: "Error",
                    subTitle: viewModel.errorMessage
                )
            }
            .toast(isPresenting: $viewModel.showSuccess) {
                AlertToast(
                    type: .complete(Color.green),
                    title: "Success",
                    subTitle: "Profile saved successfully!"
                )
            }
            .overlay {
                if viewModel.isLoading && viewModel.player == nil {
                    LoadingView()
                }
            }
        }
    }
    
    private func performSearch() {
        isSearchFieldFocused = false
        HapticManager.shared.mediumImpactFeedback()
        Task {
            await viewModel.searchPlayer()
        }
    }
}
