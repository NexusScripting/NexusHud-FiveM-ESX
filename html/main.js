const MAX_SPEED = 250;
const LOW_WARNING = 20;

// helper because writing this 20x is annoying
function setCircleProgress(id, percent) {
    const el = document.getElementById(id);
    if (!el) return;

    const value = Math.min(percent, 100);
    el.style.strokeDashoffset = 264 - (value / 100 * 264);

    const wrapper = el.closest('.icon-unit');
    if (!wrapper) return;

    if (value > 0 && value <= LOW_WARNING) {
        wrapper.classList.add('pulse-warning');
    } else {
        wrapper.classList.remove('pulse-warning');
    }
}

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'updateMic') {
        const mic = document.getElementById('mic');
        if (!mic) return;

        if (data.talking) {
            mic.classList.add('active');
            mic.classList.replace('fa-microphone-slash', 'fa-microphone');
        } else {
            mic.classList.remove('active');
            mic.classList.replace('fa-microphone', 'fa-microphone-slash');
        }
    }

    if (data.action === 'updateFast') {
        setCircleProgress('health-circle', data.health);
        setCircleProgress('armor-circle', data.armor);

        const speedBox = document.getElementById('speed-container');

        if (data.inVehicle) {
            speedBox.style.display = 'flex';
            document.getElementById('speed-num').innerText = data.speed;

            const offset = 280 - (Math.min(data.speed, MAX_SPEED) / MAX_SPEED * 205);
            document.getElementById('speed-prog').style.strokeDashoffset = offset;
        } else {
            speedBox.style.display = 'none';
        }
    }

    if (data.action === 'updateStatus') {
        document.getElementById('cash-text').innerText =
            data.cash.toLocaleString('de-DE');

        document.getElementById('bank-text').innerText =
            data.bank.toLocaleString('de-DE');

        document.getElementById('id-text').innerText = `ID: ${data.id}`;

        setCircleProgress('hunger-circle', data.hunger);
        setCircleProgress('thirst-circle', data.thirst);
    }

    if (data.action === 'fade') {
        const hud = document.getElementById('hud-wrapper');
        hud.className = data.state ? 'hidden' : '';
    }
});
