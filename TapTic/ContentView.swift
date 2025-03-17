import SwiftUI
import AVFoundation
import UIKit

// Structure pour les particules de confettis
struct Confetti: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    var opacity: Double
    let dx: CGFloat // Vitesse horizontale
    let dy: CGFloat // Vitesse verticale
    let size: CGFloat // Taille de la particule
}

struct ContentView: View {
    @State private var touchPoints: [TouchData] = [] // Liste des points de contact
    @State private var winner: TouchData? = nil // Point gagnant
    @State private var lastTouchTime: Date? = nil // Dernier moment où un doigt est ajouté
    @State private var timer: Timer? = nil // Timer pour choisir le gagnant
    @State private var resetTimer: Timer? = nil // Timer pour réinitialiser
    @State private var pulseEffect: Bool = false // Pulsation des cercles
    @State private var progress: CGFloat = 0.0 // Progrès du compte à rebours
    @State private var showWelcome: Bool = true // Écran d’accueil
    @State private var confettis: [Confetti] = [] // Liste des confettis
    @State private var confettiTimer: Timer? = nil // Timer pour les confettis
    @State private var hasPlayedPopSound: Set<Int> = [] // Suivi des sons joués
    @State private var isSoundEnabled: Bool = false // Son désactivé par défaut

    // Couleurs futuristes
    private let pointColors: [Color] = [
        Color(red: 0.0, green: 1.0, blue: 1.0), // Cyan
        Color(red: 0.75, green: 0.0, blue: 1.0), // Violet
        Color(red: 0.0, green: 0.77, blue: 1.0), // Bleu
        Color(red: 1.0, green: 0.0, blue: 1.0), // Rose
        Color(red: 0.22, green: 1.0, blue: 0.08) // Vert
    ]
    private let winnerColor: Color = Color(red: 0.75, green: 0.75, blue: 0.75) // Argent
    private let confettiColors: [Color] = [
        Color(red: 0.5, green: 1.0, blue: 1.0), // Cyan pâle
        Color(red: 0.75, green: 0.5, blue: 1.0), // Violet doux
        Color(red: 0.5, green: 0.9, blue: 1.0)  // Bleu clair
    ]
    private let neonBorderColor: Color = Color(red: 0.0, green: 1.0, blue: 1.0, opacity: 0.7) // Bordure cyan
    private let shadowColor: Color = Color(red: 0.5, green: 0.9, blue: 1.0, opacity: 0.5) // Ombre

    // Sons
    @State private var popSound: AVAudioPlayer?
    @State private var winSound: AVAudioPlayer?

