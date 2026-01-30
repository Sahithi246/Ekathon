//
//  ContentView.swift
//  HackathonApp
//
//  Created by Sahithi Mucchala on 29/01/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            QuestionnaireScreen(
                questions: PatientData.questions,
                transcript: "",
                backendSections: PatientData.backendSections
            )
            .navigationTitle("Patient Questionnaire")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
