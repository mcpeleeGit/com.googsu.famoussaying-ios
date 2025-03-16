//
//  ContentView.swift
//  famoussaying
//
//  Created by kakao on 3/15/25.
//

import SwiftUI

struct QuoteResponse: Codable {
    let contents: String
    let name: String
}

struct Quote: Identifiable, Codable {
    let id: UUID
    let text: String
    let author: String
    
    init(id: UUID = UUID(), text: String, author: String) {
        self.id = id
        self.text = text
        self.author = author
    }
    
    var shareText: String {
        return "\(text)\n- \(author)"
    }
}

struct QuoteView: View {
    let quote: Quote
    @State private var showCopiedAlert = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(quote.text)
                    .font(horizontalSizeClass == .regular ? .title : .title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .onTapGesture {
                        UIPasteboard.general.string = quote.shareText
                        showCopiedAlert = true
                    }
                
                HStack(spacing: 12) {
                    ShareLink(item: quote.shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.trailing)
            }
            
            Text("- \(quote.author)")
                .font(horizontalSizeClass == .regular ? .headline : .subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical)
        .alert("복사 완료", isPresented: $showCopiedAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("클립보드에 복사되었습니다.")
        }
    }
}

struct ContentView: View {
    @State private var currentQuote = Quote(text: "명언을 불러오는 중...", author: "")
    @State private var favorites: [Quote] = []
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var showCopiedAlert = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // UserDefaults key
    private let favoritesKey = "SavedFavorites"
    
    // 현재 명언이 즐겨찾기에 있는지 확인하는 함수
    private var isCurrentQuoteFavorite: Bool {
        favorites.contains(where: { $0.text == currentQuote.text })
    }
    
    // 즐겨찾기 저장 함수
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    // 즐겨찾기 불러오기 함수
    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.data(forKey: favoritesKey) {
            if let decodedFavorites = try? JSONDecoder().decode([Quote].self, from: savedFavorites) {
                favorites = decodedFavorites
            }
        }
    }
    
    // 즐겨찾기 삭제 함수
    private func deleteFavorite(_ quote: Quote) {
        if let index = favorites.firstIndex(where: { $0.id == quote.id }) {
            favorites.remove(at: index)
            saveFavorites()
        }
    }
    
    // 즐겨찾기 토글 함수
    private func toggleFavorite() {
        if isCurrentQuoteFavorite {
            if let index = favorites.firstIndex(where: { $0.text == currentQuote.text }) {
                favorites.remove(at: index)
            }
        } else {
            favorites.append(currentQuote)
        }
        saveFavorites()
    }
    
    func fetchNewQuote() {
        guard !isLoading else { return }
        isLoading = true
        
        guard let url = URL(string: "http://test-tam.pe.kr/api/famoussaying") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            isLoading = false
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let quoteResponse = try JSONDecoder().decode(QuoteResponse.self, from: data)
                DispatchQueue.main.async {
                    withAnimation {
                        currentQuote = Quote(text: quoteResponse.contents, author: quoteResponse.name)
                    }
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text(currentQuote.text)
                        .font(horizontalSizeClass == .regular ? .system(size: 40) : .title)
                        .multilineTextAlignment(.center)
                        .padding()
                        .onTapGesture {
                            UIPasteboard.general.string = currentQuote.shareText
                            showCopiedAlert = true
                        }
                    
                    if !currentQuote.author.isEmpty {
                        Text("- \(currentQuote.author)")
                            .font(horizontalSizeClass == .regular ? .title2 : .headline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            fetchNewQuote()
                        }) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(horizontalSizeClass == .regular ? .system(size: 44) : .largeTitle)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(isLoading ? 360 : 0))
                                .animation(isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                        }
                        .disabled(isLoading)
                        
                        ShareLink(item: currentQuote.shareText) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(horizontalSizeClass == .regular ? .system(size: 44) : .largeTitle)
                                .foregroundColor(.green)
                        }
                        
                        Button(action: toggleFavorite) {
                            Image(systemName: isCurrentQuoteFavorite ? "heart.fill" : "heart")
                                .font(horizontalSizeClass == .regular ? .system(size: 44) : .largeTitle)
                                .foregroundColor(isCurrentQuoteFavorite ? .red : .gray)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .navigationTitle("오늘의 명언")
                .navigationBarTitleDisplayMode(.inline)
                .alert("복사 완료", isPresented: $showCopiedAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text("클립보드에 복사되었습니다.")
                }
            }
            .tabItem {
                Image(systemName: "quote.bubble.fill")
                Text("명언")
            }
            .tag(0)
            
            NavigationStack {
                List {
                    ForEach(favorites) { quote in
                        QuoteView(quote: quote) {
                            deleteFavorite(quote)
                        }
                    }
                }
                .navigationTitle("즐겨찾기")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("즐겨찾기")
            }
            .tag(1)
        }
        .onAppear {
            loadFavorites()
            fetchNewQuote()
        }
    }
}

#Preview {
    ContentView()
}
