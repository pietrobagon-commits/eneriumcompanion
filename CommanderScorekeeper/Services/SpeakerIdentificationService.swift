//
//  SpeakerIdentificationService.swift
//  CommanderScorekeeper
//
//  Speaker identification service using voice signature matching.
//  Handles voice calibration and speaker recognition.
//

import Foundation
import AVFoundation
import Accelerate

/// Voice profile containing acoustic features
struct VoiceProfile: Codable {
    let playerID: UUID
    let playerName: String
    var samples: [VoiceSample]
    let createdDate: Date

    var isComplete: Bool {
        samples.count >= Constants.Voice.calibrationRepetitions
    }
}

/// Individual voice sample with acoustic features
struct VoiceSample: Codable {
    let timestamp: Date
    let pitchMean: Float
    let pitchStdDev: Float
    let energyMean: Float
    let spectralCentroid: Float
    let mfccCoefficients: [Float] // Mel-frequency cepstral coefficients
}

/// Speaker identification result
struct SpeakerIdentificationResult {
    let playerID: UUID
    let playerName: String
    let confidence: Float // 0.0 - 1.0
    let isConfident: Bool // confidence >= threshold

    init(playerID: UUID, playerName: String, confidence: Float) {
        self.playerID = playerID
        self.playerName = playerName
        self.confidence = confidence
        self.isConfident = confidence >= Constants.Voice.minSpeakerConfidence
    }
}

/// Speaker identification service
@MainActor
final class SpeakerIdentificationService: ObservableObject {

    // MARK: - Published Properties

    /// Voice profiles for all players
    @Published var voiceProfiles: [UUID: VoiceProfile] = [:]

    /// Current calibration progress (0-3)
    @Published var calibrationProgress: [UUID: Int] = [:]

    // MARK: - Private Properties

    private let audioEngine = AVAudioEngine()
    private var audioBuffer: AVAudioPCMBuffer?

    // MARK: - Initialization

    init() {
        #if DEBUG
        print("🎙️ SpeakerIdentificationService initialized")
        #endif
    }

    // MARK: - Voice Calibration

    /// Start voice calibration for a player
    func startCalibration(for playerID: UUID, playerName: String) -> VoiceProfile {
        let profile = VoiceProfile(
            playerID: playerID,
            playerName: playerName,
            samples: [],
            createdDate: Date()
        )

        voiceProfiles[playerID] = profile
        calibrationProgress[playerID] = 0

        #if DEBUG
        print("🎤 Started calibration for \(playerName)")
        #endif

        return profile
    }

    /// Record a voice sample during calibration
    func recordCalibrationSample(for playerID: UUID, audioData: Data) async throws -> VoiceSample {
        guard var profile = voiceProfiles[playerID] else {
            throw NSError(domain: "SpeakerID", code: 1, userInfo: [NSLocalizedDescriptionKey: "No profile found"])
        }

        // Extract acoustic features from audio data
        let sample = try await extractVoiceFeatures(from: audioData)

        // Add sample to profile
        profile.samples.append(sample)
        voiceProfiles[playerID] = profile

        // Update progress
        calibrationProgress[playerID] = profile.samples.count

        #if DEBUG
        print("✅ Recorded sample \(profile.samples.count)/\(Constants.Voice.calibrationRepetitions) for \(profile.playerName)")
        #endif

        return sample
    }

    /// Complete calibration and save profile
    func completeCalibration(for playerID: UUID) -> Bool {
        guard let profile = voiceProfiles[playerID], profile.isComplete else {
            return false
        }

        #if DEBUG
        print("🎉 Calibration complete for \(profile.playerName)")
        #endif

        return true
    }

    /// Reset calibration for a player
    func resetCalibration(for playerID: UUID) {
        voiceProfiles[playerID] = nil
        calibrationProgress[playerID] = 0

        #if DEBUG
        print("🔄 Reset calibration for player \(playerID)")
        #endif
    }

