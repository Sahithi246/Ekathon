//
//  PatientData.swift
//  HackathonApp
//
//  Patient data for form filling. Backend data only; no static test data.
//

import Foundation

enum PatientData {

    /// Questionnaire questions (form fields) derived from patient context.
    static let questions: [Question] = [
        Question(
            id: "pregnant",
            text: "Is the patient currently pregnant?",
            answerType: .yesNo,
            required: true
        ),
        Question(
            id: "lmp",
            text: "When was the last menstrual period?",
            answerType: .number,
            required: true
        ),
        Question(
            id: "tt_injection",
            text: "Has the patient received TT (Tetanus Toxoid) injections?",
            answerType: .yesNo,
            required: true
        ),
        Question(
            id: "household_members",
            text: "Number of members in the patient's household",
            answerType: .number,
            required: false
        ),
    ]

    /// Patient medical history and other notes — single source for form-fill output.
    /// Fetch this from your backend; this is the data you provided.
    static let backendSections: [BackendMedicalSection] = [
        BackendMedicalSection(
            title: "Patient Medical History",
            items: [
                "Personal History: Last menstrual period was approximately four months ago",
            ]
        ),
        BackendMedicalSection(
            title: "Other medical notes",
            items: [
                "Patient's name is Sahiti",
                "Patient is currently pregnant",
                "Patient has not registered at a health center for pregnancy care",
                "Patient has not received TT (Tetanus Toxoid) injections",
                "Patient has an Aadhaar card",
                "Patient does not have any government benefits (JSY, JSSK)",
                "There are four members in the patient's household",
            ]
        ),
    ]
}