    var body: some View {
        ZStack {
            if showWelcome && touchPoints.isEmpty {
                WelcomeView()
            } else {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(red: 0.29, green: 0.0, blue: 0.50), Color(red: 0.10, green: 0.0, blue: 0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()

                    // Cercles pour les doigts
                    ForEach(touchPoints) { point in
                        Circle()
                            .frame(width: 60, height: 60)
                            .position(x: point.point.x, y: point.point.y)
                            .foregroundColor(winner == point ? winnerColor : point.color.opacity(0.8))
                            .overlay(Circle().stroke(neonBorderColor, lineWidth: 2).blur(radius: 2))
                            .shadow(color: shadowColor, radius: 5)
                            .scaleEffect(winner == nil ? (pulseEffect ? 1.1 : 1.0) : 1.2)
                            .opacity(winner == nil ? 1.0 : (winner == point ? 1.0 : 0.0))
                            .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: pulseEffect)
                            .animation(.easeInOut(duration: 0.3), value: winner)
                    }

                    // Confettis
                    ForEach(confettis) { confetti in
                        Circle()
                            .frame(width: confetti.size, height: confetti.size)
                            .position(x: confetti.x, y: confetti.y)
                            .foregroundColor(confetti.color)
                            .opacity(confetti.opacity)
                            .animation(.easeOut(duration: 0.3), value: confetti.opacity)
                    }

                    // Compte à rebours
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.black.opacity(0.3), lineWidth: 10)
                                .frame(width: 120, height: 120)
                                .opacity(touchPoints.isEmpty ? 0.0 : 1.0)
                            Circle()
                                .trim(from: 0.0, to: progress)
                                .stroke(neonBorderColor, lineWidth: 10)
                                .frame(width: 120, height: 120)
                                .rotationEffect(Angle(degrees: -90))
                                .opacity(touchPoints.isEmpty ? 0.0 : 1.0)
                        }
                    }
                }
            }

            MultiTouchViewRepresentable(colors: pointColors, touchPoints: $touchPoints)
                .ignoresSafeArea()
                .onChange(of: touchPoints) { newTouchPoints in
                    // Plus besoin de vérification de zone ici, car l'icône est gérée séparément
                    for point in newTouchPoints {
                        if !hasPlayedPopSound.contains(point.id) && isSoundEnabled {
                            playPopSound()
                            triggerLightHaptic()
                            hasPlayedPopSound.insert(point.id)
                        }
                    }
                    if newTouchPoints.isEmpty {
                        resetGame()
                    } else if touchPoints.isEmpty {
                        showWelcome = false
                        lastTouchTime = Date()
                        startTimer()
                    } else {
                        lastTouchTime = Date()
                        startTimer()
                    }
                }

            // Icône de haut-parleur en superposition, visible uniquement sur l’écran d’accueil
            if showWelcome && touchPoints.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            isSoundEnabled.toggle()
                        }) {
                            Image(systemName: isSoundEnabled ? "speaker.wave.3" : "speaker.slash")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .background(isSoundEnabled ? Color.green.opacity(0.7) : Color.red.opacity(0.7))
                                .cornerRadius(20)
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                    }
                    Spacer()
                }
            }
        }
        .onAppear { loadSounds() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateProgressAndPulse()
        }
    }

    // Charger les sons
    private func loadSounds() {
        if let popPath = Bundle.main.path(forResource: "pop", ofType: "mp3") {
            popSound = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: popPath))
            popSound?.prepareToPlay()
        }
        if let winPath = Bundle.main.path(forResource: "win", ofType: "wav") {
            winSound = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: winPath))
            winSound?.prepareToPlay()
        }
    }

    // Jouer les sons (conditionnés par l'état)
    private func playPopSound() {
        if isSoundEnabled {
            popSound?.play()
        }
    }

    private func playWinSound() {
        if isSoundEnabled {
            winSound?.play()
        }
    }

    // Démarrer le timer
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            checkForWinner()
        }
        progress = 0.0
    }

    // Mettre à jour le compte à rebours et la pulsation
    private func updateProgressAndPulse() {
        if let last = lastTouchTime, !touchPoints.isEmpty {
            let timeElapsed = Date().timeIntervalSince(last)
            progress = min(timeElapsed / 3.0, 1.0)
            pulseEffect = timeElapsed >= 1.5
        }
    }

    // Choisir un gagnant
    private func checkForWinner() {
        if let last = lastTouchTime, Date().timeIntervalSince(last) >= 3.0, !touchPoints.isEmpty, winner == nil {
            winner = touchPoints.randomElement()
            touchPoints = winner.map { [$0] } ?? []
            playWinSound()
            triggerSuccessHaptic()
            startResetTimer()
            startConfettiTimer()
        }
    }

    // Timer pour les confettis
    private func startConfettiTimer() {
        confettiTimer?.invalidate()
        confettis.removeAll()
        confettiTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            generateConfettis()
        }
    }

    // Générer des confettis
    private func generateConfettis() {
        guard let winner = winner, let last = lastTouchTime, Date().timeIntervalSince(last) <= 6.0 else {
            confettis.removeAll()
            confettiTimer?.invalidate()
            return
        }
        if confettis.count < 100 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 5...15)
            let newConfetti = Confetti(
                x: winner.point.x, y: winner.point.y,
                color: confettiColors.randomElement() ?? .white,
                opacity: 1.0, dx: speed * cos(angle), dy: speed * sin(angle),
                size: CGFloat.random(in: 5...15)
            )
            confettis.append(newConfetti)
        }
        for index in confettis.indices.reversed() {
            confettis[index].x += confettis[index].dx
            confettis[index].y += confettis[index].dy
            confettis[index].opacity -= 0.1
            if confettis[index].opacity <= 0 {
                confettis.remove(at: index)
            }
        }
    }

    // Réinitialiser après 3 secondes
    private func startResetTimer() {
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            resetGame()
        }
    }

    // Réinitialiser le jeu
    private func resetGame() {
        touchPoints.removeAll()
        winner = nil
        lastTouchTime = nil
        timer?.invalidate()
        resetTimer?.invalidate()
        confettiTimer?.invalidate()
        pulseEffect = false
        progress = 0.0
        confettis.removeAll()
        showWelcome = true
        hasPlayedPopSound.removeAll()
    }

    // Vibrations
    private func triggerLightHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