    // MARK: - Speaker Identification

    /// Identify speaker from audio data
    func identifySpeaker(from audioData: Data, among playerIDs: [UUID]) async throws -> SpeakerIdentificationResult? {
        // Extract features from audio
        let testSample = try await extractVoiceFeatures(from: audioData)

        var bestMatch: (playerID: UUID, playerName: String, confidence: Float)?
        var highestConfidence: Float = 0.0

        // Compare with each player's voice profile
        for playerID in playerIDs {
            guard let profile = voiceProfiles[playerID], profile.isComplete else {
                continue
            }

            // Calculate similarity score
            let confidence = calculateSimilarity(between: testSample, and: profile)

            if confidence > highestConfidence {
                highestConfidence = confidence
                bestMatch = (playerID: playerID, playerName: profile.playerName, confidence: confidence)
            }
        }

        guard let match = bestMatch else {
            return nil
        }

        let result = SpeakerIdentificationResult(
            playerID: match.playerID,
            playerName: match.playerName,
            confidence: match.confidence
        )

        #if DEBUG
        print("🎯 Identified speaker: \(match.playerName) (confidence: \(String(format: "%.2f", match.confidence)))")
        #endif

        return result
    }

    // MARK: - Feature Extraction

    /// Extract acoustic features from audio data
    private func extractVoiceFeatures(from audioData: Data) async throws -> VoiceSample {
        // This is a simplified implementation
        // In a real app, you would use more sophisticated audio processing

        // Convert audio data to samples
        let samples = audioData.withUnsafeBytes { buffer -> [Float] in
            let count = buffer.count / MemoryLayout<Int16>.size
            let int16Buffer = buffer.bindMemory(to: Int16.self)

            return (0..<count).map { index in
                Float(int16Buffer[index]) / Float(Int16.max)
            }
        }

        guard !samples.isEmpty else {
            throw NSError(domain: "SpeakerID", code: 2, userInfo: [NSLocalizedDescriptionKey: "No audio samples"])
        }

        // Calculate pitch features
        let pitchMean = samples.reduce(0.0, +) / Float(samples.count)
        let pitchVariance = samples.map { pow($0 - pitchMean, 2) }.reduce(0.0, +) / Float(samples.count)
        let pitchStdDev = sqrt(pitchVariance)

        // Calculate energy (RMS)
        let energy = samples.map { $0 * $0 }.reduce(0.0, +) / Float(samples.count)
        let energyMean = sqrt(energy)

        // Calculate spectral centroid (simplified)
        let spectralCentroid = calculateSpectralCentroid(samples: samples)

        // Calculate MFCC coefficients (simplified - using first 13 coefficients)
        let mfccCoefficients = calculateMFCC(samples: samples, numCoefficients: 13)

        return VoiceSample(
            timestamp: Date(),
            pitchMean: pitchMean,
            pitchStdDev: pitchStdDev,
            energyMean: energyMean,
            spectralCentroid: spectralCentroid,
            mfccCoefficients: mfccCoefficients
        )
    }

    /// Calculate spectral centroid (simplified)
    private func calculateSpectralCentroid(samples: [Float]) -> Float {
        let fft = performFFT(samples: samples)
        let magnitudes = fft.map { sqrt($0.real * $0.real + $0.imag * $0.imag) }

        let numerator = magnitudes.enumerated().reduce(0.0) { sum, element in
            sum + Float(element.offset) * element.element
        }

        let denominator = magnitudes.reduce(0.0, +)

        return denominator > 0 ? numerator / denominator : 0.0
    }

    /// Perform FFT (Fast Fourier Transform) - simplified
    private func performFFT(samples: [Float]) -> [(real: Float, imag: Float)] {
        // This is a placeholder implementation
        // In a real app, use vDSP or Accelerate framework for proper FFT

        let count = min(samples.count, 256) // Limit for performance

        return (0..<count).map { index in
            let real = samples[index]
            let imag: Float = 0.0
            return (real: real, imag: imag)
        }
    }

