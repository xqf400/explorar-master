//
//  MapListView.swift
//  explorar
//
//  Created by Fabian Kuschke on 04.08.25.
//
import SwiftUI
import TelemetryDeck

struct MapListView: View {
    @StateObject private var sharedPlaces = SharedPlaces.shared
    @State private var selectedTab: Int = 0
    @State private var lastRadius: Double = 160.0

    var body: some View {
        VStack {
            Text("\(sharedPlaces.currentStreet) \(sharedPlaces.currentHouse), \(sharedPlaces.currentCity)")
            .padding()
            VStack(spacing: 8) {
                Text("Radius: \(Int(sharedPlaces.searchRadius))m")
                    .minimumScaleFactor(0.5)
                    .font(.headline)

                Slider(value: $sharedPlaces.searchRadius, in: 50...1000, step: 10)
                    .onChange(of: sharedPlaces.searchRadius, { oldValue, newValue in
                        if abs(newValue - lastRadius) >= 10 {
                            lastRadius = newValue
                            sharedPlaces.searchInterestLocations()
                        }
                    })
                    .padding(.horizontal)
            }
            .padding()
            Picker("View", selection: $selectedTab) {
                Text("List").tag(0)
                Text("Map").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            if selectedTab == 0 {
                ListView()
            } else {
                MapARView()
            }
        }
        .onAppear {
            sharedPlaces.requestLocation()
            TelemetryDeck.signal("MapListView")
        }
        .onDisappear {
            sharedPlaces.locationManager.stopUpdatingLocation()
        }
    }
}
