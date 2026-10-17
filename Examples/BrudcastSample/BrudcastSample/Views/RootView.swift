import SwiftUI
import Brudcast
import BrudcastInApp

/// Sign-in when signed out, the tabbed app when signed in.
struct RootView: View {
    @ObservedObject private var session = SampleSession.shared

    var body: some View {
        Group {
            if let user = session.current {
                MainTabView(user: user)
            } else {
                SignInView()
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.foreground)
    }
}

/// The signed-in app: Home, Shop and Account tabs.
struct MainTabView: View {
    let user: SampleSession.User
    @ObservedObject private var router = SampleRouter.shared

    var body: some View {
        TabView(selection: $router.tab) {
            NavigationStack {
                HomeView(user: user)
                    .sampleToolbar()
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(SampleRouter.Tab.home)

            NavigationStack(path: $router.shopPath) {
                ShopView()
                    .sampleToolbar()
                    .navigationDestination(for: SampleRouter.ShopRoute.self) { route in
                        switch route {
                        case .product(let product): ProductView(product: product).sampleToolbar(showsBrand: false)
                        case .checkout(let product): CheckoutView(product: product).sampleToolbar(showsBrand: false)
                        }
                    }
            }
            .tabItem { Label("Shop", systemImage: "cart") }
            .tag(SampleRouter.Tab.shop)

            NavigationStack {
                AccountView(user: user)
                    .sampleToolbar()
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
            .tag(SampleRouter.Tab.account)
        }
        .tint(Palette.foreground)
    }
}

/// The inbox bell, badged with the unread count, as an app puts it in its navigation bar.
struct InboxButton: View {
    @State private var unread = Brudcast.inApp.inbox.unreadCount

    var body: some View {
        Button { Brudcast.inApp.inbox.present() } label: {
            Image(systemName: "bell")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Palette.foreground)
                .overlay(alignment: .topTrailing) {
                    if unread > 0 {
                        Text("\(unread)")
                            .font(Typography.micro)
                            .foregroundStyle(Palette.primaryForeground)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Palette.primary, in: Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
        }
        .accessibilityIdentifier("inboxButton")
        .accessibilityLabel("Inbox, \(unread) unread")
        .onReceive(Brudcast.inApp.inbox.unreadCountPublisher) { unread = $0 }
    }
}

private extension View {
    func sampleToolbar(showsBrand: Bool = true) -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsBrand {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Brudcast Sample").font(Typography.label).foregroundStyle(Palette.brand)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { InboxButton() }
            }
            .background(Palette.background)
    }
}
