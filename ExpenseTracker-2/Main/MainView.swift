//
//  MainView.swift
//  ExpenseTracker-2
//
//  Created by Şahin Karahan on 10.01.2025.
//

import SwiftUI

struct MainView: View {
    
    @State private var shouldPresentAddCardForm = false
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.timestamp, ascending: false)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var selectedCardHash = -1
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                if !cards.isEmpty {
                    TabView(selection: $selectedCardHash) {
                        ForEach(cards) { card in
                            CreditCardView(card: card)
                                .padding(.bottom, 50)
                                .tag(card.hash)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 280)
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    .onAppear {
                        self.selectedCardHash = cards.first?.hash ?? -1
                    }
                    
                    if let firstIndex = cards.firstIndex(where: {$0.hash == selectedCardHash}) {
                        let card = self.cards[firstIndex]
                        TransactionsListView(card: card)
                    }
                    
                    
                } else {
                    emptyPromptMessage
                }
                
                Spacer()
                    .fullScreenCover(isPresented: $shouldPresentAddCardForm, onDismiss: nil) {
                        AddCardForm(card: nil) { card in
                            self.selectedCardHash = card.hash
                        }
                    }
            }
            .navigationTitle("Credit Cards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    addCardButton
                }
            }
        }
    }
    
    var addItemButton: some View {
        Button {
            withAnimation {
                let viewContext = PersistenceController.shared.container.viewContext
                let card = Card(context: viewContext)
                card.timestamp = Date()

                do {
                    try viewContext.save()
                } catch {
                    // error
                }
            }
        } label: {
            Text("Add Item")
        }
    }
    
    private var emptyPromptMessage: some View {
        VStack {
            Text("You currently have no cards in the system.")
                .padding(.horizontal, 48)
                .padding(.vertical)
                .multilineTextAlignment(.center)
            
            Button {
                shouldPresentAddCardForm.toggle()
            } label: {
                Text("+ Add Your First Card")
                    .foregroundColor(Color(.systemBackground))
            }
            .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
            .background(Color(.label))
            .cornerRadius(5)

        }.font(.system(size: 22, weight: .semibold))
    }
    
    
    struct CreditCardView: View {
        
        let card: Card
        
        init(card: Card) {
            self.card = card
            
            // lets kinda look at all the transactions for our card
            
            fetchRequest = FetchRequest<CardTransaction>(entity: CardTransaction.entity(), sortDescriptors: [
                .init(key: "timestamp", ascending: false)
            ], predicate: .init(format: "card == %@", self.card))
            
            
        }
        
        @Environment(\.managedObjectContext) private var viewContext
        
        var fetchRequest: FetchRequest<CardTransaction>
        
        @State private var shouldShowActionSheet = false
        @State private var shouldShowEditForm = false
        
        @State private var refreshId = UUID()
        
        private func handleDelete() {
            let viewContext = PersistenceController.shared.container.viewContext
            
            viewContext.delete(card)
            
            do {
                try viewContext.save()
            } catch {
                // error handling
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    
                    Text(card.name ?? "")
                        .font(.system(size: 24, weight: .semibold))
                    Spacer()
                    Button {
                        shouldShowActionSheet.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 28, weight: .bold))
                    }
                    
                    .actionSheet(isPresented: $shouldShowActionSheet) {
                        
                            .init(title: Text(self.card.name ?? ""), message: Text("Options"), buttons: [
                                .default(Text("Edit"), action: {
                                shouldShowEditForm.toggle()
                            }),
                                .destructive(Text("Delete Card"), action: handleDelete),
                                .cancel()
                            ])
                    }
                }
                HStack {
                    let imageName = card.type?.lowercased() ?? ""
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                        .clipped()
                    Spacer()
                    
                    let balance = fetchRequest.wrappedValue.reduce(0, { $0 + $1.amount })

                    Text("Balance: $\(String(format: "%.2f", balance))")
                        .font(.system(size: 18, weight: .semibold))

                }
                
                
                Text(card.number ?? "")
                
                HStack {
                    let balance = fetchRequest.wrappedValue.reduce(0, {$0 + $1.amount })
                    
                    Text("Credit Limit: $\(card.limit - Int32(balance))")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Valid Thru")
                        Text("\(String(format: "%02d", card.expMonth))/\(String(card.expYear % 2000))")
                    }
                }


                
            }
            .foregroundStyle(.white)
            .padding()
            .background(VStack {
                if let colorData = card.color,
                   let uiColor = UIColor.color(data: colorData) {
                    LinearGradient(colors: [
                        Color(uiColor).opacity(0.6),
                        Color(uiColor)
                    ], startPoint: .center, endPoint: .bottom)
                } else {
                    Color.purple
                }
            })
            .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(Color.black.opacity(0.5), lineWidth: 1)
                            )
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.top, 8)
            
                        .fullScreenCover(isPresented: $shouldShowEditForm) {
                            AddCardForm(card: self.card)
                        }
        }
    }
    
    private var deleteAllButton: some View {
        Button {
            cards.forEach { card in
                viewContext.delete(card)
            }
            
            do {
                try viewContext.save()
            } catch {
                // error
            }
    
        } label: {
            Text("Delete All")
        }
    }
    
    var addCardButton: some View {
        
        Button {
            shouldPresentAddCardForm.toggle()
        } label: {
            Text("+ Card")
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .bold))
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .background(Color.black)
                .clipShape(.rect(cornerRadius: 5))
        }
    }
}

#Preview {
    let viewContext = PersistenceController.shared.container.viewContext
    MainView()
        .environment(\.managedObjectContext, viewContext)
}
