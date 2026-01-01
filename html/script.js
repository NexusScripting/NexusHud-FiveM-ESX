const MAX_SPEED = 250;     
const PULSE_LIMIT = 20;    

window.addEventListener('message', function(event) {
    const d = event.data;
    const setProg = (id, pct) => {
        const el = document.getElementById(id);
        if(el) {
            el.style.strokeDashoffset = 264 - (Math.min(pct, 100) / 100 * 264);
            const parent = el.parentElement.parentElement;
            if (pct < PULSE_LIMIT && pct > 0) parent.classList.add('pulse-warning');
            else parent.classList.remove('pulse-warning');
        }
    };
    if (d.action === "updateMic") {
        const mic = document.getElementById('mic');
        if (d.talking) {
            mic.classList.add('active');
            mic.classList.replace('fa-microphone-slash', 'fa-microphone');
        } else {
            mic.classList.remove('active');
            mic.classList.replace('fa-microphone', 'fa-microphone-slash');
        }
    }
    if (d.action === "updateFast") {
        setProg('health-circle', d.health);
        setProg('armor-circle', d.armor);
        const speedo = document.getElementById('speed-container');
        if (d.inVehicle) {
            speedo.style.display = 'flex';
            document.getElementById('speed-num').innerText = d.speed;
            const offset = 280 - (Math.min(d.speed, MAX_SPEED) / MAX_SPEED * 205);
            document.getElementById('speed-prog').style.strokeDashoffset = offset;
        } else { speedo.style.display = 'none'; }
    }
    if (d.action === "updateStatus") {
        document.getElementById('cash-text').innerText = d.cash.toLocaleString('de-DE');
        document.getElementById('bank-text').innerText = d.bank.toLocaleString('de-DE');
        document.getElementById('id-text').innerText = "ID: " + d.id;
        setProg('hunger-circle', d.hunger);
        setProg('thirst-circle', d.thirst);
    }
    if (d.action === "fade") { document.getElementById('hud-wrapper').className = d.state ? 'hidden' : ''; }
});