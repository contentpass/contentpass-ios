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
            Text("Has valid subscription: \(viewModel.hasValidSubscription)" as String)
            
            HStack {
                loginButton
                
                logoutButton
            }
            
            errorButton
            
            impressionButton
            
            Text("Counting impression tries: \(viewModel.impressionTries)\nCounting impression successes: \(viewModel.impressionSuccesses)")
        }
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
}
