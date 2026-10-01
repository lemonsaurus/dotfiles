import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

const APP_ID = 'it.mijorus.smile';

export default class SmileSummonExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._windowCreatedId = global.display.connect('window-created', (_, window) => {
            const actor = window.get_compositor_private();
            if (!actor) return;
            actor.connect('realize', () => {
                if (!this._isSmile(window)) return;
                this._moveToPointer(window);
                window.activate(global.get_current_time());
            });
        });

        Main.wm.addKeybinding(
            'summon-smile',
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
            () => this._toggle()
        );
    }

    disable() {
        Main.wm.removeKeybinding('summon-smile');
        if (this._windowCreatedId) {
            global.display.disconnect(this._windowCreatedId);
            this._windowCreatedId = null;
        }
        this._settings = null;
    }

    _isSmile(window) {
        return window.get_gtk_application_id() === APP_ID && window.get_title() === 'Smile';
    }

    _findWindow() {
        return global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => this._isSmile(w)) ?? null;
    }

    _toggle() {
        const window = this._findWindow();
        if (!window) {
            Gio.Subprocess.new(['flatpak', 'run', APP_ID], Gio.SubprocessFlags.NONE);
            return;
        }

        if (window.has_focus()) {
            this._sendEscape();
            return;
        }

        this._moveToPointer(window);
        window.unminimize();
        window.activate(global.get_current_time());
    }

    _sendEscape() {
        const seat = Clutter.get_default_backend().get_default_seat();
        const kbd = seat.create_virtual_device(Clutter.InputDeviceType.KEYBOARD_DEVICE);
        kbd.notify_keyval(Clutter.get_current_event_time(), Clutter.KEY_Escape, Clutter.KeyState.PRESSED);
        kbd.notify_keyval(Clutter.get_current_event_time(), Clutter.KEY_Escape, Clutter.KeyState.RELEASED);
    }

    _moveToPointer(window) {
        const [px, py] = global.get_pointer();
        const monitor = global.display.get_current_monitor();
        const area = Main.layoutManager.getWorkAreaForMonitor(monitor);
        const rect = window.get_frame_rect();

        const clamp = (v, min, max) => Math.min(Math.max(v, min), Math.max(min, max));
        const x = clamp(px, area.x, area.x + area.width - rect.width);
        const y = clamp(py, area.y, area.y + area.height - rect.height);
        window.move_frame(true, x, y);
    }
}
