import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PomodoroViewModel()
    
    var progress: Double {
        let total = Double(viewModel.totalDuration)
        let elapsed = Double(viewModel.totalDuration - viewModel.timeRemaining)
        return elapsed / total
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: viewModel.timerMode.gradientColor),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Picker("Select Mode", selection: $viewModel.timerMode) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                ZStack {
                    TimerCircleView(progress: progress)
                        .frame(width: 250, height: 250)
                    
                    Text(viewModel.formattedTimeRemaining)
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 40) {
                    Button(action: {
                        viewModel.isActive ? viewModel.pauseTimer() : viewModel.startTimer()
                    }) {
                        Image(systemName: viewModel.isActive ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        viewModel.resetTimer()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            
            if viewModel.showPopUp {
                PopupView(message: "Time's up!") {
                    withAnimation {
                        viewModel.showPopUp = false
                    }
                    viewModel.resetTimer()
                }
            }
        }
    }
}

struct PopupView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text(message)
                .font(.title)
                .padding()
            
            Button("OK") {
                onDismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .frame(width: 200, height: 150)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .transition(.scale)
    }
}

struct TimerCircleView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(.white)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(.white)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
        }
        .padding(20)
    }
}

enum TimerMode: String, CaseIterable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
}

extension TimerMode {
    var duration: Int {
        switch self {
        case .work: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
    
    var gradientColor: [Color] {
        switch self {
        case .work: return [.red, .orange]
        case .shortBreak: return [.green, .blue]
        case .longBreak: return [.purple, .pink]
        }
    }
}

class PomodoroViewModel: ObservableObject {
    @Published var timerMode: TimerMode = .work {
        didSet {
            pauseTimer()
            timeRemaining = timerMode.duration
        }
    }
    
    var totalDuration: Int { timerMode.duration }
    
    @Published var timeRemaining: Int = TimerMode.work.duration
    @Published var isActive: Bool = false
    @Published var showPopUp: Bool = false
    
    private var timer: Timer?
    
    func startTimer() {
        guard !isActive else { return }
        isActive = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                withAnimation(.smooth(duration: 0.5)) {
                    self.timeRemaining -= 1
                }
            } else {
                self.timer?.invalidate()
                self.isActive = false
                self.showPopUp = true
            }
        }
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        
        withAnimation {
            self.timeRemaining = timerMode.duration
        }
    }
    
    var formattedTimeRemaining: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
