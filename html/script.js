let isEditMode = false;
let forceHidden = false;

function loadPositions() {
    const savedData = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
    Object.keys(savedData).forEach(id => {
        const itemElement = document.getElementById(id);
        if (itemElement) {
            itemElement.style.top = savedData[id].t;
            itemElement.style.left = savedData[id].l;
            itemElement.style.right = 'auto';
            itemElement.style.bottom = 'auto';
            itemElement.style.transform = 'none';
        }
    });
}

function updateCircle(id, val) {
    const c = document.getElementById(id);
    if (c) {
        let dashOffset = 264 - (val / 100 * 264);
        c.style.strokeDashoffset = dashOffset;
    }
}

window.addEventListener('message', (event) => {
    const payload = event.data;
    
    if (payload.action === "resetHud") {
        localStorage.removeItem('nexus_pos_v2');
        document.querySelectorAll('.drag-item').forEach(e => {
            e.style.top = ''; e.style.left = ''; e.style.right = ''; e.style.bottom = ''; e.style.transform = '';
        });
        return;
    }

    if (payload.action === "init") {
        if (payload.colors) {
            const root = document.documentElement;
            root.style.setProperty('--primary', payload.colors.primary);
            root.style.setProperty('--health', payload.colors.health);
            root.style.setProperty('--armor', payload.colors.armor);
            root.style.setProperty('--hunger', payload.colors.hunger);
            root.style.setProperty('--thirst', payload.colors.thirst);
        }
        if (payload.branding) {
            document.querySelector('.nexus').innerText = payload.branding.name1;
            document.querySelector('.roleplay').innerText = payload.branding.name2;
        }
        if (payload.settings) {
            document.getElementById('id-text').style.display = payload.settings.showID ? 'block' : 'none';
            document.getElementById('drag-status').style.display = payload.settings.showStatus ? 'flex' : 'none';
            document.getElementById('drag-mic').style.display = payload.settings.showMic ? 'block' : 'none';
        }
        loadPositions();
    }

    if (payload.action === "forceHide") { forceHidden = payload.state; }
    
    if (payload.action === "toggleEdit") {
        isEditMode = payload.state;
        document.body.classList.toggle('edit-mode', isEditMode);
    }

    if (payload.action === "tick") {
        document.body.style.display = (payload.paused || forceHidden) ? 'none' : 'block';
        
        if (!isEditMode && payload.mapPos) {
            const statusBox = document.getElementById('drag-status');
            const saved = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
            if (!saved['drag-status']) {
                // Ein klitzekleines bisschen weiter links (-3.2)
                statusBox.style.left = (payload.mapPos.x + (payload.mapPos.w / 2) - 3.2) + "%";
                statusBox.style.top = (payload.mapPos.y - 4.1) + "%";
                statusBox.style.transform = 'translateX(-50%)';
                statusBox.style.bottom = 'auto';
                statusBox.style.right = 'auto';
            }
        }

        updateCircle('health-circle', payload.hp);
        updateCircle('armor-circle', payload.arm);
        
        const speedo = document.getElementById('speedo-container');
        if (payload.inVeh) {
            speedo.style.display = 'flex';
            document.getElementById('speed-val').innerText = payload.spd;
            document.getElementById('gear-val').innerText = payload.gear;
            document.getElementById('rpm-bar-fill').style.width = (payload.rpm * 100) + "%";
        } else { speedo.style.display = 'none'; }

        const mic = document.getElementById('mic');
        if (payload.talking) {
            mic.classList.add('active');
            mic.classList.replace('fa-microphone-slash', 'fa-microphone');
        } else {
            mic.classList.remove('active');
            mic.classList.replace('fa-microphone', 'fa-microphone-slash');
        }
    }

    if (payload.action === "updateStats") {
        updateCircle('hunger-circle', payload.h);
        updateCircle('thirst-circle', payload.t);
    }

    if (payload.action === "status") {
        if (payload.cash !== undefined) document.getElementById('cash-text').innerText = payload.cash.toLocaleString();
        if (payload.bank !== undefined) document.getElementById('bank-text').innerText = payload.bank.toLocaleString();
        if (payload.sid !== undefined) document.getElementById('id-text').innerText = "ID: " + payload.sid;
    }
});

let active_item = null;
document.addEventListener('mousedown', (e) => {
    if (!isEditMode) return;
    active_item = e.target.closest('.drag-item');
    if (active_item) active_item.style.transform = 'none';
});

document.addEventListener('mousemove', (e) => {
    if (!isEditMode || !active_item) return;
    active_item.style.left = e.clientX - (active_item.offsetWidth/2) + "px";
    active_item.style.top = e.clientY - (active_item.offsetHeight/2) + "px";
});

document.addEventListener('mouseup', () => {
    if (active_item) {
        const current_save = JSON.parse(localStorage.getItem('nexus_pos_v2') || '{}');
        current_save[active_item.id] = { t: active_item.style.top, l: active_item.style.left };
        localStorage.setItem('nexus_pos_v2', JSON.stringify(current_save));
        active_item = null;
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === "Escape" && isEditMode) {
        fetch(`https://${GetParentResourceName()}/closeEdit`, { method: 'POST', body: JSON.stringify({}) });
    }
});

document.addEventListener('DOMContentLoaded', () => {
    fetch(`https://${GetParentResourceName()}/nuiReady`, { method: 'POST', body: JSON.stringify({}) });
    loadPositions();
});