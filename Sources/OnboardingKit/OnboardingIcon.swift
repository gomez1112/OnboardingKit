//
//  OnboardingIcon.swift
//  OnboardingKit
//
//  Created by Gerard Gomez on 11/27/25.
//


/// Internal wrapper to handle both image types
public enum OnboardingIcon: Equatable {
    case system(String)
    case asset(String)
}