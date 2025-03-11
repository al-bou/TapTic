import SwiftUI

struct WelcomeView: View {
    @State private var showHands: Bool = true
    @Binding var isSoundEnabled: Bool // Binding pour contrôler les sons

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.29, green: 0.0, blue: 0.50), Color(red: 0.10, green: 0.0, blue: 0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                if showHands {
                    ZStack {
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color(red: 0.0, green: 1.0, blue: 1.0)) // Cyan
                            .overlay(Circle().stroke(Color(red: 0.0, green: 1.0, blue: 1.0, opacity: 0.7), lineWidth: 2).blur(radius: 2))
                            .shadow(color: Color(red: 0.5, green: 0.9, blue: 1.0, opacity: 0.5), radius: 5)
                            .scaleEffect(showHands ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: showHands)
                        
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color(red: 0.75, green: 0.0, blue: 1.0)) // Violet
                            .overlay(Circle().stroke(Color(red: 0.0, green: 1.0, blue: 1.0, opacity: 0.7), lineWidth: 2).blur(radius: 2))
                            .shadow(color: Color(red: 0.5, green: 0.9, blue: 1.0, opacity: 0.5), radius: 5)
                            .offset(x: -40, y: 0)
                            .scaleEffect(showHands ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: showHands)
                        
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color(red: 0.0, green: 0.77, blue: 1.0)) // Bleu
                            .overlay(Circle().stroke(Color(red: 0.0, green: 1.0, blue: 1.0, opacity: 0.7), lineWidth: 2).blur(radius: 2))
                            .shadow(color: Color(red: 0.5, green: 0.9, blue: 1.0, opacity: 0.5), radius: 5)
                            .offset(x: 40, y: 0)
                            .scaleEffect(showHands ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showHands)
                    }
                    .onAppear {
                        showHands = true
                    }
                }
                
                Text("Appuyez et maintenez vos doigts\npour commencer !")
                    .font(.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color(red: 0.5, green: 0.9, blue: 1.0, opacity: 0.5), radius: 3, x: 0, y: 2)
                
                // Bouton pour activer/désactiver les sons
                Button(action: {
                    isSoundEnabled.toggle()
                }) {
                    Text(isSoundEnabled ? "Désactiver le son" : "Activer le son")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(isSoundEnabled ? Color.red : Color.green)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}
