//
//  ContentView.swift
//  ContentPassExample
//
//  Created by Paul Weber on 10.06.22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack {
            Text("Is authenticated: \(viewModel.isAuthenticated)" as String)
            if let email = viewModel.email {
                Text("With email: \(email)")
            }
            Text("Has valid subscription: \(viewModel.hasValidSubscription)" as String)

            HStack {
                loginButton

                logoutButton
            }

            errorButton

            impressionButton

            Text("Counting impression tries: \(viewModel.impressionTries)\nCounting impression successes: \(viewModel.impressionSuccesses)")

            dashboardButton
        }
        .sheet(
            isPresented: Binding<Bool>(
                get: { viewModel.dashboard != nil },
                set: {
                    if !$0 {
                        viewModel.dashboard = nil
                    }
                }
            ),
            content: {
                if let dashboard = viewModel.dashboard {
                    DashboardView(dashboard: dashboard)
                }
            }
        )
    }

    var loginButton: some View {
            Button("Log in") {
                viewModel.login()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isAuthenticated)
    }

    var logoutButton: some View {
        Button("Log out") {
            viewModel.logout()
        }
        .buttonStyle(.bordered)
        .disabled(!viewModel.isAuthenticated)
    }

    var errorButton: some View {

        Button("Recover from error") {
            viewModel.recoverFromError()
        }
        .buttonStyle(.borderedProminent)
        .opacity(viewModel.isError ? 1 : 0)

    }

    var impressionButton: some View {
        Button("Count impression") {
            viewModel.countImpression()
        }
        .buttonStyle(.borderedProminent)
        .opacity(viewModel.isError || !viewModel.isAuthenticated ? 0 : 1)
    }

    var dashboardButton: some View {
        Button("Open Dashboard") {
            viewModel.openDashboard()
        }
        .buttonStyle(.borderedProminent)
        .opacity(viewModel.isAuthenticated ? 1 : 0)
    }
}