    /// Calculate MFCC coefficients (simplified)
    private func calculateMFCC(samples: [Float], numCoefficients: Int) -> [Float] {
        // This is a placeholder implementation
        // In a real app, use a proper MFCC library

        let fft = performFFT(samples: samples)
        let magnitudes = fft.map { sqrt($0.real * $0.real + $0.imag * $0.imag) }

        // Simple downsampling to get approximate coefficients
        let step = max(1, magnitudes.count / numCoefficients)
        var coefficients: [Float] = []

        for i in 0..<numCoefficients {
            let index = min(i * step, magnitudes.count - 1)
            coefficients.append(magnitudes[index])
        }

        return coefficients
    }

    // MARK: - Similarity Calculation

    /// Calculate similarity between test sample and voice profile
    private func calculateSimilarity(between testSample: VoiceSample, and profile: VoiceProfile) -> Float {
        // Calculate average similarity across all calibration samples
        let similarities = profile.samples.map { trainingSample in
            calculateSampleSimilarity(testSample, trainingSample)
        }

        let avgSimilarity = similarities.reduce(0.0, +) / Float(max(1, similarities.count))

        return avgSimilarity
    }

    /// Calculate similarity between two voice samples
    private func calculateSampleSimilarity(_ sample1: VoiceSample, _ sample2: VoiceSample) -> Float {
        // Normalize and weight different features

        // Pitch similarity (weight: 0.2)
        let pitchDiff = abs(sample1.pitchMean - sample2.pitchMean)
        let pitchSimilarity = exp(-pitchDiff * 2.0) // Exponential decay

        // Energy similarity (weight: 0.1)
        let energyDiff = abs(sample1.energyMean - sample2.energyMean)
        let energySimilarity = exp(-energyDiff * 3.0)

        // Spectral similarity (weight: 0.2)
        let spectralDiff = abs(sample1.spectralCentroid - sample2.spectralCentroid)
        let spectralSimilarity = exp(-spectralDiff * 0.01)

        // MFCC similarity (weight: 0.5) - most important
        let mfccSimilarity = calculateMFCCSimilarity(sample1.mfccCoefficients, sample2.mfccCoefficients)

        // Weighted average
        let totalSimilarity = (
            pitchSimilarity * 0.2 +
            energySimilarity * 0.1 +
            spectralSimilarity * 0.2 +
            mfccSimilarity * 0.5
        )

        return totalSimilarity
    }

    /// Calculate similarity between MFCC coefficients
    private func calculateMFCCSimilarity(_ mfcc1: [Float], _ mfcc2: [Float]) -> Float {
        // Euclidean distance
        let count = min(mfcc1.count, mfcc2.count)

        let squaredDiffs = (0..<count).map { i in
            pow(mfcc1[i] - mfcc2[i], 2)
        }

        let distance = sqrt(squaredDiffs.reduce(0.0, +))

        // Convert distance to similarity (0-1)
        let similarity = exp(-distance * 0.1)

        return similarity
    }

    // MARK: - Persistence

    /// Save voice profiles to player entities
    func saveProfiles(to players: [Player]) {
        for player in players {
            if let profile = voiceProfiles[player.id], profile.isComplete {
                // Encode profile to Data
                if let data = try? JSONEncoder().encode(profile) {
                    player.voiceProfile = data

                    #if DEBUG
                    print("💾 Saved voice profile for \(player.name)")
                    #endif
                }
            }
        }
    }

    /// Load voice profiles from player entities
    func loadProfiles(from players: [Player]) {
        voiceProfiles.removeAll()

        for player in players {
            if let data = player.voiceProfile,
               let profile = try? JSONDecoder().decode(VoiceProfile.self, from: data) {
                voiceProfiles[player.id] = profile

                #if DEBUG
                print("📂 Loaded voice profile for \(player.name)")
                #endif
            }
        }
    }
}
