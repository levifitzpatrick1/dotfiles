import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: parent.width
    height: 20 // Total hit/bounding box height

    // Properties to hook up to your MPRIS/System backend
    property real value: 0.35      // Current progress (0.0 to 1.0)
    property bool isPlaying: true  // Animates wave only when playing

    // Wave Customization Styling
    property color trackColor: "#14ffffff"    // Color of the remaining line    property real waveFrequency: 0.08       // How tightly packed the waves are
    property real waveSpeed: 0.15           // Speed of the wave crawling

    // Signal emitted when user scrubs or clicks the bar
    signal seeked(real val)

    // Internal animation driver
    property real phase: 0.0
    NumberAnimation on phase {
        from: 0; to: Math.PI * 2
        duration: 1000
        loops: Animation.Infinite
        running: root.isPlaying || root.waveAmplitude > 0
    }

    // Trigger canvas repaint when phase or value changes
    onPhaseChanged: canvas.requestPaint()
    onValueChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.lineWidth = 4; // Thickness of the slider line
            ctx.lineCap = "round";

            var midY = height / 2;
            var progressX = width * root.value;

            // --- 1. DRAW THE TRACK (Unplayed portion, flat line) ---
            ctx.strokeStyle = root.trackColor;
            ctx.beginPath();
            ctx.moveTo(progressX, midY);
            ctx.lineTo(width, midY);
            ctx.stroke();

            // --- 2. DRAW THE WAVE (Played portion, active sine wave) ---
            ctx.strokeStyle = root.activeColor;
            ctx.beginPath();
            
            // Start at the left edge using the animated amplitude
            var startY = midY + Math.sin(-root.phase) * root.waveAmplitude;
            ctx.moveTo(0, startY);

            // Calculate the sine wave up until the progress handle point
            for (var x = 1; x <= progressX; x++) {
                // Smoothly flatten/grow based on root.waveAmplitude's animated property
                var y = midY + Math.sin(x * root.waveFrequency - root.phase) * root.waveAmplitude;
                ctx.lineTo(x, y);
            }
            ctx.stroke();

            // --- 3. DRAW THE KNOB / HANDLE (Material 3 Pill Style) ---
            ctx.fillStyle = root.activeColor;
            ctx.beginPath();
            // Draw a rounded vertical pill at the edge of the wave
            ctx.ellipse(progressX - 4, midY - 10, 8, 20); 
            ctx.fill();
        }
    }

    // Allow scrubbing/clicking to change the position
    MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => {
            var val = Math.max(0.0, Math.min(1.0, mouse.x / width));
            root.seeked(val);
        }
        onPositionChanged: (mouse) => {
            if (pressed) {
                var val = Math.max(0.0, Math.min(1.0, mouse.x / width));
                root.seeked(val);
            }
        }
    }
}
